#!/bin/bash
servername=$(ls /etc/nginx/conf.d |grep -v default|head -c -6)
cat > /etc/shadowsocks-rust/config.json <<-EOF
{
    "servers": [
        {
            "address": "127.0.0.1",
            "server_port":50003,
            "password": "barfoo!",
            "timeout":300,
            "method": "chacha20-ietf-poly1305",
            "no_delay": true,
            "mode":"tcp_and_udp",
            "plugin":"v2ray-plugin",
            "plugin_opts":"server;tls;path=/uri;host=s.$servername;cert=/root/cert/fullchain.cer;key=/root/cert/privkey.key"
        }
    ]
}
EOF
systemctl stop ss
systemctl start ss

:'
cat > /etc/shadowsocks-rust/config.json <<-EOF
{
    "servers": [
        {
            "address": "127.0.0.1",
            "server_port":50003,
            "password": "barfoo!",
            "timeout":300,
            "method": "chacha20-ietf-poly1305",
            "fast_open":false,
            "mode":"tcp_only",
            "plugin":"v2ray-plugin",
            "plugin_opts":"server;mode=quic;host=s.flyrain.tk;cert=/root/cert/fullchain.cer;key=/root/cert/privkey.key"
        }
    ]
}
EOF
systemctl stop ss
systemctl start ss
'