#!/usr/bin/env bash
#=================================================
#   WARP + Google 流量分流
#   用途：本机发往 Google 网段的 TCP 流量走 Cloudflare WARP 出口，
#         解决 VPS IP 被 Google「送中」/ 风控导致无法访问的问题。
#         其它流量完全不动，不上全局 VPN。
#   系统：Debian 10+ / Ubuntu 18+ / CentOS 7+
#   用法：bash warp-google.sh          → 菜单
#         bash warp-google.sh install  → 也可直接指定动作
#=================================================
set -o pipefail

PROBE_URL="https://www.google.com"
WARP_SOCKS="socks5h://127.0.0.1:40000"
WARP_PORT=40000
REDSOCKS_CONF="/etc/redsocks.conf"
REDSOCKS_PORT=12345
FW_SCRIPT="/usr/local/bin/warp-google"          # 负责增删 iptables 规则
SVC_NAME="warp-google"

GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; RED=$'\033[0;31m'; CYAN=$'\033[0;36m'; PLAIN=$'\033[0m'
ok()   { echo -e "${GREEN}[ OK ]${PLAIN}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${PLAIN}  $*"; }
err()  { echo -e "${RED}[FAIL]${PLAIN}  $*"; }

[[ $EUID -ne 0 ]] && { err "请使用 root 运行"; exit 1; }

[[ -r /etc/os-release ]] && . /etc/os-release
OS=${ID:-unknown}
CODENAME=${VERSION_CODENAME:-}

command -v curl >/dev/null 2>&1 || {
    err "缺少 curl，请先安装：apt-get install -y curl 或 yum install -y curl"
    exit 1
}

# ────────────── warp-cli 兼容封装（新旧版本参数不同）──────────────
wcli() {
    warp-cli --accept-tos "$@" >/dev/null 2>&1 || warp-cli "$@" >/dev/null 2>&1
}
warp_reg_new() { wcli registration new || wcli register; }
warp_reg_del() { wcli registration delete || wcli delete; }
warp_mode_proxy() { wcli mode proxy || wcli proxy mode; }

wait_connected() {
    local i
    for i in {1..15}; do
        warp-cli status 2>/dev/null | grep -q "Connected" && return 0
        sleep 1
    done
    return 1
}

# ────────────── Google 探测 ──────────────
# 参数：可选代理地址；为空则走系统默认路径（即透明代理生效后的真实链路）
# 返回：0=正常  1=送中(跳转 google.com.hk)  2=风控(/sorry)  3=连不上
# 输出：G_CODE / G_URL
probe() {
    local proxy_args=() res
    [[ -n "${1:-}" ]] && proxy_args=(-x "$1")
    res=$(curl -s "${proxy_args[@]}" --max-time 10 -o /dev/null \
        -w "%{http_code}|%{redirect_url}" "$PROBE_URL" 2>/dev/null)
    G_CODE=${res%%|*}
    G_URL=${res#*|}
    [[ -z "$G_CODE" || "$G_CODE" == "000" ]] && return 3
    case "$G_URL" in
        *hkredirect*|*google.com.hk*|*google.cn*) return 1 ;;
        */sorry/*) return 2 ;;
    esac
    return 0
}

do_test() {
    local rc
    echo "测试 Google 访问..."
    probe; rc=$?
    case $rc in
        0) ok "Google 正常（HTTP $G_CODE）" ;;
        1) warn "送中：跳转 google.com.hk，请执行菜单 4「换 IP」" ;;
        2) warn "风控：要求人机验证（/sorry），请执行菜单 4「换 IP」" ;;
        3) err "无法连接 Google，请检查 warp status / 分流规则" ;;
    esac
    return $rc
}

# ────────────── 安装 Cloudflare WARP ──────────────
install_warp() {
    if command -v warp-cli >/dev/null 2>&1; then
        ok "warp-cli 已安装，跳过"
        return 0
    fi
    echo "安装 Cloudflare WARP 官方客户端..."
    case $OS in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y -qq gnupg curl lsb-release || return 1
            curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
                | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg || return 1
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ ${CODENAME} main" \
                > /etc/apt/sources.list.d/cloudflare-client.list
            apt-get update -qq && apt-get install -y cloudflare-warp || return 1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            cat > /etc/yum.repos.d/cloudflare-warp.repo <<'EOF'
[cloudflare-warp]
name=Cloudflare WARP
baseurl=https://pkg.cloudflareclient.com/rpm
enabled=1
gpgcheck=1
gpgkey=https://pkg.cloudflareclient.com/pubkey.gpg
EOF
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y cloudflare-warp || return 1
            else
                yum install -y cloudflare-warp || return 1
            fi
            ;;
        *)
            err "不支持的系统: $OS"
            return 1
            ;;
    esac
    command -v warp-cli >/dev/null 2>&1 && ok "warp-cli 安装完成" || { err "WARP 安装失败"; return 1; }
}

configure_warp() {
    echo "配置 WARP（仅 SOCKS5 代理模式，不接管全局流量）..."
    warp_reg_new                       # 已有注册时失败属正常，忽略
    warp_mode_proxy
    wcli proxy port "$WARP_PORT"
    wcli connect
    if wait_connected; then
        ok "WARP 已连接（SOCKS5 127.0.0.1:${WARP_PORT}）"
    else
        warn "WARP 连接超时，稍后可在菜单里重试「换 IP」"
    fi
}

# ────────────── redsocks 透明代理 ──────────────
install_redsocks() {
    command -v redsocks >/dev/null 2>&1 && return 0
    echo "安装 redsocks + iptables..."
    case $OS in
        ubuntu|debian)
            apt-get install -y -qq redsocks iptables
            ;;
        *)
            # CentOS/RHEL 系列 redsocks 在 EPEL 里
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y epel-release >/dev/null 2>&1
                dnf install -y redsocks iptables
            else
                yum install -y epel-release >/dev/null 2>&1
                yum install -y redsocks iptables
            fi
            ;;
    esac
    # redsocks 由本脚本的 systemd 服务托管，关掉发行版自带的实例避免抢端口
    systemctl disable --now redsocks >/dev/null 2>&1
    return 0
}

write_redsocks_conf() {
    cat > "$REDSOCKS_CONF" <<EOF
base {
    log_debug = off;
    log_info  = on;
    log       = "syslog:daemon";
    daemon    = on;
    redirector = iptables;
}
redsocks {
    local_ip   = 127.0.0.1;
    local_port = ${REDSOCKS_PORT};
    ip         = 127.0.0.1;
    port       = ${WARP_PORT};
    type       = socks5;
}
EOF
}

# ────────────── 规则脚本（iptables 增删）──────────────
write_fw_script() {
    cat > "$FW_SCRIPT" <<'SCRIPT'
#!/usr/bin/env bash
# Google ASN IPv4 段（来源：Google Prefixes JSON）
GOOGLE_IPS="
8.8.4.0/24
8.8.8.0/24
34.0.0.0/9
35.184.0.0/13
35.192.0.0/12
35.224.0.0/12
35.240.0.0/13
64.233.160.0/19
66.102.0.0/20
66.249.64.0/19
72.14.192.0/18
74.125.0.0/16
104.132.0.0/14
108.177.0.0/17
142.250.0.0/15
172.217.0.0/16
172.253.0.0/16
173.194.0.0/16
209.85.128.0/17
216.58.192.0/19
216.239.32.0/19
"
REDSOCKS_CONF="/etc/redsocks.conf"
REDSOCKS_PORT=12345

start() {
    pkill -f "$REDSOCKS_CONF" 2>/dev/null
    redsocks -c "$REDSOCKS_CONF"
    # 让 Google 的 IPv6 立即失败，客户端快速回落 IPv4（避免等超时）
    ip -6 route replace unreachable 2607:f8b0::/32 2>/dev/null
    iptables -t nat -N WARP_GOOGLE 2>/dev/null || iptables -t nat -F WARP_GOOGLE
    for ip in $GOOGLE_IPS; do
        iptables -t nat -A WARP_GOOGLE -d "$ip" -p tcp -j REDIRECT --to-ports "$REDSOCKS_PORT"
    done
    iptables -t nat -C OUTPUT -j WARP_GOOGLE 2>/dev/null \
        || iptables -t nat -A OUTPUT -j WARP_GOOGLE
    echo "WARP Google 分流已启动"
}

stop() {
    pkill -f "$REDSOCKS_CONF" 2>/dev/null
    ip -6 route del unreachable 2607:f8b0::/32 2>/dev/null
    iptables -t nat -D OUTPUT -j WARP_GOOGLE 2>/dev/null
    iptables -t nat -F WARP_GOOGLE 2>/dev/null
    iptables -t nat -X WARP_GOOGLE 2>/dev/null
    echo "WARP Google 分流已停止"
}

case "$1" in
    start) start ;;
    stop)  stop ;;
    *) echo "用法: $0 {start|stop}" ;;
esac
SCRIPT
    chmod +x "$FW_SCRIPT"
}

write_systemd_unit() {
    cat > /etc/systemd/system/${SVC_NAME}.service <<EOF
[Unit]
Description=WARP Google Transparent Proxy
After=network.target warp-svc.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${FW_SCRIPT} start
ExecStop=${FW_SCRIPT} stop

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
}

# ────────────── 安装流程 ──────────────
do_install() {
    install_warp || return 1
    configure_warp
    install_redsocks    || { err "redsocks 安装失败"; return 1; }
    write_redsocks_conf
    write_fw_script
    write_systemd_unit
    systemctl enable --now "$SVC_NAME" >/dev/null 2>&1
    sleep 2
    do_test
    echo ""
    echo "完成。本次只接管 Google 网段的 TCP 流量，其它流量不经过 WARP。"
    warn "如仍提示送中/风控，请执行菜单 4「换 IP」"
}

do_uninstall() {
    echo "卸载 WARP 及分流规则..."
    systemctl disable --now "$SVC_NAME" >/dev/null 2>&1
    [[ -x "$FW_SCRIPT" ]] && "$FW_SCRIPT" stop
    rm -f /etc/systemd/system/${SVC_NAME}.service "$FW_SCRIPT" "$REDSOCKS_CONF" /etc/systemd/system/multi-user.target.wants/${SVC_NAME}.service
    systemctl daemon-reload
    wcli disconnect
    case $OS in
        ubuntu|debian)
            apt-get remove -y cloudflare-warp redsocks >/dev/null 2>&1
            rm -f /etc/apt/sources.list.d/cloudflare-client.list
            ;;
        *)
            if command -v dnf >/dev/null 2>&1; then
                dnf remove -y cloudflare-warp redsocks >/dev/null 2>&1
            else
                yum remove -y cloudflare-warp redsocks >/dev/null 2>&1
            fi
            rm -f /etc/yum.repos.d/cloudflare-warp.repo
            ;;
    esac
    ok "已卸载"
}

# ────────────── 换 IP（解决送中/风控）─────────────
do_refresh() {
    local max=${1:-10} i ip rc
    [[ "$max" =~ ^[0-9]+$ ]] || max=10
    command -v warp-cli >/dev/null 2>&1 || { err "未安装 WARP，请先执行安装"; return 1; }
    echo "开始更换 WARP 出口 IP（最多尝试 ${max} 次）..."
    for ((i = 1; i <= max; i++)); do
        wcli disconnect
        warp_reg_del
        warp_reg_new
        warp_mode_proxy
        wcli proxy port "$WARP_PORT"
        wcli connect
        if ! wait_connected; then
            warn "[$i/$max] 连接超时，重试..."
            continue
        fi
        sleep 2
        ip=$(curl -s -x "$WARP_SOCKS" --max-time 8 https://api.ip.sb/ip 2>/dev/null)
        probe "$WARP_SOCKS"; rc=$?
        case $rc in
            0) ok "[$i/$max] ${ip:-未知} → 可用，更换完成"; return 0 ;;
            1) warn "[$i/$max] ${ip:-未知} → 送中（google.com.hk），继续更换..." ;;
            2) warn "[$i/$max] ${ip:-未知} → 风控（/sorry），继续更换..." ;;
            *) warn "[$i/$max] ${ip:-未知} → 连不上 Google，继续更换..." ;;
        esac
    done
    err "已尝试 ${max} 次仍未获得可用 IP，请稍后再试"
    return 1
}

# ────────────── 状态 ──────────────
do_status() {
    local warp_st rules
    warp_st=$(warp-cli status 2>/dev/null | tail -1)
    rules=$(iptables -t nat -L WARP_GOOGLE -n 2>/dev/null | grep -c REDIRECT)
    printf "  %-14s %s\n" "WARP 客户端:" "$(command -v warp-cli >/dev/null 2>&1 && echo 已安装 || echo 未安装)"
    printf "  %-14s %s\n" "WARP 状态:"   "${warp_st:-未运行}"
    printf "  %-14s %s\n" "透明代理:"    "$(pgrep -f "$REDSOCKS_CONF" >/dev/null 2>&1 && echo 运行中 || echo 未运行)"
    printf "  %-14s %s 条\n" "Google 规则:" "${rules:-0}"
    printf "  %-14s %s\n" "开机自启:"    "$(systemctl is-enabled "$SVC_NAME" 2>/dev/null || echo 未启用)"
}

# ────────────── 菜单 ──────────────
show_menu() {
    while :; do
        echo ""
        echo -e "${CYAN}══════  WARP Google 分流管理  ══════${PLAIN}"
        do_status
        echo ""
        echo "  1) 安装并启用        2) 卸载"
        echo "  3) 测试 Google       4) 换 IP（解决送中/风控）"
        echo "  5) 重启分流规则      0) 退出"
        echo ""
        read -rp "  请选择 [0-5]: " choice
        echo ""
        case $choice in
            1) do_install ;;
            2) read -rp "  确认卸载 WARP 及全部分流规则? [y/N]: " y
               [[ "$y" =~ ^[Yy]$ ]] && do_uninstall || warn "已取消" ;;
            3) do_test ;;
            4) read -rp "  最大尝试次数 [默认 10]: " n
               do_refresh "${n:-10}" && do_test ;;
            5) systemctl restart "$SVC_NAME" && ok "分流规则已重启" ;;
            0) exit 0 ;;
            *) err "无效选项" ;;
        esac
        echo ""
        read -r -p "  按回车返回菜单..." _
    done
}

# ────────────── 入口 ──────────────
case "${1:-}" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    status)    do_status ;;
    test)      do_test ;;
    refresh)   do_refresh "${2:-10}" ;;
    restart)   systemctl restart "$SVC_NAME" && ok "分流规则已重启" ;;
    "")        show_menu ;;
    *)         echo "用法: bash $0 [install|uninstall|status|test|refresh [N]|restart]" ;;
esac
