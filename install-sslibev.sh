#!/bin/bash
apt -y install snapd haveged gawk
snap install core 
snap install shadowsocks-libev
ipaddr=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}')
cat > /snap/bin/config.json <<-EOF
{
    "server": "$ipaddr",
    "server_port": 8388,
    "password": "barfoo!",
    "method": "chacha20-ietf-poly1305",
}
EOF

cat > /lib/systemd/system/ss.service <<-EOF
[Unit]
Description=Shadowsocks Server
After=network.target

[Service]
Restart=on-abnormal
ExecStart=/snap/bin/shadowsocks-libev.ss-server -c /snap/bin/config.json > /dev/null 2>&1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start ss.service
systemctl enable ss.service
