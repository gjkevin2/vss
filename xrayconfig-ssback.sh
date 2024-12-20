#!/bin/bash
cat > /usr/local/etc/xray/config.json <<-EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
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
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
            }
          ]
        }
      }
    },
    {
      "port": 50008,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "0c131050-d263-45cf-8d84-db3785197031"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "test"
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
            "flow": "xtls-rprx-direct",
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
      "port": 1311,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "bf45efa6-9d98-4553-a627-8715c1a491b8"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/wstest"
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
    },
    {
      "listen": "127.0.0.1",
      "port": 2022,
      "protocol": "shadowsocks",
      "settings": {
        "method":"chacha20-ietf-poly1305",
        "password":"barfoo!"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/uri"
        }
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
sed -i "s/User=nobody//" /etc/systemd/system/xray.service
systemctl daemon-reload
systemctl start xray
