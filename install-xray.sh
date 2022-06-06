#!/bin/bash
#安装xray 和最新发行的 geoip.dat 和 geosite.dat,
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

# 获取ip和域名
apt -y install gawk
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
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
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
              "certificateFile": "/root/.acme.sh/$servername/fullchain.cer",
              "keyFile": "/root/.acme.sh/$servername/$servername.key"
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
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
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
              "certificateFile": "/root/.acme.sh/$servername/fullchain.cer",
              "keyFile": "/root/.acme.sh/$servername/$servername.key"
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
=======
              "certificateFile": "/root/cert/fullchain.cer",
              "keyFile": "/root/cert/privkey.key"
>>>>>>> 7280d897a15cea412781d849609ec04c493c7462
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
      "protocol": "dokodemo-door",
      "settings": {
        "address": "v1.mux.cool"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/uri"
        }
      },
      "tag":"ddws"
    },
    {
      "listen": "127.0.0.1",
      "port": 2021,
      "protocol": "shadowsocks",
      "settings": {
        "method": "none",
        "password": "barfoo!"
      },
      "streamSettings": {
        "network": "domainsocket",
        "security": "none",
        "dsSettings": {
          "path": "ss",
          "abstract": true
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "ssds",
      "protocol": "freedom",
      "streamSettings": {
        "network": "domainsocket",
        "dsSettings": {
          "path": "ss",
          "abstract": true
        }
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": "ddws",
        "outboundTag": "ssds"
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

#修改配置文件
wget -O /usr/share/nginx/html/static/config.yaml https://raw.githubusercontent.com/gjkevin2/vss/master/config.yaml
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.yaml
sed -i 's/maindomain/'$servername'/g' /usr/share/nginx/html/static/config.yaml
wget -O /usr/share/nginx/html/static/config.json https://raw.githubusercontent.com/gjkevin2/vss/master/config.json
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.json
sed -i 's/servername/'$servername'/g' /usr/share/nginx/html/static/config.json
#生成ss，vmess订阅
bash create-ref.sh $serverip
