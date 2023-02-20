#!/bin/bash
#安装xray 和最新发行的 geoip.dat 和 geosite.dat,
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

# 获取ip和域名
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
systemctl stop xray
systemctl stop nginx
#去除user，使用root读取证书
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload
rm -rf /dev/shm/*
systemctl start xray
systemctl enable xray

# 443端口转发到实际端口
grep "t.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tt.$servername trojan;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream trojan {\n\t\tserver unix:/dev/shm/trojan.sock;\n\t}" /etc/nginx/nginx.conf
}
grep "v.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tv.$servername vless;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream vless {\n\t\tserver unix:/dev/shm/vless.sock;\n\t}" /etc/nginx/nginx.conf
}

# (re)start nginx
systemctl daemon-reload
systemctl start nginx

#修改配置文件
cd ~
wget -O /usr/share/nginx/html/static/config.yaml https://raw.githubusercontent.com/gjkevin2/vss/master/config.yaml
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.yaml
sed -i 's/maindomain/'$servername'/g' /usr/share/nginx/html/static/config.yaml
wget -O /usr/share/nginx/html/static/config.json https://raw.githubusercontent.com/gjkevin2/vss/master/config.json
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.json
sed -i 's/servername/'$servername'/g' /usr/share/nginx/html/static/config.json
#生成ss，vmess订阅
bash create-ref.sh $serverip
