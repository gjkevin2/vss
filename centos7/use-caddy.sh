yum-config-manager --add-repo https://copr.fedorainfracloud.org/coprs/g/caddy/caddy/repo/epel-7/group_caddy-caddy-epel-7.repo
yum install caddy -y
domain="flyrain.tk"
email="gkevin2@163.com"
root="/usr/share/caddy"
vport=23282
# cat > /etc/caddy/Caddyfile <<-EOF
# $domain {
#     encode gzip
#     tls $email
#     root * $root
#     file_server browse
# }
# EOF
cat > /etc/caddy/Caddyfile <<-EOF
$domain {
    @websockets {
        header Connection *Upgrade*
        header Upgrade websocket
    }
    reverse_proxy @websockets localhost:$vport
}
EOF
#mod v2ray
cat > /usr/local/etc/v2ray/config.json <<-EOF
{
    "inbounds": [{
        "port": $vport,
        "listen":"127.0.0.1",
        "protocol": "vmess",
        "settings": {
            "clients": [
                {
                    "id": "74a2e3cf-2b2c-4afe-b4c9-fec7124bc941",
                    "level": 1,
                    "alterId": 64
                }
            ]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": {
                "path": "/ws"
            }
        }},
        {
        "port":10630,
        "protocol":"shadowsocks",
        "settings":{
          "method":"chacha20-ietf",
          "password":"barfoo!"
        }
    }],
    "outbounds": [{
        "protocol": "freedom",
        "settings": {}
        },
        {
        "protocol": "blackhole",
        "settings": {},
        "tag": "blocked"
    }],
    "routing": {
        "rules": [
            {
            "type": "field",
            "ip": ["geoip:private"],
            "outboundTag": "blocked"
            }
        ]
    }
}
EOF

systemctl enable caddy
systemctl start caddy

systemctl stop v2ray
systemctl start v2ray