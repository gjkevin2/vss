#!/bin/bash
# 删除
# bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
#安装xray 和最新发行的 geoip.dat 和 geosite.dat,
# bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.1
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

# 获取ip和域名
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|grep -v 172.|awk -F '/' '{print $1}'|tr -d "inet ")
# testdomain=`sed -n "/preread_server/{n;p;}" /etc/nginx/nginx.conf |awk -F ' ' '{print $1}'`
# servername=${testdomain#*.}

# 注:下面的私key对应的公key是：t9vXFAGogW4e9jP7uYemUY9-0TSf8dqNeFD5uPrTPj4
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
            "dest": "/dev/shm/web.sock",
            "xver": 2
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.lovelive-anime.jp:443",
          "xver": 0,
          "serverNames": ["www.lovelive-anime.jp"],
          "privateKey": "OBoNu9hZWvPuxdmRoBUQSQyyZht0EycMw4ie3S0zFVA",
          "shortIds": ["6ba85179e30d4fc2"]
        },
        "tcpSettings": {
          "acceptProxyProtocol": true
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
    },
    {
      "listen":"$serverip",
      "port":18880,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "286e1077-4f3a-4522-bd5a-317cc6b32af0",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/ray?ed=2560"
        }
      }
    },
    {
      "port":19990,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "6a57458f-e196-45d1-b686-3179abf4284f"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "httpupgrade",
        "httpupgradeSettings": {
          "path": "/ht?ed=2560"
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
systemctl stop xray
systemctl stop nginx
#去除user，使用root读取证书
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload
rm -rf /dev/shm/*
systemctl start xray
systemctl enable xray

# 443端口转发到实际端口
grep "upstream vless" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\twww.lovelive-anime.jp vless;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream vless {\n\t\tserver unix:/dev/shm/vless.sock;\n\t}" /etc/nginx/nginx.conf
}

# (re)start nginx
systemctl daemon-reload
systemctl start nginx