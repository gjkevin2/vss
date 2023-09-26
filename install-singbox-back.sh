#!/bin/bash
#安装
cd ~
# lurl='https://api.github.com/repos/SagerNet/sing-box/releases/latest'
# latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
# 测试版
latest_version=1.5.0-rc.5
wget https://github.com/SagerNet/sing-box/releases/download/v${latest_version}/sing-box-${latest_version}-linux-amd64.tar.gz
tar xf sing-box-${latest_version}-linux-amd64.tar.gz 
cp -f sing-box-*/sing-box /usr/local/bin && chmod +x /usr/local/bin/sing-box
rm -rf sing-box-${latest_version}-linux-amd64.tar.gz sing-box-*

# 获取ip和域名
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
testdomain=`sed -n "/^\s*server_name/p" /etc/nginx/conf.d/default.conf | awk -F' ' '{print $2}'`
# 顶级域名和二级域名都可以提取到顶级域名
a=${testdomain%.*}
servername=${a##*.}.${testdomain##*.}

# 配置文件
mkdir /usr/local/etc/sing-box 2>/dev/null
cat > /usr/local/etc/sing-box/sing-box_config.json <<-EOF
{
    "inbounds": [
        {
            "type": "shadowsocks",
            "listen": "$serverip",
            "listen_port": 50101,
            "method": "2022-blake3-aes-128-gcm",
            "password": "PJBCXp8lJrg7XxRV7yfApA=="
        },
        {
            "type": "naive",
            "listen": "127.0.0.1",
            "listen_port": 52003,
            "users": [
                {
                    "username": "naiveuser",
                    "password": "461ece30"
                }
            ],
            "tls": {
                "enabled": true,
                "certificate_path": "/root/cert/fullchain.cer",
                "key_path": "/root/cert/$servername.key"
            }
        },
        {
            "type": "hysteria2",
            "listen": "$serverip",
            "listen_port": 50102,
            "users": [
                {
                    "password": "461ece30"
                }
            ],
            "tls": {
                "enabled": true,
                "alpn": [
                    "h3"
                ],
                "certificate_path": "/root/cert/fullchain.cer",
                "key_path": "/root/cert/$servername.key"
            }
        },
        {
            "type": "tuic",
            "listen": "$serverip",
            "listen_port": 50103,
            "users": [
                {
                    "uuid": "b280fcbb-097b-4282-8e1d-cd144eb59716",
                    "password": "461ece30"
                }
            ],
            "congestion_control": "bbr",
            "tls": {
                "enabled": true,
                "alpn": [
                    "h3"
                ],
                "certificate_path": "/root/cert/fullchain.cer",
                "key_path": "/root/cert/$servername.key"
            }
        }
    ],
    "outbounds": [
        {
            "type": "direct"
        }
    ]
}
EOF
cat >/lib/systemd/system/sing-box.service<<\EOF
[Unit]
Description=Tuic server based on QUIC protocol
After=network.target

[Service]
User=root
Restart=on-abnormal
ExecStart=/usr/local/bin/sing-box run -c /usr/local/etc/sing-box/sing-box_config.json
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now sing-box
systemctl stop sing-box
systemctl stop xray
systemctl stop nginx
#去除user，使用root读取证书
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload
rm -rf /dev/shm/*

# 443端口转发到实际端口
grep "upstream singbox-naive" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tnaive.$servername singbox-naive;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream singbox-naive {\n\t\tserver 127.0.0.1:52003;\n\t}" /etc/nginx/nginx.conf
}

# (re)start nginx
systemctl start sing-box
systemctl start xray
systemctl start nginx