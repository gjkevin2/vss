#!/usr/bin/env bash
#=================================================
#   WARP + Google 流量分流
#   用途：本机发往 Google 网段的 TCP 流量走 Cloudflare WARP 出口，
#         解决 VPS IP 被 Google「送中」/ 风控导致无法访问的问题。
#         其它流量完全不动，不上全局 VPN。
#   系统：Debian 10+ / Ubuntu 18+ / CentOS 7+
#   用法：bash warp-google.sh          → 菜单
#         bash warp-google.sh install  → 也可直接指定动作
#         bash warp-google.sh optimize → 优选 WARP 接入点（降延迟）
#=================================================
set -o pipefail

PROBE_URL="https://www.google.com"
PROBE_204="https://www.google.com/generate_204"
WARP_SOCKS="socks5h://127.0.0.1:40000"
WARP_PORT=40000
REDSOCKS_CONF="/etc/redsocks.conf"
REDSOCKS_PORT=12345
FW_SCRIPT="/usr/local/bin/warp-google"          # 负责增删 iptables 规则
SVC_NAME="warp-google"
ENDPOINT_FILE="/etc/warp-google.endpoint"       # 优选后的 WARP 接入点记录
ACCEPT_MS=${ACCEPT_MS:-500}                     # 换 IP 时可接受的出口延迟（毫秒）

# WARP 接入点候选网段与端口（ICMP 粗筛 → 逐个重连实测）
EP_RANGES="162.159.192 162.159.193 162.159.195 162.159.204 188.114.96 188.114.97 188.114.98 188.114.99"
EP_PORT=2408        # 默认 WireGuard 接入端口
EP_PORTS=${EP_PORTS:-}   # 显式指定要实测的端口列表（如 "2408" 或 "2408 443"），默认按客户端当前接入点推断
EP_STEP=8          # 每个 /24 的采样步长（8 = 32 个 IP）
EP_SHORTLIST=5     # 进入实测阶段的最优候选数量

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
    warp-cli --accept-tos "$@" >/dev/null 2>&1 </dev/null || warp-cli "$@" >/dev/null 2>&1 </dev/null
}
warp_reg_new() { wcli registration new || wcli register; }
warp_reg_del() { wcli registration delete || wcli delete; }
warp_mode_proxy() { wcli mode proxy || wcli proxy mode; }
warp_ep_set() { wcli tunnel endpoint set "$1" || wcli --endpoint "$1"; }
warp_ep_reset() { wcli tunnel endpoint reset || wcli --endpoint default; }

# 换出口 IP：注销旧注册 → 新注册 → 重连（接入点设置保持不变）
rotate_warp() {
    wcli disconnect
    warp_reg_del
    warp_reg_new
    warp_mode_proxy
    wcli proxy port "$WARP_PORT"
    wcli connect
}

# SOCKS 可用性实测（部分 warp-cli 版本的 status 文案无法解析）
warp_proxy_alive() {
    curl -s -x "$WARP_SOCKS" --max-time 4 -o /dev/null "https://1.1.1.1/cdn-cgi/trace" 2>/dev/null
}

warp_status() {
    warp-cli --accept-tos status 2>/dev/null || warp-cli status 2>/dev/null
}

wait_connected() {
    local i
    for i in {1..10}; do
        warp_status | grep -q "Connected" && return 0
        sleep 1
    done
    warp_proxy_alive
}

# 读取客户端当前接入点（ip:port / host:port）；settings 没暴露时回退到磁盘配置
warp_current_endpoint() {
    local out re='(([0-9]{1,3}\.){3}[0-9]{1,3}|[a-z0-9]([a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}):[0-9]{2,5}'
    out=$(warp-cli --accept-tos settings 2>/dev/null || warp-cli settings 2>/dev/null)
    out=$(grep -oiE "$re" <<<"$out" | head -1)
    if [[ -z "$out" ]]; then
        out=$(grep -rhoiE "$re" /var/lib/cloudflare-warp/ 2>/dev/null \
            | grep -E ':(2408|443|500|1701|4500)$' | head -1)
    fi
    [[ -n "$out" ]] && echo "$out"
    return 0
}

# 打印 warp-svc 里与连接失败相关的最后几行
warp_last_error() {
    journalctl -u warp-svc -n 60 --no-pager 2>/dev/null \
        | grep -iE "error|fail|timeout|handshake|endpoint" | tail -5 | sed 's/^/      /'
}

# WARP 起不来时打印排查信息（优选接入点之前用）
warp_diag() {
    echo "  ── 诊断信息 ──"
    printf "  %-14s %s\n" "warp-svc:"   "$(systemctl is-active warp-svc 2>/dev/null || echo 未知)"
    printf "  %-14s %s\n" "TUN 设备:"   "$([[ -c /dev/net/tun ]] && echo 存在 || echo 缺失（OpenVZ/LXC 需先开 TUN）)"
    printf "  %-14s %s\n" "warp-cli 版本:" "$(warp-cli --version 2>/dev/null | head -1)"
    printf "  %-14s %s\n" "注册状态:"   "$(warp-cli --accept-tos registration show 2>/dev/null | head -3 | tr '\n' ' ')"
    printf "  %-14s %s\n" "客户端状态:" "$(warp_status | grep -E 'Status|Network' | tr '\n' ' ')"
    printf "  %-14s %s\n" "当前接入点:" "$(warp_current_endpoint || true)"
    printf "  %-14s %s\n" "隧道协议:" "$(warp-cli --accept-tos tunnel protocol show 2>/dev/null | tail -1)"
    printf "  %-14s %s\n" "协议/接入点:" "$(warp-cli --accept-tos settings 2>/dev/null | grep -iE 'endpoint|protocol' | tr '\n' ' ')"
    printf "  %-14s %s\n" "SOCKS 监听:" "$(ss -lnt 2>/dev/null | grep -q ":${WARP_PORT} " && echo 监听中 || echo 未监听)"
    printf "  %-14s %s\n" "SOCKS 实测:" "$(warp_proxy_alive && echo 可用 || echo 失败)"
    echo "  最近的 warp-svc 日志："
    journalctl -u warp-svc -n 8 --no-pager 2>/dev/null | sed 's/^/    /'
    echo "  若 UDP 2408 被拦截，可尝试改用 MASQUE（走 QUIC/UDP 443）："
    echo "    warp-cli --accept-tos tunnel protocol set MASQUE && warp-cli --accept-tos connect"
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

# 通过 WARP SOCKS 测到 Google 的端到端耗时（毫秒，取 3 次最快值），失败返回 1
measure_google() {
    local i t best=""
    for i in 1 2 3; do
        t=$(curl -s -x "$WARP_SOCKS" --max-time 8 -o /dev/null \
            -H 'Connection: close' -w '%{time_appconnect}' "$PROBE_204" 2>/dev/null) || continue
        t=$(awk -v t="$t" 'BEGIN{ if (t<=0) exit 1; printf "%d", t*1000 }') || continue
        [[ -z "$t" ]] && continue
        [[ -z "$best" || "$t" -lt "$best" ]] && best=$t
    done
    [[ -z "$best" ]] && return 1
    echo "$best"
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
# Google 网段：IPv4 TCP 走 redsocks，IPv6 直接置为不可达（客户端快速回落 IPv4）
PREFIX_CACHE="/usr/local/etc/warp-google-prefixes.txt"
PREFIX_URL="https://www.gstatic.com/ipranges/goog.json"
V6_ROUTE_FILE="/usr/local/etc/warp-google-ipv6-routes.txt"
REDSOCKS_CONF="/etc/redsocks.conf"
REDSOCKS_PORT=12345

# 拉不到 goog.json 时的兜底网段（Google 常用 IPv4 + IPv6 主段）
FALLBACK_PREFIXES="
8.8.4.0/24
8.8.8.0/24
34.0.0.0/9
34.128.0.0/10
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
2001:4860::/32
2404:6800::/32
2607:f8b0::/32
2a00:1450::/32
2c0f:fb50::/32
"

# 优先读缓存（超过 30 天自动刷新），其次拉取官方 JSON，最后用内置兜底
load_prefixes() {
    local body
    if [[ -s $PREFIX_CACHE ]]; then
        [[ -z $(find "$PREFIX_CACHE" -mtime +30 2>/dev/null) ]] && { cat "$PREFIX_CACHE"; return 0; }
    fi
    body=$(curl -fsSL --max-time 10 "$PREFIX_URL" 2>/dev/null) || body=""
    if [[ -n $body ]] && printf '%s\n' "$body" \
        | grep -oE '[0-9a-fA-F:.]+/[0-9]+' | sort -u > "$PREFIX_CACHE.tmp" \
        && [[ -s $PREFIX_CACHE.tmp ]]; then
        mkdir -p "${PREFIX_CACHE%/*}"
        mv "$PREFIX_CACHE.tmp" "$PREFIX_CACHE"
        cat "$PREFIX_CACHE"
        return 0
    fi
    rm -f "$PREFIX_CACHE.tmp"
    [[ -s $PREFIX_CACHE ]] && { cat "$PREFIX_CACHE"; return 0; }   # 拉取失败时沿用旧缓存
    printf '%s\n' "$FALLBACK_PREFIXES"
}

start() {
    local p prefixes n4=0 n6=0
    prefixes=$(load_prefixes)
    pkill -f "$REDSOCKS_CONF" 2>/dev/null
    redsocks -c "$REDSOCKS_CONF"
    iptables -t nat -N WARP_GOOGLE 2>/dev/null || iptables -t nat -F WARP_GOOGLE
    for p in $prefixes; do
        case $p in
            *:*) ;;
            *) iptables -t nat -A WARP_GOOGLE -d "$p" -p tcp -j REDIRECT --to-ports "$REDSOCKS_PORT"
               n4=$((n4 + 1)) ;;
        esac
    done
    iptables -t nat -C OUTPUT -j WARP_GOOGLE 2>/dev/null \
        || iptables -t nat -A OUTPUT -j WARP_GOOGLE
    # 让 Google 的 IPv6 立即失败，客户端快速回落 IPv4（避免等超时）
    mkdir -p "${V6_ROUTE_FILE%/*}"
    : > "$V6_ROUTE_FILE"
    for p in $prefixes; do
        case $p in
            *:*) ip -6 route replace unreachable "$p" 2>/dev/null \
                     && echo "$p" >> "$V6_ROUTE_FILE" && n6=$((n6 + 1)) ;;
        esac
    done
    echo "WARP Google 分流已启动（IPv4 ${n4} 条 / IPv6 ${n6} 条）"
}

stop() {
    local p
    pkill -f "$REDSOCKS_CONF" 2>/dev/null
    if [[ -s $V6_ROUTE_FILE ]]; then
        while read -r p; do
            [[ -n $p ]] && ip -6 route del unreachable "$p" 2>/dev/null
        done < "$V6_ROUTE_FILE"
    fi
    rm -f "$V6_ROUTE_FILE"
    ip -6 route del unreachable 2607:f8b0::/32 2>/dev/null   # 清理旧版本遗留的单条规则
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

# 重建规则脚本并重启（升级本脚本后用它刷新已安装的规则与网段）
do_restart() {
    [[ -x "$FW_SCRIPT" ]] || { err "尚未安装，请先执行菜单 1 安装"; return 1; }
    write_fw_script && write_systemd_unit || { err "规则脚本写入失败"; return 1; }
    if systemctl restart "$SVC_NAME"; then ok "分流规则已重建并重启"; else err "重启失败，查看 journalctl -u $SVC_NAME"; return 1; fi
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
    warn "如果访问 Google 慢，请执行菜单 6「优选接入点」"
}

do_uninstall() {
    echo "卸载 WARP 及分流规则..."
    systemctl disable --now "$SVC_NAME" >/dev/null 2>&1
    [[ -x "$FW_SCRIPT" ]] && "$FW_SCRIPT" stop
    rm -f /etc/systemd/system/${SVC_NAME}.service "$FW_SCRIPT" "$REDSOCKS_CONF" /etc/systemd/system/multi-user.target.wants/${SVC_NAME}.service
    rm -f "$ENDPOINT_FILE" /usr/local/etc/warp-google-prefixes.txt /usr/local/etc/warp-google-ipv6-routes.txt
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

# ────────────── 换 IP（解决送中/风控，择优取延迟低的）──────────────
# 参数：最大尝试次数。前 N 次只接受「可用且到 Google ≤ ACCEPT_MS」的出口，
#       若均为慢出口，则再试 N 次，只要能用就接受（保证不停在送中/风控 IP 上）。
do_refresh() {
    local max=${1:-10} hard_max i ip rc rtt relaxed=0
    [[ "$max" =~ ^[0-9]+$ ]] || max=10
    command -v warp-cli >/dev/null 2>&1 || { err "未安装 WARP，请先执行安装"; return 1; }
    hard_max=$((max * 2))
    echo "开始更换 WARP 出口 IP（最多 ${hard_max} 次，接受延迟 ≤ ${ACCEPT_MS}ms）..."
    for ((i = 1; i <= hard_max; i++)); do
        (( i > max )) && relaxed=1
        rotate_warp
        if ! wait_connected; then
            warn "[$i/$hard_max] 连接超时，重试..."
            continue
        fi
        sleep 2
        ip=$(curl -s -x "$WARP_SOCKS" --max-time 8 https://api.ip.sb/ip 2>/dev/null)
        probe "$WARP_SOCKS"; rc=$?
        if [[ $rc -ne 0 ]]; then
            case $rc in
                1) warn "[$i/$hard_max] ${ip:-未知} → 送中（google.com.hk），继续更换..." ;;
                2) warn "[$i/$hard_max] ${ip:-未知} → 风控（/sorry），继续更换..." ;;
                *) warn "[$i/$hard_max] ${ip:-未知} → 连不上 Google，继续更换..." ;;
            esac
            continue
        fi
        rtt=$(measure_google) || rtt=""
        if [[ $relaxed -eq 1 || -z "$rtt" || "$rtt" -le "$ACCEPT_MS" ]]; then
            ok "[$i/$hard_max] ${ip:-未知} → 可用，到 Google ${rtt:-?}ms，采用"
            return 0
        fi
        warn "[$i/$hard_max] ${ip:-未知} → 可用但到 Google ${rtt}ms > ${ACCEPT_MS}ms，继续找更快的..."
    done
    err "已尝试 ${hard_max} 次仍未获得可用 IP，请稍后再试"
    return 1
}

# ────────────── 优选接入点（降低 VPS → CF → Google 延迟）──────────────
# 阶段 1：对 CF WARP 候选网段做 ICMP 粗筛，取 RTT 最低的若干候选
# 阶段 2：逐个设置接入点重建隧道，实测到 Google 的耗时，保留最快者
scan_endpoints() {
    local ranges=${1:-$EP_RANGES} net i
    for net in $ranges; do
        for ((i = 1; i < 256; i += EP_STEP)); do
            printf '%s.%s\n' "$net" "$i"
        done
    done | xargs -P 32 -I{} bash -c '
        rtt=$(ping -c1 -W1 "$1" 2>/dev/null | sed -n "s/.*time=\([0-9.]*\).*/\1/p" | head -1)
        [[ -n "$rtt" ]] && echo "$rtt $1"
        exit 0
    ' _ {} | sort -n
}

do_optimize() {
    local k=${1:-$EP_SHORTLIST} list rtt host ep cur_ep="" ms prev="" best_ep="" best_ms=""
    local ep_port ports cur_ep_cfg="" fails=0 ranges=$EP_RANGES masque_ip=""
    [[ "$k" =~ ^[0-9]+$ ]] || k=$EP_SHORTLIST
    command -v warp-cli >/dev/null 2>&1 || { err "未安装 WARP，请先执行安装"; return 1; }
    [[ -s "$ENDPOINT_FILE" ]] && prev=$(cat "$ENDPOINT_FILE")
    cur_ep_cfg=$(warp_current_endpoint)
    [[ -n "$cur_ep_cfg" ]] && prev=$cur_ep_cfg
    # 端口优先级：显式 EP_PORTS > 客户端当前接入点 > WireGuard 2408 / MASQUE 443
    if [[ -n "$EP_PORTS" ]]; then
        ports=$EP_PORTS
    elif [[ -n "$cur_ep_cfg" ]]; then
        ports=${cur_ep_cfg##*:}
    else
        ports="$EP_PORT 443"
    fi

    # 先确认隧道能起来，否则逐候选重连毫无意义
    echo "第 0 步：确认 WARP 隧道可建立..."
    wcli connect
    if ! wait_connected; then
        warn "当前接入点连不上，尝试恢复默认接入点..."
        wcli disconnect
        warp_ep_reset
        wcli connect
        if ! wait_connected; then
            err "WARP 隧道无法建立，优选接入点已中止（优选只调接入点，修不了隧道本身）"
            warp_diag
            return 1
        fi
    fi

    for ep_port in $ports; do
        # MASQUE（443）只接受当前接入点所在 /24，其它 WARP 网段的 443 不提供 MASQUE 服务
        ranges=$EP_RANGES
        if [[ "$ep_port" == "443" ]]; then
            if [[ -z "$cur_ep_cfg" ]]; then
                warn "端口 443（MASQUE）但未探测到接入点 IP，跳过 443"
                continue
            fi
            masque_ip=$cur_ep_cfg
            [[ "$masque_ip" == *[a-zA-Z]* ]] && masque_ip=$(getent ahostsv4 "${cur_ep_cfg%:*}" 2>/dev/null | awk 'NR==1{print $1}')
            if [[ -z "$masque_ip" ]]; then
                warn "MASQUE 接入点 ${cur_ep_cfg} 解析不出 IP，跳过 443"
                continue
            fi
            ranges=${masque_ip%.*}
            echo "  当前为 MASQUE（接入点 ${cur_ep_cfg}），只在 ${ranges}.0/24 内优选"
        fi

        echo "第 1 步：ICMP 粗筛接入点（网段 ${ranges}，每个 /24 采样 $((255 / EP_STEP + 1)) 个 IP）..."
        list=$(scan_endpoints "$ranges" | sed -n "1,${k}p")
        if [[ -z "$list" ]]; then
            warn "全部无 ICMP 回应（可能被限速/阻断），改用各网段前 ${k} 个入口测试"
            list=$(for net in $ranges; do for ((i = 1; i <= k; i++)); do echo "0 ${net}.${i}"; done; done | sed -n "1,${k}p")
        fi

        echo "第 2 步：逐个重建隧道实测到 Google 的耗时（端口 ${ep_port}，每个约 5~10 秒）..."
        while read -r rtt host; do
            [[ -z "$host" ]] && continue
            ep="${host}:${ep_port}"
            printf '  → 测试 %s（ICMP %sms）' "$ep" "$rtt"
            wcli disconnect
            if ! warp_ep_set "$ep"; then
                echo ""
                err "设置接入点失败（当前 warp-cli 不支持 tunnel endpoint）"
                [[ -n "$prev" ]] && warp_ep_set "$prev"
                wcli connect
                return 1
            fi
            cur_ep=$ep
            wcli connect
            if ! wait_connected; then
                echo "连接超时，跳过"
                if [[ $fails -eq 0 ]]; then
                    echo "  首次失败原因（warp-svc 日志）："
                    warp_last_error
                fi
                fails=$((fails + 1))
                continue
            fi
            sleep 1
            if ! probe "$WARP_SOCKS"; then
                echo "访问 Google 异常，跳过"
                continue
            fi
            ms=$(measure_google) || ms=""
            if [[ -z "$ms" ]]; then
                echo "测速失败，跳过"
                continue
            fi
            echo "→ 到 Google ${ms}ms"
            if [[ -z "$best_ms" || "$ms" -lt "$best_ms" ]]; then
                best_ms=$ms; best_ep=$ep
            fi
        done <<< "$list"
        [[ -n "$best_ep" ]] && break
        [[ "$ports" == *" "* ]] && warn "端口 ${ep_port} 全部失败，换下一个端口重试..."
    done

    if [[ -n "$best_ep" ]]; then
        if [[ "$cur_ep" == "$best_ep" ]]; then
            echo "当前接入点已是最优：${best_ep}（${best_ms}ms）"
        else
            echo "应用最优接入点 ${best_ep}（${best_ms}ms）..."
            wcli disconnect
            warp_ep_set "$best_ep" || { err "应用接入点失败"; return 1; }
            wcli connect
            wait_connected || warn "重连超时，请手动检查 warp-cli status"
        fi
        echo "$best_ep" > "$ENDPOINT_FILE"
        ok "接入点优选完成：${best_ep}，到 Google ${best_ms}ms"
        echo "提示：如需重新优选，可重复执行本功能；如需回默认接入点，执行 bash $0 reset-endpoint"
    else
        warn "没有测到可用接入点，恢复原设置..."
        wcli disconnect
        if [[ -n "$prev" ]]; then warp_ep_set "$prev" || warp_ep_reset; else warp_ep_reset; fi
        wcli connect
        wait_connected || warn "重连超时，请手动检查 warp-cli status"
        rm -f "$ENDPOINT_FILE"
        [[ $fails -gt 0 ]] && warn "全部候选连接失败，请把 bash $0 diag 的输出发给维护者（MASQUE 环境需确认所在 /24 是否支持接入点优选）"
        return 1
    fi
}

# 切换隧道协议（WireGuard / MASQUE）：MASQUE 下做接入点优选前需先切到 WireGuard
do_set_protocol() {
    local proto=${1:-} lc
    [[ -n "$proto" ]] || { echo "用法: bash $0 protocol WireGuard|MASQUE"; return 1; }
    lc=$(tr '[:upper:]' '[:lower:]' <<<"$proto")
    wcli disconnect
    if ! wcli tunnel protocol set "$proto" && ! wcli tunnel protocol set "$lc"; then
        err "设置协议失败（当前 warp-cli 可能不支持 tunnel protocol set）"
        wcli connect
        return 1
    fi
    wcli connect
    if wait_connected; then
        ok "已切换为 ${proto}"
    else
        warn "切换后连接失败，请执行 diag 或将协议改回：bash $0 protocol MASQUE"
        return 1
    fi
}

do_reset_endpoint() {
    wcli disconnect
    warp_ep_reset || { err "重置接入点失败（旧版 warp-cli 可忽略）"; }
    wcli connect
    wait_connected || warn "重连超时，请手动检查 warp-cli status"
    rm -f "$ENDPOINT_FILE"
    ok "已恢复默认接入点"
}

# ────────────── 状态 ──────────────
do_status() {
    local warp_st rules
    warp_st=$(warp_status | grep -E 'Status|Network' | tr '\n' ' ')
    if [[ -z "$warp_st" ]]; then
        warp_proxy_alive && warp_st="SOCKS 可用（状态文案为空）" || warp_st="未运行"
    fi
    rules=$(iptables -t nat -L WARP_GOOGLE -n 2>/dev/null | grep -c REDIRECT)
    printf "  %-14s %s\n" "WARP 客户端:" "$(command -v warp-cli >/dev/null 2>&1 && echo 已安装 || echo 未安装)"
    printf "  %-14s %s\n" "WARP 状态:"   "${warp_st:-未运行}"
    printf "  %-14s %s\n" "透明代理:"    "$(pgrep -f "$REDSOCKS_CONF" >/dev/null 2>&1 && echo 运行中 || echo 未运行)"
    printf "  %-14s %s\n" "Google 规则:" "${rules:-0} 条"
    printf "  %-14s %s\n" "WARP 接入点:" "$([[ -s "$ENDPOINT_FILE" ]] && cat "$ENDPOINT_FILE" || echo 默认)"
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
        echo "  5) 重启分流规则      6) 优选接入点（降延迟）"
        echo "  7) 恢复默认接入点    0) 退出"
        echo ""
        read -rp "  请选择 [0-7]: " choice
        echo ""
        case $choice in
            1) do_install ;;
            2) read -rp "  确认卸载 WARP 及全部分流规则? [y/N]: " y
               [[ "$y" =~ ^[Yy]$ ]] && do_uninstall || warn "已取消" ;;
            3) do_test ;;
            4) read -rp "  最大尝试次数 [默认 10]: " n
               do_refresh "${n:-10}" && do_test ;;
            5) do_restart ;;
            6) read -rp "  实测候选数量 [默认 ${EP_SHORTLIST}]: " n
               do_optimize "${n:-$EP_SHORTLIST}" ;;
            7) do_reset_endpoint ;;
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
    optimize)  do_optimize "${2:-$EP_SHORTLIST}" ;;
    protocol)  do_set_protocol "${2:-}" ;;
    reset-endpoint) do_reset_endpoint ;;
    diag)      warp_diag ;;
    restart)   do_restart ;;
    "")        show_menu ;;
    *)         echo "用法: bash $0 [install|uninstall|status|test|refresh [N]|optimize [N]|protocol WireGuard|MASQUE|reset-endpoint|diag|restart]" ;;
esac
