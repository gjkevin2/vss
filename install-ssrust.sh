#!/bin/bash
cd ~
lurl='https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`

wget https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-linux-amd64.tar.xz
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${latest_version}/shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz
tar xf shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz


# creat configfile-folder
mkdir /etc/shadowsocks-rust && cd /etc/shadowsocks-rust

# config.json
ipaddr=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
cat > /etc/shadowsocks-rust/config.json <<-EOF
{
    "server": "$ipaddr",
    "server_port": 8388,
    "password": "barfoo!",
    "method": "chacha20-ietf-poly1305",
}
EOF

#server
cat > /lib/systemd/system/ss.service <<-EOF
[Unit]
Description=Shadowsocks Server
After=network.target
[Service]
Restart=on-abnormal
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks-rust/config.json > /dev/null 2>&1
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start ss.service
systemctl enable ss.service
