#!/bin/bash
#安装
# 测试版
 bash -c "$(curl -L https://sing-box.vercel.app)" @ install --beta

# 获取ip和域名
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
testdomain=`sed -n "/^\s*server_name/p" /etc/nginx/conf.d/default.conf | awk -F' ' '{print $2}'`
# 顶级域名和二级域名都可以提取到顶级域名
a=${testdomain%.*}
servername=${a##*.}.${testdomain##*.}

# 配置文件
# reality的public key： GuapS0D1QmrqLgMgwPijrWmMaYH1231UXuWvPYWjoxs
cat > /usr/local/etc/sing-box/config.json <<-EOF
{
    "inbounds": [
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
            "type": "shadowsocks",
            "listen": "$serverip",
            "listen_port": 50101,
            "method": "2022-blake3-aes-128-gcm",
            "password": "PJBCXp8lJrg7XxRV7yfApA=="
        },
        {
            "type": "vless",
            "listen": "127.0.0.1",
            "listen_port": 52004,
            "users": [
                {
                    "uuid": "461edf16-8619-4f46-8e1e-e3994c8c00a2",
                    "flow": "xtls-rprx-vision"
                }
            ],
            "tls": {
                "enabled": true,
                "server_name": "ameblo.jp",
                "reality": {
                    "enabled": true,
                    "handshake": {
                        "server": "ameblo.jp",
                        "server_port": 443
                    },
                    "private_key": "kOi18qSHQVA-mc6Db3ayv9gu8vgN82KsLb36d5-OCXg",
                    "short_id": [
                        "b2c86d5449d237fa"
                    ]
                }
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
systemctl stop sing-box
systemctl stop xray
systemctl stop nginx
#去除user，使用root读取证书
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload
rm -rf /dev/shm/*

# 443端口转发到实际端口
grep "upstream singbox-reality" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\tameblo.jp singbox-reality;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream singbox-reality {\n\t\tserver 127.0.0.1:52004;\n\t}" /etc/nginx/nginx.conf
}

# (re)start nginx
systemctl start sing-box
systemctl start xray
systemctl start nginx