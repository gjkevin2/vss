#!/bin/bash

#安装v2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 安裝最新發行的 geoip.dat 和 geosite.dat,只更新 .dat 資料檔
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)

# alias cp='cp'
# cp -f config.json /usr/local/etc/v2ray/
domain="tj.flyrain.tk"

cat > /usr/local/etc/v2ray/config.json <<-EOF
{
  "inbounds": [
    {
        "port": 443,
        "protocol": "vless",
        "settings": {
            "clients": [
                {
                    "id": "dc8dd6af-62fa-480d-81bb-53eec20f58d5",
                    "flow": "xtls-rprx-direct",
                    "level": 0
                }
            ],
            "decryption": "none",
            "fallbacks": [
              {
                  "dest": 80
              }
            ]
        },
        "streamSettings": {
            "network": "tcp",
            "security": "xtls",
            "xtlsSettings": {
                "alpn": [
                    "http/1.1"
                ],
                "certificates": [
                    {
                        "certificateFile": "$HOME/cert/fullchain.cer",
                        "keyFile": "$HOME/cert/privkey.key"
                    }
                ]
            }
        }
    },
    {
        "port": 23282,
        "protocol": "vmess",
        "settings": {
            "clients": [
                {
                    "id": "74a2e3cf-2b2c-4afe-b4c9-fec7124bc941",
                    "level": 1,
                    "alterId": 0
                }
            ]
        }
    },
    {
        "port":10630,
        "protocol":"shadowsocks",
        "settings":{
            "method":"chacha20-ietf",
            "password":"barfoo!"
        }
    }
  ],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  },{
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
#去除user，使用root读取证书
sed -i "s/User=nobody//" /etc/systemd/system/v2ray.service
systemctl daemon-reload
systemctl start v2ray
systemctl enable v2ray

cat >/etc/yum.repos.d/nginx.repo<<-EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
yum -y install  nginx

mkdir /usr/share/nginx/html/static >/dev/null 2>&1
cat > /etc/nginx/conf.d/$domain.conf <<-EOF
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
EOF
systemctl enable nginx
systemctl stop nginx
systemctl start nginx