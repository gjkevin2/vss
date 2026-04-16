#!/bin/bash

# 错误处理：任何命令失败时退出
set -e

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    echo "错误：请使用root权限运行此脚本"
    exit 1
fi

# 检查必要的依赖
check_dependencies() {
    local missing_deps=()
    for cmd in curl wget apt systemctl nginx; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "错误：缺少必要的依赖：${missing_deps[*]}"
        echo "请先安装缺少的依赖"
        exit 1
    fi
}

check_dependencies

# 获取最新版本
GITHUB_API_URL='https://api.github.com/repos/juanfont/headscale/releases/latest'
LATEST_VERSION=$(curl -s "$GITHUB_API_URL" | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')

if [ -z "$LATEST_VERSION" ]; then
    echo "错误：无法获取headscale最新版本"
    exit 1
fi

echo "准备安装headscale版本: $LATEST_VERSION"

# 下载headscale包
HEADSCALE_DEB="headscale_${LATEST_VERSION}_linux_amd64.deb"
if ! wget --output-document="$HEADSCALE_DEB" "https://github.com/juanfont/headscale/releases/download/v${LATEST_VERSION}/${HEADSCALE_DEB}"; then
    echo "错误：下载headscale失败"
    exit 1
fi

# 安装headscale
if ! apt install -y "./$HEADSCALE_DEB"; then
    echo "错误：安装headscale失败"
    exit 1
fi

# 清理下载的deb包
rm -f "$HEADSCALE_DEB"

# 获取本机顶级域名
SERVERNAME=$(nginx -T 2>/dev/null | awk '$1=="server_name" && $2!~/localhost|_/ {sub(/;.*/,"",$2); print $2; exit}')

echo "使用域名: hs.${SERVERNAME}"

# 创建必要的目录
mkdir -p /etc/headscale
mkdir -p /var/lib/headscale

# 下载配置文件
if ! wget -O /etc/headscale/config.yaml "https://raw.githubusercontent.com/juanfont/headscale/refs/tags/v${LATEST_VERSION}/config-example.yaml"; then
    echo "错误：下载配置文件失败"
    exit 1
fi

# 修改配置文件
sed -i "s#server_url: http://127.0.0.1:8080#server_url: https://hs.${SERVERNAME}#g" /etc/headscale/config.yaml
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/headscale/config.yaml

# 验证配置文件修改
CONFIG_SERVER_URL=$(grep "^server_url:" /etc/headscale/config.yaml | awk '{print $2}')
echo "Headscale配置中的server_url: $CONFIG_SERVER_URL"

if [[ "$CONFIG_SERVER_URL" != *"hs.${SERVERNAME}"* ]]; then
    echo "警告：server_url配置可能不正确，请手动检查 /etc/headscale/config.yaml"
fi

# DERP配置
sed -i '/urls:/{N; s/.*/  urls: []/}' /etc/headscale/config.yaml
sed -i 's/paths: \[\][[:space:]]*$/paths:\n    - \/etc\/headscale\/derp.yaml/' /etc/headscale/config.yaml

# 创建DERP配置文件，注意修改成国内derp的地址和对应端口；stunport设置为-1，表示不走udp
cat > /etc/headscale/derp.yaml << 'EOF'
regions:
  901:
    regionid: 901
    regioncode: cn
    regionname: China
    nodes:
      - name: cn-1
        regionid: 901
        hostname: 160.202.254.29
        stunport: -1
        derpport: 18562
        stunonly: false
        insecurefortests: true
EOF

# 启动Headscale服务并设置开机自启
# 先停止可能存在的旧服务
systemctl stop headscale 2>/dev/null || true

# 启动服务
systemctl enable --now headscale

# 验证服务是否启动成功
if ! systemctl is-active --quiet headscale; then
    echo "错误：Headscale服务启动失败"
    systemctl status headscale
    exit 1
fi

echo "Headscale服务启动成功"

# 创建nginx配置
cat > /etc/nginx/conf.d/headscale.conf << EOF
server {
    listen 80;
    listen [::]:80;
    server_name hs.${SERVERNAME};
    return 301 https://\$host\$request_uri;
}

server {
    listen unix:/dev/shm/web.sock ssl proxy_protocol;
    http2 on;
    server_name hs.${SERVERNAME};
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# 验证nginx配置
if ! nginx -t; then
    echo "错误：nginx配置验证失败"
    exit 1
fi

# 重载nginx配置
nginx -s reload
echo "nginx配置已重载"

# 批量创建用户
CREATED_COUNT=0
SKIPPED_COUNT=0

for i in {1..5}; do
    USERNAME="gxtest${i}"
    if headscale users list 2>/dev/null | grep -q "$USERNAME"; then
        echo "用户 $USERNAME 已存在，跳过创建"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    else
        if headscale users create "$USERNAME" > /dev/null 2>&1; then
            echo "用户 $USERNAME 创建成功"
            CREATED_COUNT=$((CREATED_COUNT + 1))
        else
            echo "用户 $USERNAME 创建失败"
        fi
    fi
done

echo "用户创建完成: 新创建 ${CREATED_COUNT} 个，跳过 ${SKIPPED_COUNT} 个"

# 获取tailscale最新版本
TAILSCALE_API_URL='https://api.github.com/repos/tailscale/tailscale/releases/latest'
TAILSCALE_VERSION=$(curl -s "$TAILSCALE_API_URL" | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')

if [ -z "$TAILSCALE_VERSION" ]; then
    echo "警告：无法获取tailscale最新版本，使用默认版本"
    TAILSCALE_VERSION="1.86.2"
fi

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo "客户端下载地址:"
echo "https://dl.tailscale.com/stable/tailscale-setup-${TAILSCALE_VERSION}-amd64.msi"
echo ""
echo "客户端连接命令:"
echo "tailscale login --login-server http://hs.${SERVERNAME} --accept-dns=false"
echo ""
echo "查看用户列表:"
echo "headscale users list"
echo ""
echo "查看节点列表:"
echo "headscale nodes list"
echo ""
echo "创建预授权密钥示例:"
echo "headscale preauthkeys create --reusable --expiration 876000h --user <用户ID>"
echo ""
