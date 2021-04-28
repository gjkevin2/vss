#!/bin/bash
#nginx config
cat >/etc/nginx/conf.d/ssrust.conf<<-EOF
server {
    listen              80;
    listen              443 ssl;
    server_name         sli.flyrain.tk;
    ssl_certificate     /root/cert/fullchain.cer;
    ssl_certificate_key /root/cert/privkey.key;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_ssl_server_name on;
        proxy_pass https://imeizi.me;
    }

    # 拦截websocket请求
    location /websocket {
        proxy_pass http://127.0.0.1:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
systemctl daemon-reload
systemctl stop nginx
systemctl start nginx
