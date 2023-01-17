#!/bin/bash
cd ~
lurl='https://api.github.com/repos/EAimTY/tuic/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"]' '{print $5}'`
wget https://github.com/EAimTY/tuic/releases/download/${latest_version}/tuic-server-${latest_version}-x86_64-linux-gnu
chmod +x tuic-server-${latest_version}-x86_64-linux-gnu
mv tuic-server-${latest_version}-x86_64-linux-gnu /usr/bin/tuic

mkdir /etc/tuic >/dev/null 2>&1
cat >/etc/tuic/config.json<<-EOF
{
    "port": 16386,
    "token": ["461ece30"],
    "certificate": "/root/.acme.sh/$servername/fullchain.cer",
    "private_key": "/root/.acme.sh/$servername/$servername.key",
    "ip": "0.0.0.0",
    "congestion_controller": "cubic", #拥塞控制算法可以选择 cubic/bbr/new_reno 默认是cubic
    "max_idle_time": 15000,
    "authentication_timeout": 1000,
    "alpn": ["h3"], #ALPN协议可以设置多个，我这里就只设置一个了
    "max_udp_relay_packet_size": 1500,
    "log_level": "warning"
}
EOF

#server
cat > /lib/systemd/system/tuic.service <<-EOF
[Unit]
Description=Tuic server based on QUIC protocol
After=network.target
[Service]
user=root
Restart=on-abnormal
ExecStart=/usr/bin/tuic -c /etc/tuic/config.json
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl stop tuic.service
systemctl start tuic.service
systemctl enable tuic.service