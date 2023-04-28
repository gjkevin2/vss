#!/bin/bash
echo '请输入顶级域名'
read domain

# set sni bypass
# serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
# nginx need user root to use unix socket
# sed -i 's/user.*/user  root/g' /etc/nginx/nginx.conf
# sed -i 's#/var/run/nginx.pid#/run/nginx.pid#g' /etc/nginx/nginx.conf
sed -i '/^stream {/,$d' /etc/nginx/nginx.conf
cat >>/etc/nginx/nginx.conf<<-EOF
stream {
    # SNI recognize
    map \$ssl_preread_server_name \$stream_map {
        www.$domain web;
        default web;
    }
    # upstream set
    upstream web {
        server unix:/dev/shm/web.sock;
    }
    server {
        listen 443;
        listen [::]:443;
        ssl_preread on;
        proxy_protocol on; 
        proxy_pass  \$stream_map;
    }
    # remove proxy_protocol
}
EOF

# ssl相关配置及realip设置
grep "ssl_certificate" /etc/nginx/nginx.conf || {
  sed -i "/keepalive_timeout/a\\\tssl_certificate \/root\/cert\/fullchain.cer;\n\tssl_certificate_key \/root\/cert\/$domain.key;\n\tset_real_ip_from 127.0.0.1;\n\treal_ip_header proxy_protocol;" /etc/nginx/nginx.conf
}


cat >/etc/nginx/conf.d/default.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    server_name ~^(www\.)?(.+)$;
    return 301 https://\$host\$request_uri;
}

server {
    listen unix:/dev/shm/web.sock ssl http2 proxy_protocol;
    server_name $domain www.$domain;
    port_in_redirect off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
EOF


# (re)start nginx
systemctl stop nginx
rm -rf /dev/shm/*
systemctl start nginx
