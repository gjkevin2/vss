#!/bin/bash
cat > /usr/local/etc/xray/config.json <<-EOF
{
    "log": {
        "loglevel": "warning"
    },
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
                "method":"chacha20-ietf",
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
