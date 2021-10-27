#!/bin/bash
servername=$(ls /etc/nginx/conf.d |grep -v default|head -c -6)
systempwd="/usr/lib/systemd/system/"
apt -y install wget unzip zip curl tar >/dev/null 2>&1
if test -s $HOME/cert/fullchain.cer; then
    lurl='https://api.github.com/repos/p4gefau1t/trojan-go/releases/latest'
    latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
    wget https://github.com/p4gefau1t/trojan-go/releases/download/v${latest_version}/trojan-go-linux-amd64.zip
    unzip -o trojan-go-linux-amd64.zip -d /usr/local/bin/trojan-go
    rm trojan-go-linux-amd64.zip

    #创建配置文件
    trojan_passwd="461ece30"
    mkdir -p /usr/local/etc/trojan-go >/dev/null 2>&1
    cat >/usr/local/etc/trojan-go/config.json<<-EOF
{
    "run_type": "server",
    "local_addr": "127.0.0.1",
    "local_port": 50009,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojan_passwd"
    ],
    "ssl": {
        "cert": "$HOME/cert/fullchain.cer",
        "key": "$HOME/cert/privkey.key",
        "sni": "tg.$servername"
    },
    "router":{
        "enabled": true,
        "block": [
            "geoip:private"
        ]
    }
}
EOF

    #增加启动脚本    
    cat > ${systempwd}trojan-go.service <<-EOF

[Unit]
Description=Trojan-Go
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/trojan-go/trojan-go -config /usr/local/etc/trojan-go/config.json
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF
    chmod +x ${systempwd}trojan-go.service
    systemctl daemon-reload
    systemctl start trojan-go.service
    systemctl enable trojan-go.service
fi
