#!/bin/bash
testdomain=`sed -n "/preread_server/{n;p;}" /etc/nginx/nginx.conf |awk -F ' ' '{print $1}'`
servername=${testdomain#*.}

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
            "alterId": 0,
            "level": 0
          }
        ],
        "decryption": "none"
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
              "certificateFile": "/root/.acme.sh/$servername/fullchain.cer",
              "keyFile": "/root/.acme.sh/$servername/$servername.key"
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
            "level": 1
          }
        ]
      }
    },
    {
      "port": 10630,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-256-gcm",
        "password": "barfoo!"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
systemctl stop xray
#去除user，使用root读取证书
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload
systemctl start xray