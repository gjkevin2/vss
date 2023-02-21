#!/bin/bash
testdomain=`sed -n "/preread_server/{n;p;}" /etc/nginx/nginx.conf |awk -F ' ' '{print $1}'`
servername=${testdomain#*.}

systemctl stop nginx
systemctl stop xray
cat > /usr/local/etc/xray/config.json <<-EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "/dev/shm/vless.sock,666",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "dc8dd6af-62fa-480d-81bb-53eec20f58d5",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "alpn": "h2",
            "dest": "/dev/shm/h2c.sock",
            "xver": 2
          },
          {
            "dest": "/dev/shm/h1.sock",
            "xver": 2
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/root/.acme.sh/$servername/fullchain.cer",
              "keyFile": "/root/.acme.sh/$servername/$servername.key"
            }
          ]
        },
        "tcpSettings": {
          "acceptProxyProtocol": true
        },
        "sockopt": {
            "tcpFastOpen": true,
            "tcpKeepAliveIdle": 30,
            "tcpKeepAliveInterval": 30
        }
      },
      "sniffing": {
          "enabled": true,
          "destOverride": [
              "http",
              "tls"
          ]
      }
    },
    {
      "tag": "VLESS-TCP-Reality",
      "listen":"0.0.0.0",
      "protocol": "vless",
      "port":4003,
      "settings": {
        "clients": [
          {
            "id": "1bacd758-db56-4713-a936-240fccce7f2f",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "/dev/shm/h2c.sock",
          "serverNames": ["re.158742.xyz"],
          "privateKey": "R6xEek-WTsP90wyi8X1uhkjVscuqY5bf9jOEqCOPV6k",
          "shortIds": ["3f4d573ec4ce481c"]
        }
      }
    },
    {
      "listen": "/dev/shm/vgrpc.sock,666",
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
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
         "http",
         "tls"
        ]
      }
    },
    {
      "port": 10630,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
        "password": "PJBCXp8lJrg7XxRV7yfApA==",
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    },
    {
            "protocol": "blackhole",
            "tag": "blackhole"
    }
  ],
 "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
    {
      "domain": [
          "geosite:cn"
      ],
      "outboundTag": "blackhole",
      "type": "field"
    },
    {
      "ip": [
          "geoip:cn"
      ],
      "outboundTag": "blackhole",
      "type": "field"
    }

    ]
  }
}
EOF
rm -rf /dev/shm/*
systemctl start xray

# 443端口转发到实际端口
grep "v.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tv.$servername vless;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream vless {\n\t\tserver unix:/dev/shm/vless.sock;\n\t}" /etc/nginx/nginx.conf
}

systemctl start nginx