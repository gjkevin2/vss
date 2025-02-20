#!/bin/bash
domain=158742.xyz
cat >/etc/nginx/conf.d/default.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}

server {
        listen 443 ssl http2;
        server_name localhost;
        ssl_certificate /root/.acme.sh/$domain/fullchain.cer; 
        ssl_certificate_key /root/.acme.sh/$domain/$domain.key;
        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;
        ssl_session_tickets  off;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers  TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
        }
}
EOF