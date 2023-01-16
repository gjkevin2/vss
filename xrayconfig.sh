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
          },
          {
            "path": "/wstest",
            "dest": "@vless-ws",
            "xver": 2
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "minVersion": "1.2",
          "maxVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256",
          "alpn": ["h2", "http/1.1"],
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
      }
    },
    {
      "listen": "@vless-ws",
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
         "acceptProxyProtocol": true,
         "path": "/wstest"
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
      "listen": "/dev/shm/trojan.sock,666",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password":"461ece30"
          }
        ],
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
          "minVersion": "1.2",
          "maxVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256",
          "alpn": ["h2", "http/1.1"],
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
        "method": "2022-blake3-aes-128-gcm",
        "password": "PJBCXp8lJrg7XxRV7yfApA==",
        "network": "tcp,udp"
      }
    },
    {
      "port": 30200,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "b60af21d-da5c-4c68-a303-9461416d6bbe",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "minVersion": "1.2",
          "maxVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256",
          "alpn": ["h2", "http/1.1"],
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
#去除user，使用root读取证书
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload

# 443端口转发到实际端口
grep "t.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tt.$servername trojan;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream trojan {\n\t\tserver unix:/dev/shm/trojan.sock;\n\t}" /etc/nginx/nginx.conf
}
grep "v.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tv.$servername vless;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream vless {\n\t\tserver unix:/dev/shm/vless.sock;\n\t}" /etc/nginx/nginx.conf
}

rm -rf /dev/shm/*
systemctl start xray
systemctl start nginx