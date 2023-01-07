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
        server {
                listen $serverip:443      reuseport;  # listen server port 443
                listen [::]:443 reuseport;
                proxy_pass      \$stream_map;
                ssl_preread     on;
                proxy_protocol on;                    # start Proxy protocol
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
