#!/bin/bash

# deploy free-api
docker run -it -d --init --name metaso-free-api -p 8000:8000 -e TZ=Asia/Shanghai vinlic/metaso-free-api:latest
# docker logs -f metaso-free-api
# docker restart metaso-free-api
# docker stop metaso-free-api

domain=158742.xyz

cat >/etc/nginx/conf.d/metaso.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    return 301 https://\$host\$request_uri;
}

server {
    listen unix:/dev/shm/web.sock ssl proxy_protocol;
    http2 on;
    server_name metaso.$domain;
    
    location / {
        proxy_pass http://127.0.0.1:8000;  # 将请求代理到本地的 8000 端口
        proxy_set_header Host \$host;  # 传递原始 Host 头部
        proxy_set_header X-Real-IP \$remote_addr;  # 传递客户端的真实 IP
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;  # 传递转发的 IP
        proxy_set_header X-Forwarded-Proto \$scheme;  # 传递原始协议（HTTP/HTTPS）
    }
}
EOF


# (re)start nginx
systemctl stop nginx
systemctl start nginx