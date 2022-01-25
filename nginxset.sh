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
                x.$domain beforextls;
                tx.$domain beforetrojanxtls;
                vw.$domain vlessws;
                g.$domain grpc;
                t.$domain beforetrojan;
                tg.$domain beforetrojango;
                s.$domain beforess;
                sx.$domain beforessx;
                www.$domain web;
        }
        upstream beforextls { # remove "Proxy protocol"
                server 127.0.0.1:50011;
        }
        upstream xtls {
                server 127.0.0.1:50001;
        }
        upstream beforetrojanxtls {
                server 127.0.0.1:50017;
        }
        upstream trojanxtls {
                server 127.0.0.1:1310;
        }
        upstream vlessws {
                server 127.0.0.1:50014;
        }
        upstream grpc {
                server 127.0.0.1:50018;
        }
        upstream beforetrojan {
                server 127.0.0.1:50012; 
        }
        upstream trojan {
                server 127.0.0.1:50002; 
        }
        upstream beforetrojango {
                server 127.0.0.1:50019; 
        }
        upstream trojango {
                server 127.0.0.1:50009; 
        }
        upstream beforess {
                server 127.0.0.1:50013;
        }
        upstream ss {
                server 127.0.0.1:50003;
        }
        upstream beforessx {
                server 127.0.0.1:50213;
        }
        upstream ssx {
                server 127.0.0.1:50203;
        }
        upstream web { # just local port 443
                server 127.0.0.1:443;
        }
        server {
                listen $serverip:443      reuseport;  # listen server port 443
                # listen [::]:443 reuseport;
                proxy_pass      \$stream_map;
                ssl_preread     on;
                proxy_protocol on;                    # start Proxy protocol
        }
        # remove proxy protocol
        server {
                listen 127.0.0.1:50011 proxy_protocol;
                proxy_pass xtls;   # redirect to xtls 
        }
        server {
                listen 127.0.0.1:50017 proxy_protocol;
                proxy_pass trojanxtls;   # redirect to trojanxtls 
        }
        server {
                listen 127.0.0.1:50012 proxy_protocol;
                proxy_pass trojan;   # redirect to trojan 
        }
        server {
                listen 127.0.0.1:50019 proxy_protocol;
                proxy_pass trojango;   # redirect to trojango
        }
        server {
                listen 127.0.0.1:50013 proxy_protocol;
                proxy_pass ss;   # redirect to ss 
        }
        server {
                listen 127.0.0.1:50213 proxy_protocol;
                proxy_pass ssx;   # redirect to ssx
        }
}
EOF


cd /etc/nginx/conf.d
aconf=$(ls |grep -v default)
rm -rf $aconf
cat > $domain.conf <<-EOF
server {
        listen 80;
        server_name $domain;        
        location / {
                root /usr/share/nginx/html;
                index index.html;
        }
        location ^~ /subscribe/  {
                alias /usr/share/nginx/html/static/;
        }
}
server {
        listen 80;
        server_name x.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name tx.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name vw.$domain;
        return 301 http://$domain;
}
server {
        listen 127.0.0.1:50014 ssl http2 proxy_protocol;
        set_real_ip_from 127.0.0.1;
        server_name vw.$domain;

        ssl_certificate /root/cert/fullchain.cer; 
        ssl_certificate_key /root/cert/privkey.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        ssl_prefer_server_ciphers on;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always; #启用HSTS
        location / {
                root /usr/share/nginx/html;
                index index.html;
        }

        location = /wstest { #与vless+ws应用中path对应
            proxy_redirect off;
            proxy_pass http://127.0.0.1:1311; #转发给本机vless+ws监听端口
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
server {
        listen 80;
        server_name g.$domain;
        return 301 http://$domain;
}
server {
        listen 127.0.0.1:50018 ssl http2 proxy_protocol;
        set_real_ip_from 127.0.0.1;
        server_name g.$domain;

        ssl_certificate /root/cert/fullchain.cer; 
        ssl_certificate_key /root/cert/privkey.key;
        # ssl_protocols TLSv1.2 TLSv1.3;
        # ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        # ssl_prefer_server_ciphers on;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always; #启用HSTS
        location / {
                root /usr/share/nginx/html;
                index index.html;
        }

        location /test { #与vless+grpc应用中serviceName对应
            if (\$request_method != "POST") {
                return 404;
            }
            client_body_buffer_size 1m;
            client_body_timeout 1071906480m;
            client_max_body_size 0;
            grpc_read_timeout 1071906480m;
            grpc_send_timeout 1h;
            grpc_pass grpc://127.0.0.1:50008;
        }
}
server {
        listen 80;
        server_name t.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name tg.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name s.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name sx.$domain;
        return 301 http://$domain;
}
EOF
# repair pid file
sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
# (re)start nginx
systemctl stop nginx
systemctl start nginx
