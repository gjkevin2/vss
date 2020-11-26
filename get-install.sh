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
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/get-cert-web.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-v2ray.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/install-trojan-after.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/creat-ref.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/bbr.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/os8-install-snap.sh
    wget https://raw.githubusercontent.com/gjkevin2/vss/master/os8-install-sslibev.sh
}

function get_cert_bbr(){
    bash get-cert-web.sh
    bash bbr.sh
}

function install_vless(){
    bash install-v2ray.sh
}

function install_trojan(){
    bash install-trojan-after.sh
}

function install_snap(){
    bash os8-install-snap.sh
}

function install_sslibev(){
    bash os8-install-sslibev.sh
}

function remove_trojan(){
    red "================================"
    red "即将卸载trojan"
    red "================================"
    systemctl stop trojan
    systemctl disable trojan
    rm -f ${systempwd}trojan.service
    rm -rf /usr/src/trojan*
    bash install-v2ray.sh
    green "=============="
    green "trojan删除完毕"
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
    yellow " 6. 安装sslibev的工具-snap,装完重启"
    red " ===================================="
    yellow " 7. 安装sslibev"
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
    install_snap
    ;;
    7)
    install_sslibev
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
