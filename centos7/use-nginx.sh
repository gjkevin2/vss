yum -y update && yum -y install curl socat nginx
curl https://get.acme.sh | sh

domain="flyrain.tk"
# odomain=${domain#*.}
vport=23282

#creat ssl cert
systemctl stop nginx
~/.acme.sh/acme.sh --issue --standalone -d $domain
#installcert
rm -rf /etc/nginx/ssl
mkdir /etc/nginx/ssl
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   /etc/nginx/ssl/$domain.key \
        --fullchain-file /etc/nginx/ssl/fullchain.cer 
#mod nginx
touch /run/nginx.pid #creat a pid file in order to avoid error
cat >/etc/nginx/conf.d/v2ray-ss.conf<<-EOF
server {
        listen 80;
        server_name $domain;
        return 301 https://\$server_name\$request_uri;
}

server {
        listen 443 ssl;
        server_name $domain;
        access_log /etc/nginx/access.log main;
        ssl_certificate  /etc/nginx/ssl/fullchain.cer;
        ssl_certificate_key /etc/nginx/ssl/$domain.key;
        ssl_session_timeout 5m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        location /ws {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:$vport;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            # Show realip in v2ray access.log
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
EOF
systemctl start nginx

#mod v2ray
cat > /usr/local/etc/v2ray/config.json <<-EOF
{
    "inbounds": [{
        "port": $vport,
        "listen":"127.0.0.1",
        "protocol": "vmess",
        "settings": {
            "clients": [
                {
                    "id": "74a2e3cf-2b2c-4afe-b4c9-fec7124bc941",
                    "level": 1,
                    "alterId": 0
                }
            ]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": {
                "path": "/ws",
                "headers":{
                    "Host":"$domain"
                }
            }
        }},
        {
        "port":10630,
        "protocol":"shadowsocks",
        "settings":{
          "method":"chacha20-ietf",
          "password":"barfoo!"
        }
    }],
    "outbounds": [{
        "protocol": "freedom",
        "settings": {}
        },
        {
        "protocol": "blackhole",
        "settings": {},
        "tag": "blocked"
    }],
    "routing": {
        "rules": [
            {
            "type": "field",
            "ip": ["geoip:private"],
            "outboundTag": "blocked"
            }
        ]
    }
}
EOF
systemctl stop v2ray
systemctl start v2ray