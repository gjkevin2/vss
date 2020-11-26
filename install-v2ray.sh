#!/bin/bash

#安装v2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 安裝最新發行的 geoip.dat 和 geosite.dat,只更新 .dat 資料檔
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)

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
