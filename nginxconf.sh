#!/bin/bash
#nginx config
cat >/etc/nginx/conf.d/ssrust.conf<<-EOF
server {
    listen              80;
    listen              443 ssl;
    server_name         sli.flyrain.tk;
    ssl_certificate     /root/cert/fullchain.cer;
    ssl_certificate_key /root/cert/privkey.key;
    #ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    #ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_ssl_server_name on;
        proxy_pass https://imeizi.me;
    }

 # 转发https协议
    # location / {
    #     proxy_pass  https://imeizi.me;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    # }
}
EOF
systemctl daemon-reload
systemctl restart nginx
