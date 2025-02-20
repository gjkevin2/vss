#!/bin/bash
domain=158742.xyz
# ssl相关配置
sed -i "/keepalive_timeout/a\\\tssl_session_cache shared:SSL:10m;\n\tssl_session_timeout 10m;\n\tset_real_ip_from 0.0.0.0/0;\n\treal_ip_header X-Forwarded-For;\n\treal_ip_recursive on;" /etc/nginx/nginx.conf
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

        location ^~ /static/ {
                root /usr/share/nginx/html/static/;
        }

        location ~* (table|ftest|output/|css|ico|gh/.*)$ {
                include uwsgi_params;
                uwsgi_pass 127.0.0.1:5060;
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
EOF


# (re)start nginx
systemctl stop nginx
systemctl start nginx