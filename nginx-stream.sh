#!/bin/bash
domain=flyrain.tk
# set sni bypass
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
sed -i '/^stream {/,$d' /etc/nginx/nginx.conf
cat >>/etc/nginx/nginx.conf<<-EOF
stream {
        # SNI recognize
        map \$ssl_preread_server_name \$stream_map {
                x.$domain beforextls;
                g.$domain grpc;
                t.$domain beforetrojan;
                tg.$domain beforetrojango;
                s.$domain beforess;
                www.$domain web;
        }
        upstream beforextls { # remove "Proxy protocol"
                server 127.0.0.1:50011;
        }
        upstream xtls {
                server 127.0.0.1:50001;
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
}
EOF

mkdir /usr/share/nginx/html/static >/dev/null 2>&1
cd /etc/nginx/conf.d
aconf=$(ls |grep -v default)
rm -rf $aconf
cat > $domain.conf <<-EOF
server {
        listen 80;
        server_name $domain;
        root /usr/share/nginx/html;
        location / {
        proxy_ssl_server_name on;
        proxy_pass https://imeizi.me;
        }
        location = /robots.txt {
        }
        location ^~ /subscribe/  {
        alias /usr/share/nginx/html/static/;
        }
}
server {
        listen 80;
        server_name x.$domain;
        return 301 https://$domain;
}
server {
        listen 80;
        server_name g.$domain;
        return 301 https://$domain;
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
        root /usr/share/nginx/html;
        location / {
                proxy_ssl_server_name on;
                proxy_pass https://imeizi.me;
        }

        location /test { #与vless+grpc应用中serviceName对应
            grpc_pass grpc://127.0.0.1:50008; 
        }
}
server {
        listen 80;
        server_name t.$domain;
        return 301 https://$domain;
}
server {
        listen 80;
        server_name tg.$domain;
        return 301 https://$domain;
}
server {
        listen 80;
        server_name s.$domain;
        return 301 https://$domain;
}
EOF
systemctl stop nginx
systemctl start nginx