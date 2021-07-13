#!/bin/bash
systempwd="/usr/lib/systemd/system/"
apt -y install net-tools socat wget unzip zip curl tar >/dev/null 2>&1
if test -s $HOME/cert/fullchain.cer; then
    cd /usr/src
    wget https://api.github.com/repos/trojan-gfw/trojan/releases/latest
    latest_version=`grep tag_name latest| awk -F '[:,"v]' '{print $6}'`
    wget https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-linux-amd64.tar.xz
    tar xf trojan-${latest_version}-linux-amd64.tar.xz
    # trojan_passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
    trojan_passwd="461ece30"
    rm -rf /usr/src/trojan/server.conf
    cat > /usr/src/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "127.0.0.1",
    "local_port": 50002,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "$HOME/cert/fullchain.cer",
        "key": "$HOME/cert/privkey.key",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
    #增加启动脚本    
    cat > ${systempwd}trojan.service <<-EOF
[Unit]  
Description=trojan  
After=network.target  
   
[Service]  
Type=simple  
PIDFile=/usr/src/trojan/trojan/trojan.pid
ExecStart=/usr/src/trojan/trojan -c "/usr/src/trojan/server.conf"  
ExecReload=  
ExecStop=/usr/src/trojan/trojan  
PrivateTmp=true  
   
[Install]  
WantedBy=multi-user.target
EOF
    chmod +x ${systempwd}trojan.service
    systemctl daemon-reload
    systemctl start trojan.service
    systemctl enable trojan.service
fi
