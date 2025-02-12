#!/bin/bash
#安装
# 测试版
 # bash -c "$(curl -L https://sing-box.vercel.app)" @ install --beta
 bash -c "$(curl -L https://sing-box.vercel.app)" @ install
 # bash -c "$(curl -L sing-box.vercel.app)" @ remove

# 获取ip和域名
# serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|grep -v 172.|awk -F '/' '{print $1}'|tr -d "inet ")
testdomain=`sed -n "/^\s*server_name/p" /etc/nginx/conf.d/default.conf | awk -F' ' '{print $2}'`
# 顶级域名和二级域名都可以提取到顶级域名
a=${testdomain%.*}
servername=${a##*.}.${testdomain##*.}

# 配置文件
# sing-box generate uuid
# sing-box generate reality-keypair
# reality的public key： Y8cBV8RyH9hSkdy0ATDC9T4s0hzMq1rUXU_YmH6Fgj4
# 偷证书的网站必须支持TLSv1.3和H2
cat > /usr/local/etc/sing-box/config.json <<-EOF
{
    "inbounds": [
        {
            "type": "hysteria2",
            "listen": "::",
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
            "listen": "::",
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
                "server_name": "www.microsoft.com",
                "reality": {
                    "enabled": true,
                    "handshake": {
                        "server": "www.microsoft.com",
                        "server_port": 443
                    },
                    "private_key": "QBzN1AK91YVPC8ujyQ4BvZ1d4iexRrDUgLgVvXutIWw",
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
# systemctl stop xray
systemctl stop nginx
#去除user，使用root读取证书
#sed -i "s/User=nobody//" /etc/systemd/system/xray.service
#systemctl daemon-reload
rm -rf /dev/shm/*

# 443端口转发到实际端口，nginx还要移除proxy_protocol
grep "upstream singbox-reality" /etc/nginx/nginx.conf || {
  sed -i "/\$ssl_preread_server_name/a\\\t\twww.microsoft.com singbox-proxy;" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream singbox-reality {\n\t\tserver 127.0.0.1:52004;\n\t}" /etc/nginx/nginx.conf
  sed -i "/upstream set/a\\\tupstream singbox-proxy {\n\t\tserver 127.0.0.1:52204;\n\t}" /etc/nginx/nginx.conf
  sed -i "/remove proxy_protocol/a\\\tserver {\n\t\tlisten 52204 proxy_protocol;\n\t\tproxy_pass singbox-reality;\n\t}" /etc/nginx/nginx.conf
}

# (re)start nginx
systemctl start sing-box
# systemctl start xray
systemctl start nginx