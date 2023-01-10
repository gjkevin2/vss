#!/bin/bash
echo '请输入顶级域名'
read domain

# set sni bypass
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
# nginx need user root to use unix socket
sed -i 's/user  nginx/user  root/g' /etc/nginx/nginx.conf
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

cat >/etc/nginx/conf.d/default.conf<<-EOF
server {
        listen 80;
        listen [::]:80;
        return 301 https://$domain\$request_uri;
}

server {
        listen unix:/dev/shm/h1.sock proxy_protocol;
        listen unix:/dev/shm/h2c.sock proxy_protocol; 
        set_real_ip_from unix:;
        return 301 https://$domain\$request_uri;
}

server {
        listen unix:/dev/shm/web.sock ssl http2 proxy_protocol;
        server_name $domain www.$domain;
        if (\$host != $domain) { return 301 https://$domain\$request_uri; }   
        set_real_ip_from unix:;
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

        location /test { # grpc serviceName与xray配置里一致
                if (\$request_method != "POST") {
                        return 404;
                }
                client_body_buffer_size 1m;
                client_body_timeout 1h;
                client_max_body_size 0;
                grpc_read_timeout 1h;
                grpc_send_timeout 1h;
                grpc_pass grpc://unix:/dev/shm/vgrpc.sock;
        }
}

server {
        listen 80;
        server_name $serverip; # 修改为自己的vps IP 此块代码功能为禁止使用IP访问网站
        return 403;
}
EOF

# repair pid file
sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
# (re)start nginx
systemctl daemon-reload
systemctl stop nginx
systemctl start nginx
