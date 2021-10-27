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
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/get-cert-web.sh -O get-cert-web.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-xray.sh -O install-xray.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-trojan-after.sh -O install-trojan-after.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-trojango-after.sh -O install-trojango-after.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/create-ref.sh -O create-ref.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/bbr.sh -O bbr.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-ssrust.sh -O install-ssrust.sh
}

function get_cert_bbr(){
    bash get-cert-web.sh
    bash bbr.sh
}

function install_vless(){
    bash install-xray.sh
}

function install_trojan(){
    bash install-trojan-after.sh
}

function install_trojango(){
    bash install-trojango-after.sh
}

function install_ssrust(){
    bash install-ssrust.sh
}

function remove_trojan(){
    red "================================"
    red "即将卸载trojan"
    red "================================"
    systemctl stop trojan
    systemctl disable trojan
    rm -f ${systempwd}trojan.service
    rm -rf /usr/src/trojan*
    bash install-xray.sh
    green "=============="
    green "trojan删除完毕"
    green "=============="
}

function remove_trojango(){
    red "================================"
    red "即将卸载trojango"
    red "================================"
    systemctl stop trojan-go
    systemctl disable trojan-go
    rm -f ${systempwd}trojan-go.service
    rm -rf /usr/local/bin/trojan-go
    bash install-xray.sh
    green "=============="
    green "trojango删除完毕"
    green "=============="
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
