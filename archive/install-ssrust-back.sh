#!/bin/bash
cd ~
rm -rf shadowsocks-v* xray-plugin* v2ray-plugin*
lurl='https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${latest_version}/shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz
tar xf shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz -C /usr/local/bin
rm -f shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz

# v2ray-plugin
vurl='https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest'
latest_version2=`curl $vurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v${latest_version2}/v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz
tar xf v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz -C /usr/local/bin
mv /usr/local/bin/v2ray-plugin_linux_amd64 /usr/local/bin/v2ray-plugin
rm -f v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz

# xray-plugin
vurl='https://api.github.com/repos/teddysun/xray-plugin/releases/latest'
latest_version3=`curl $vurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/teddysun/xray-plugin/releases/download/v${latest_version3}/xray-plugin-linux-amd64-v${latest_version3}.tar.gz
tar xf xray-plugin-linux-amd64-v${latest_version3}.tar.gz -C /usr/local/bin
mv /usr/local/bin/xray-plugin_linux_amd64 /usr/local/bin/xray-plugin
rm -f xray-plugin-linux-amd64-v${latest_version3}.tar.gz

# creat configfile-folder
mkdir /etc/shadowsocks-rust >/dev/null 2>&1

# config.json
testdomain=`sed -n "/preread_server/{n;p;}" /etc/nginx/nginx.conf |awk -F ' ' '{print $1}'`
servername=${testdomain#*.}
# grpc has config "serviceName"
cat > /etc/shadowsocks-rust/config.json <<-EOF
{
    "servers": [
        {
            "address": "::",
            "server_port":50003,
            "password": "barfoo!",
            "method":"none",
            "fast_open":true,
            "plugin":"v2ray-plugin",
            "plugin_opts":"server;tls;path=/uri;host=s.$servername;cert=/root/.acme.sh/$servername/fullchain.cer;key=/root/.acme.sh/$servername/$servername.key"
        },
        {
            "address": "::",
            "server_port":50203,
            "password": "barfoo!",
            "method":"none",
            "fast_open":true,
            "plugin":"xray-plugin",
            "plugin_opts":"server;mode=grpc;tls;host=sx.$servername;cert=/root/.acme.sh/$servername/fullchain.cer;key=/root/.acme.sh/$servername/$servername.key"
        },
        {
            "address": "::",
            "port":50303,
            "password": "barfoo!",
            "method":"aes-256-gcm"
        }
    ]
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
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl stop ss.service
systemctl start ss.service
systemctl enable ss.service
