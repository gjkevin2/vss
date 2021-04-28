#!/bin/bash
cd ~
rm -rf shadowsocks-v* v2ray-plugin*
lurl='https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${latest_version}/shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz
tar xf shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz -C /usr/local/bin

#v2plugin
vurl='https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest'
latest_version2=`curl $vurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v${latest_version2}/v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz
tar xf v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz -C /usr/local/bin
mv /usr/local/bin/v2ray-plugin_linux_amd64 /usr/local/bin/v2ray-plugin

# creat configfile-folder
mkdir /etc/shadowsocks-rust >/dev/null 2>&1

# config.json
#ipaddr=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
cat > /etc/shadowsocks-rust/config.json <<-EOF
{
    "servers": [
        {
            "address": "127.0.0.1",
            "port": 8388,
            "password": "barfoo!",
            "method": "chacha20-ietf-poly1305",
            "timeout": 7200
        },
        {
            "server":"127.0.0.1",
            "server_port":9000,
            "timeout":300,
            "method":"chacha20-ietf",
            "password":"password0",
            "fast_open":false,
            "nameserver":"dns.google",
            "mode":"tcp_only",
            "plugin":"v2ray-plugin",
            "plugin_opts":"server;path=/uri"
        }
    ]
}
EOF

#nginx config
cat >/etc/nginx/conf.d/ssrust.conf<<-EOF
server {
    listen 443 ssl;
    server_name sli.flyrain.tk;
    ssl_certificate  /root/cert/fullchain.cer;
    ssl_certificate_key /root/cert/privkey.key;
    ssl_session_timeout 5m;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;

 # 转发https协议
    location /{
        proxy_pass https://imeizi.me;
        proxy_set_header   X-Real-IP        $remote_addr;
        proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
    }

    # 转发wss协议
    location /uri {
        proxy_pass http://127.0.0.1:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

#server
cat > /lib/systemd/system/ss.service <<-EOF
[Unit]
Description=Shadowsocks Server
After=network.target
[Service]
Restart=on-abnormal
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks-rust/config.json
StandardOutput=null
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl reload nginx
systemctl start ss.service
systemctl enable ss.service
