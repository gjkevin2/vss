#!/usr/bin/env bash
set -e

DOMAIN="${DOMAIN:-ai.158742.xyz}"
ADMIN_PASS="${ADMIN_PASS:-change123456}"
SESSION_SECRET="${SESSION_SECRET:-$(openssl rand -hex 32)}"
PORT=3000
DIR=/opt/new-api

echo "==> 1. 装基础依赖"
apt update -y && apt install -y wget curl openssl

echo "==> 2. 下载 new-API 单二进制"
mkdir -p "$DIR"
cd "$DIR"
lurl='https://api.github.com/repos/QuantumNous/new-api/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/QuantumNous/new-api/releases/download/v${latest_version}/new-api-v${latest_version}
mv new-api-v${latest_version} new-api
chmod +x new-api

echo "==> 3. 写env"
cat > "$DIR/env" <<ENV
SESSION_SECRET=${SESSION_SECRET}
TZ=Asia/Shanghai
MEMORY_CACHE_ENABLED=true
STREAMING_TIMEOUT=600
RELAY_RESPONSE_HEADER_TIMEOUT=1800
ENV

echo "==> 4. systemd 保活（只绑 127.0.0.1）"
cat > /etc/systemd/system/new-api.service <<UNIT
[Unit]
Description=New API
After=network.target

[Service]
WorkingDirectory=${DIR}
EnvironmentFile=${DIR}/env
ExecStart=${DIR}/new-api --port ${PORT}
Restart=always
RestartSec=5
User=root
MemoryMax=700M
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now new-api

echo "==> 5. 等 NEW-API 起来"
for i in $(seq 1 20); do
  curl -sf http://127.0.0.1:$PORT >/dev/null && break
  sleep 1
done

echo "==> 6. Nginx server block（已有泛域名证书）"
cat > /etc/nginx/conf.d/one-api.conf <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server{
    listen unix:/dev/shm/web.sock ssl proxy_protocol;
    http2 on;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Accept-Encoding gzip;

        # SSE / 流式关键
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        proxy_connect_timeout 60s;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX

nginx -t
systemctl reload nginx

echo "============================================"
echo "New API:  https://${DOMAIN}"
echo "API:      https://${DOMAIN}/v1"
echo "用已有泛域名证书，未跑 certbot"
echo "============================================"