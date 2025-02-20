#!/bin/bash

AI=metaso
port=8000

# deploy free-api
docker run -it -d --init --name ${AI}-free-api -p ${port}:${port} -e TZ=Asia/Shanghai vinlic/${AI}-free-api:latest
# docker logs -f ${AI}-free-api
# docker restart ${AI}-free-api
# docker stop ${AI}-free-api

domain=158742.xyz

cat >/etc/nginx/conf.d/${AI}.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    server_name $AI.$domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen unix:/dev/shm/web.sock ssl proxy_protocol;
    http2 on;
    server_name $AI.$domain;
    
    location / {
        proxy_pass http://127.0.0.1:${port};  # 将请求代理到本地的 ${port} 端口
        proxy_set_header Host \$host;  # 传递原始 Host 头部
        proxy_set_header X-Real-IP \$remote_addr;  # 传递客户端的真实 IP
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;  # 传递转发的 IP
        proxy_set_header X-Forwarded-Proto \$scheme;  # 传递原始协议（HTTP/HTTPS）
    }

    proxy_buffering off; # 关闭代理缓冲
    tcp_nopush on; # 开启TCP_NOPUSH，可以提高网络效率。    
    tcp_nodelay on; # 开启TCP_NODELAY。在某些情况下，这可以减少网络的延迟。
}
EOF


# (re)start nginx
systemctl stop nginx
systemctl start nginx