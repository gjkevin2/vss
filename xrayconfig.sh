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
      "listen": "/dev/shm/vless.sock",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "dc8dd6af-62fa-480d-81bb-53eec20f58d5",
            "flow": "xtls-rprx-direct"
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
        "security": "xtls",
        "xtlsSettings": {
          "alpn": [
            "h2",
            "http/1.1"
          ],
          "minVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
          "certificates": [
            {
              "certificateFile": "/root/.acme.sh/$servername/fullchain.cer",
              "keyFile": "/root/.acme.sh/$servername/$servername.key",
              "ocspStapling": 3600
            }
          ]
        },
        "tcpSettings": {
          "acceptProxyProtocol": true
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
      "listen": "/dev/shm/trojan.sock",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password":"461ece30",
            "flow": "xtls-rprx-direct"
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
        "security": "xtls",
        "xtlsSettings": {
          "alpn": [
            "h2"
          ],
          "minVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
          "certificates": [
            {
              "certificateFile": "/root/.acme.sh/$servername/fullchain.cer",
              "keyFile": "/root/.acme.sh/$servername/$servername.key",
              "ocspStapling": 3600
            }
          ]
        },
        "tcpSettings": {
          "acceptProxyProtocol": true
        }
      }
    },
    {
      "listen": "/dev/shm/vgrpc.sock",
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
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
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