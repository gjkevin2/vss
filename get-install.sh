#!/bin/bash

cd ~
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

function getall(){
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/ready_os.sh -O ready_os.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/TlsFakeSet.sh -O TlsFakeSet.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/nginxset.sh -O nginxset.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/bbr.sh -O bbr.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-xray.sh -O install-xray.sh    
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-ssrust.sh -O install-ssrust.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-singbox.sh -O install-singbox.sh
}

function get_cert_bbr(){
    bash ready_os.sh
    bash TlsFakeSet.sh
    bash nginxset.sh
    bash bbr.sh
}

function install_vless(){
    bash install-xray.sh
}

function install_ssrust(){
    bash install-ssrust.sh
}

start_menu(){
    clear
    red " ===================================="
    yellow " 1. 获取所有脚本"
    red " ===================================="
    yellow " 2. 获取泛域名证书及bbr加速"
    red " ===================================="
    yellow " 3. 安装vless"
    red " ===================================="
    yellow " 4. 加装trojan"
    red " ===================================="
    yellow " 5. 卸载trojan"
    red " ===================================="
    yellow " 6. 加装trojango"
    red " ===================================="
    yellow " 7. 卸载trojango"
    red " ===================================="
    yellow " 8. 安装ssrust"
    red " ===================================="
    yellow " 0. 退出脚本"
    red " ===================================="
    echo
    read -p "请输入数字:" num
    case "$num" in
    1)
    getall
    ;;
    2)
    get_cert_bbr
    ;;
    3)
    install_vless
    ;;
    4)
    install_trojan
    ;;
    5)
    remove_trojan
    ;;
    6)
    install_trojango
    ;;
    7)
    remove_trojango
    ;;
    8)
    install_ssrust
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
