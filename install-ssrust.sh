#!/bin/bash
cd ~
rm -rf shadowsocks-v* xray-plugin* v2ray-plugin*
lurl='https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${latest_version}/shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz
tar xf shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz -C /usr/local/bin
rm -f shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz

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
