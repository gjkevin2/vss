#!/bin/bash
latest_version=`curl -s https://api.github.com/repos/subhra74/xdm/releases/latest|grep "tag_name"| awk -F '[:,"]' '{print $5}'`
echo -e "\e[33mdownload link by manual\e[0m:\nhttps://github.com/subhra74/xdm/releases/download/${latest_version}/xdm-setup-${latest_version}.tar.xz"
echo -e "\e[33mif speed is too slow, please use browser download,then run this script again\e[0m"
if [ ! -f ~/xdm-setup-${latest_version}.tar.xz ]; then
    #wget -P ~ https://download.fastgit.org/subhra74/xdm/releases/download/${latest_version}/xdm-setup-${latest_version}.tar.xz
    #wget -P ~ https://gh.api.99988866.xyz/https://github.com/subhra74/xdm/releases/download/${latest_version}/xdm-setup-${latest_version}.tar.xz
    wget -P ~ https://ghproxy.com/https://github.com/subhra74/xdm/releases/download/${latest_version}/xdm-setup-${latest_version}.tar.xz
fi
tar xvJf ~/xdm-setup-${latest_version}.tar.xz -C ~
rm -f ~/xdm-setup-${latest_version}.tar.xz ~/readme.txt
if [ -e ~/pwd ]; then
    echo $(cat ~/pwd)|sudo -S bash ~/install.sh
else
    sudo bash ~/install.sh
fi

echo -e "\e[33myou can use this command to uninstall:\n sudo rm -rf /opt/xdman /usr/bin/xdman\e[0m"