#!/bin/bash

#fonts color
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

systempwd="/usr/lib/systemd/system/"

function install_trojan(){
    systemctl stop nginx >/dev/null 2>&1
    yum -y install net-tools socat
    Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
    Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
    if [ -n "$Port80" ]; then
        process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
        red "==========================================================="
        red "检测到80端口被占用，占用进程为：${process80}，本次安装结束"
        red "==========================================================="
        exit 1
    fi
    if [ -n "$Port443" ]; then
        process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
        red "============================================================="
        red "检测到443端口被占用，占用进程为：${process443}，本次安装结束"
        red "============================================================="
        exit 1
    fi
    CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
    if [ "$CHECK" == "SELINUX=enforcing" ]; then
        red "======================================================================="
        red "检测到SELinux为开启状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启 ?请输入 [Y/n] :" yn
        [ -z "${yn}" ] && yn="y"
        if [[ $yn == [Yy] ]]; then
            sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
                setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi
    if [ "$CHECK" == "SELINUX=permissive" ]; then
        red "======================================================================="
        red "检测到SELinux为宽容状态，为防止申请证书失败，请先重启VPS后，再执行本脚本"
        red "======================================================================="
        read -p "是否现在重启 ?请输入 [Y/n] :" yn
        [ -z "${yn}" ] && yn="y"
        if [[ $yn == [Yy] ]]; then
            sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
                setenforce 0
            echo -e "VPS 重启中..."
            reboot
        fi
        exit
    fi
    systemctl stop firewalld >/dev/null 2>&1
    systemctl disable firewalld >/dev/null 2>&1

    # rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
    cat >/etc/yum.repos.d/nginx.repo<<-EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

    yum -y install  nginx wget unzip zip curl tar >/dev/null 2>&1
    systemctl enable nginx
    green "======================="
    yellow "请输入绑定到本VPS的域名"
    green "======================="
    # read your_domain
    your_domain="tj.flyrain.tk"
    real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    local_addr=`curl ipv4.icanhazip.com`
    if [ $real_addr == $local_addr ] ; then
        green "=========================================="
        green "       域名解析正常，开始安装trojan"
        green "=========================================="
        sleep 1s
        cat > /etc/nginx/conf.d/trojan.conf <<-EOF
server {
    listen       80;
    server_name  $your_domain;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    location /static {
        alias /usr/share/nginx/html/static;
    }
}
EOF
        #设置伪装站
        rm -rf /usr/share/nginx/html/*
        cd /usr/share/nginx/html/
        mkdir static >/dev/null 2>&1 #新建静态文件夹
        wget https://github.com/V2RaySSR/Trojan/raw/master/web.zip
        unzip web.zip
        systemctl restart nginx
        #申请https证书
        mkdir /usr/src/trojan-cert
        curl https://get.acme.sh | sh
        ~/.acme.sh/acme.sh  --issue  -d $your_domain  --webroot /usr/share/nginx/html/
        ~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/trojan-cert/private.key \
        --fullchain-file /usr/src/trojan-cert/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
        if test -s /usr/src/trojan-cert/fullchain.cer; then
            cd /usr/src
            wget https://api.github.com/repos/trojan-gfw/trojan/releases/latest
            latest_version=`grep tag_name latest| awk -F '[:,"v]' '{print $6}'`
            wget https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-linux-amd64.tar.xz
            tar xf trojan-${latest_version}-linux-amd64.tar.xz
            #下载trojan WIN客户端
            wget https://github.com/atrandys/trojan/raw/master/trojan-cli.zip
            wget -P /usr/src/trojan-temp https://github.com/trojan-gfw/trojan/releases/download/v${latest_version}/trojan-${latest_version}-win.zip
            unzip trojan-cli.zip
            unzip /usr/src/trojan-temp/trojan-${latest_version}-win.zip -d /usr/src/trojan-temp/
            cp /usr/src/trojan-cert/fullchain.cer /usr/src/trojan-cli/fullchain.cer
            mv -f /usr/src/trojan-temp/trojan/trojan.exe /usr/src/trojan-cli/ 
            # trojan_passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
            trojan_passwd="461ece30"
            cat > /usr/src/trojan-cli/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$your_domain",
    "remote_port": 443,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF
            rm -rf /usr/src/trojan/server.conf
            cat > /usr/src/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$trojan_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/src/trojan-cert/fullchain.cer",
        "key": "/usr/src/trojan-cert/private.key",
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
            #打包WIN客户端
            cd /usr/src/
            zip -q -r trojan-cli.zip ./trojan-cli
            mv trojan-cli.zip ./trojan-cli/
            trojan_path=$(cat /dev/urandom | head -1 | md5sum | head -c 16)
            mkdir /usr/share/nginx/html/${trojan_path}
            mv /usr/src/trojan-cli/trojan-cli.zip /usr/share/nginx/html/${trojan_path}/

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
            systemctl start trojan.service
            systemctl enable trojan.service

            green "======================================================================"
            green "Trojan已安装完成，请使用以下链接下载trojan客户端，此客户端已配置好所有参数"
            green "1、复制下面的链接，在浏览器打开，下载客户端"
            yellow "http://${your_domain}/$trojan_path/trojan-cli.zip"
            red "请记录下面规则网址"
            yellow "http://${your_domain}/trojan.txt"
            green "2、将下载的压缩包解压，打开文件夹，打开start.bat即打开并运行Trojan客户端"
            green "3、打开stop.bat即关闭Trojan客户端"
            green "4、Trojan客户端需要搭配浏览器插件使用，例如switchyomega等"
            green "访问  https://www.v2rayssr.com/trojan-1.html ‎ 下载 浏览器插件 及教程"
            green "======================================================================"
        else
            red "================================"
            red "https证书没有申请成功，本次安装失败"
            red "================================"
        fi    
    else
        red "================================"
        red "域名解析地址与本VPS IP地址不一致"
        red "本次安装失败，请确保域名解析正常"
        red "================================"
    fi
}

function remove_trojan(){
    red "================================"
    red "即将卸载trojan"
    red "同时卸载安装的nginx"
    red "================================"
    systemctl stop trojan
    systemctl disable trojan
    rm -f ${systempwd}trojan.service
    yum remove -y nginx
    rm -rf /usr/src/trojan*
    rm -rf /usr/share/nginx/html/*
    green "=============="
    green "trojan删除完毕"
    green "=============="
}

function bbr_boost_sh(){
    bash <(curl -L -s -k "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh")
}

start_menu(){
    clear
    green " ===================================="
    green " Trojan 一键安装自动脚本      "
    green " 系统：centos7+/debian9+/ubuntu16.04+"
    green " 此脚本为 atrandys 的，集成了BBRPLUS加速 "
    green " ===================================="
    echo
    red " ===================================="
    yellow " 1. 一键安装 Trojan"
    red " ===================================="
    yellow " 2. 安装 4 IN 1 BBRPLUS加速脚本"
    red " ===================================="
    yellow " 3. 一键卸载 Trojan"
    red " ===================================="
    yellow " 0. 退出脚本"
    red " ===================================="
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    install_trojan
    ;;
    2)
    bbr_boost_sh 
    ;;
    3)
    remove_trojan
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "请输入正确数字"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu