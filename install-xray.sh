#!/bin/bash
#安装xray
bash <(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

# 安裝最新發行的 geoip.dat 和 geosite.dat,只更新 .dat 資料檔
bash <(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-dat-release.sh)

cat > /usr/local/etc/xray/config.json <<-EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 50001,
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
                        "dest": 1310,
                        "xver": 1
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
                            "certificateFile": "/root/cert/fullchain.cer",
                            "keyFile": "/root/cert/privkey.key" 
                        }
                    ]
                }
            }
        },
        {
            "port": 1310,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "461ece30",
                        "level": 0
                    }
                ],
                "fallbacks": [
                    {
                        "dest": 80
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": true
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
                "method":"aes-256-gcm",
                "password":"barfoo!"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ],
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
systemctl stop xray
#去除user，使用root读取证书
sed -i "s/User=nobody//" /etc/systemd/system/xray.service
systemctl daemon-reload
systemctl start xray
systemctl enable xray

apt -y install gawk
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
servername=$(ls /etc/nginx/conf.d |grep -v default|head -c -6)
wget -O /usr/share/nginx/html/static/config.yaml https://raw.githubusercontent.com/gjkevin2/vss/master/config.yaml
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.yaml
sed -i 's/maindomain/'$servername'/g' /usr/share/nginx/html/static/config.yaml
wget -O /usr/share/nginx/html/static/config.json https://raw.githubusercontent.com/gjkevin2/vss/master/config.json
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.json
sed -i 's/servername/'$servername'/g' /usr/share/nginx/html/static/config.json
#生成ss，vmess订阅
bash create-ref.sh $serverip
