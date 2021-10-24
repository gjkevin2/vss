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

# creat configfile-folder
mkdir /etc/shadowsocks-rust >/dev/null 2>&1

# config.json
servername=$(ls /etc/nginx/conf.d |grep -v default|head -c -6)
cat > /etc/shadowsocks-rust/config.json <<-EOF
{
    "servers": [
        {
            "address": "127.0.0.1",
            "server_port":50003,
            "password": "barfoo!",
            "method":"aes-256-gcm",
            "plugin":"v2ray-plugin",
            "plugin_opts":"server;tls;path=/uri;host=s.$servername;cert=/root/cert/fullchain.cer;key=/root/cert/privkey.key",
            "timeout":7200
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
StandardOutput=null
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl stop ss.service
systemctl start ss.service
systemctl enable ss.service
