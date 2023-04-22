#!/bin/bash
echo '请输入顶级域名'
read domain

# set sni bypass
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
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
grep "ssl_session_timeout" /etc/nginx/nginx.conf || {
  sed -i "/keepalive_timeout/a\\\tssl_session_cache shared:SSL:10m;\n\tssl_session_timeout 10m;\n\tset_real_ip_from 0.0.0.0/0;\n\treal_ip_header X-Forwarded-For;\n\treal_ip_recursive on;" /etc/nginx/nginx.conf
}


cat >/etc/nginx/conf.d/default.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    return 301 https://\$host\$request_uri;
}

server {
    listen unix:/dev/shm/web.sock ssl http2 proxy_protocol;
    server_name ~^(?<www>www\.)?(.+)$; 
    if (\$www) {return 301 https://\$2\$request_uri;}

    ssl_certificate /root/cert/fullchain.cer; 
    ssl_certificate_key /root/cert/$domain.key;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4:!RSA;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
EOF


# (re)start nginx
systemctl stop nginx
systemctl start nginx
