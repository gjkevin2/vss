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
              "certificateFile": "/root/.acme.sh/$servername/fullchain.cer",
              "keyFile": "/root/.acme.sh/$servername/$servername.key"
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
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload
systemctl start xray
systemctl enable xray

# 443端口转发到实际端口
grep "g.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tg.$servername grpc;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream grpc {\n\t\tserver 127.0.0.1:50018;\n\t}" /etc/nginx/nginx.conf
}

grep "vw.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tvw.$servername vlessws;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream vlessws {\n\t\tserver 127.0.0.1:50014;\n\t}" /etc/nginx/nginx.conf
}

grep "tx.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\ttx.$servername beforetrojanxtls;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream trojanxtls {\n\t\tserver 127.0.0.1:1310;\n\t}" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream beforetrojanxtls {\n\t\tserver 127.0.0.1:50017;\n\t}" /etc/nginx/nginx.conf
  sed -i "/remove proxy protocol/a\\\tserver {\n\t\tlisten 127.0.0.1:50017 proxy_protocol;\n\t\tproxy_pass trojanxtls;\n\t}" /etc/nginx/nginx.conf
}

grep "x.$servername" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tx.$servername beforextls;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream xtls {\n\t\tserver 127.0.0.1:50001;\n\t}" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream beforextls {\n\t\tserver 127.0.0.1:50011;\n\t}" /etc/nginx/nginx.conf
  sed -i "/remove proxy protocol/a\\\tserver {\n\t\tlisten 127.0.0.1:50011 proxy_protocol;\n\t\tproxy_pass xtls;\n\t}" /etc/nginx/nginx.conf
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
        listen 127.0.0.1:50014 ssl http2 proxy_protocol;
        set_real_ip_from 127.0.0.1;
        server_name vw.$servername;

        ssl_certificate /root/cert/fullchain.cer; 
        ssl_certificate_key /root/cert/privkey.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        ssl_prefer_server_ciphers on;
        add_header Strict-Transport-Security "max-age=31536000; includeSubservernames; preload" always; #启用HSTS
        location / {
                root /usr/share/nginx/html;
                index index.html;
        }

        location = /wstest { #与vless+ws应用中path对应
            proxy_redirect off;
            proxy_pass http://127.0.0.1:1311; #转发给本机vless+ws监听端口
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
server {
        listen 80;
        listen [::]:80;
        server_name g.$servername;
        return 301 http://$servername;
}
server {
        listen 127.0.0.1:50018 ssl http2 proxy_protocol;
        set_real_ip_from 127.0.0.1;
        server_name g.$servername;

        ssl_certificate /root/cert/fullchain.cer; 
        ssl_certificate_key /root/cert/privkey.key;
        # ssl_protocols TLSv1.2 TLSv1.3;
        # ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        # ssl_prefer_server_ciphers on;

        add_header Strict-Transport-Security "max-age=31536000; includeSubservernames; preload" always; #启用HSTS
        location / {
                root /usr/share/nginx/html;
                index index.html;
        }

        location /test { #与vless+grpc应用中serviceName对应
            if (\$request_method != "POST") {
                return 404;
            }
            client_body_buffer_size 1m;
            client_body_timeout 1071906480m;
            client_max_body_size 0;
            grpc_read_timeout 1071906480m;
            grpc_send_timeout 1h;
            grpc_pass grpc://127.0.0.1:50008;
        }
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
server {
        listen 127.0.0.1:50313 ssl http2 proxy_protocol;
        set_real_ip_from 127.0.0.1;
        server_name xss.$servername;

        ssl_certificate /root/cert/fullchain.cer; 
        ssl_certificate_key /root/cert/privkey.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        ssl_prefer_server_ciphers on;
        add_header Strict-Transport-Security "max-age=31536000; includeSubservernames; preload" always; #启用HSTS
        location / {
                root /usr/share/nginx/html;
                index index.html;
        }

        location = /uri { # 与xray里ss应用中dekodemo-door里path对应
            proxy_redirect off;
            proxy_pass http://127.0.0.1:2022; # 转发给本机dekodemo-door监听端口
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
}
EOF
# repair pid file
sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
# (re)start nginx
systemctl daemon-reload
systemctl stop nginx
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
