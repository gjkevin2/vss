#!/bin/bash

#安装v2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 安裝最新發行的 geoip.dat 和 geosite.dat,只更新 .dat 資料檔
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)

# alias cp='cp'
# cp -f config.json /usr/local/etc/v2ray/
cat > /usr/local/etc/v2ray/config.json <<-EOF
{
  "inbounds": [{
    "port": 23282,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "74a2e3cf-2b2c-4afe-b4c9-fec7124bc941",
          "level": 1,
          "alterId": 64
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
  }],
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
systemctl start v2ray
systemctl enable v2ray