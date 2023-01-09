#!/bin/bash
echo '请输入顶级域名'
read domain

# set sni bypass
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
sed -i '/^stream {/,$d' /etc/nginx/nginx.conf
cat >>/etc/nginx/nginx.conf<<-EOF
stream {
        # SNI recognize
        map \$ssl_preread_server_name \$stream_map {
                www.$domain web;                
        }
        # upstream set
        upstream web {
                server 127.0.0.1:8443;
        }
        server {
                listen $serverip:443    reuseport;  # listen server port 443
                listen [::]:443 reuseport;
                proxy_pass      \$stream_map;
                ssl_preread     on;
                proxy_protocol on;                    # start Proxy protocol
        }
}
EOF

cat >/etc/nginx/conf.d/default.conf<<-EOF
set_real_ip_from 127.0.0.1;
real_ip_header proxy_protocol;

server {
        listen 80;
        listen [::]:80;
        server_name localhost;
        location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
                root   /usr/share/nginx/html;
        }
}
server {
        listen 80;
        listen [::]:80;
        server_name www.$domain;
        return 301 https://www.$domain\$request_uri;
}
server {
        listen 8443 ssl http2 proxy_protocol;
        listen [::]:8443 ssl http2 proxy_protocol;
        server_name www.$domain;

        ssl_certificate /root/.acme.sh/$domain/fullchain.cer; 
        ssl_certificate_key /root/.acme.sh/$domain/$domain.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        ssl_prefer_server_ciphers on;
        add_header Strict-Transport-Security "max-age=31536000; includeSubservernames; preload" always; #启用HSTS
        location / {
                root   /usr/share/nginx/html;
                index  index.html index.htm;
        }
}
EOF

# repair pid file
sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
# (re)start nginx
systemctl daemon-reload
systemctl stop nginx
systemctl start nginx
