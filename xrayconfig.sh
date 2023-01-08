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
        "tcpSettings": {
          "acceptProxyProtocol": true
        },
        "xtlsSettings": {
          "alpn": ["h2", "http/1.1"],
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

# 443端口转发到实际端口
grep "x.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tx.$servername xtls;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream xtls {\n\t\tserver 127.0.0.1:50001;\n\t}" /etc/nginx/nginx.conf
}

# nginx set
cd /etc/nginx/conf.d
cat > $servername.conf <<-EOF
server {
        listen 80;
        listen [::]:80;
        server_name $servername;        
        location / {
                root /usr/share/nginx/html;
                index index.html;
        }
        location ^~ /subscribe/  {
                alias /usr/share/nginx/html/static/;
        }
}
server {
        listen 80;
        listen [::]:80;
        server_name x.$servername;
        return 301 http://$servername;
}
server {
        listen 80;
        listen [::]:80;
        server_name tx.$servername;
        return 301 http://$servername;
}
server {
        listen 80;
        listen [::]:80;
        server_name vw.$servername;
        return 301 http://$servername;
}

server {
        listen 80;
        listen [::]:80;
        server_name g.$servername;
        return 301 http://$servername;
}

server {
        listen 80;
        listen [::]:80;
        server_name t.$servername;
        return 301 http://$servername;
}
server {
        listen 80;
        listen [::]:80;
        server_name tg.$servername;
        return 301 http://$servername;
}
server {
        listen 80;
        listen [::]:80;
        server_name s.$servername;
        return 301 http://$servername;
}
server {
        listen 80;
        listen [::]:80;
        server_name sx.$servername;
        return 301 http://$servername;
}
EOF
# repair pid file
sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
# (re)start nginx
systemctl daemon-reload
systemctl stop nginx
systemctl start nginx