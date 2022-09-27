#!/bin/bash
sudo pacman -S --noconfirm axel
sudo tee /var/local/aurconf >/dev/null<<-EOF
#! /bin/bash
# 该脚本用于处理yay安装软件时，由github下载缓慢甚至无法下载的问题
# 检测域名是不是github，如果是，则替换为镜像网站，依旧使用curl下载
# 如果不是github则采用axel代替curl进行15线程下载

domain=\$(echo \$2 | cut -f3 -d'/');
#others=\$(echo \$2 | cut -f4- -d'/');
case "\$domain" in 
    "github.com")
    #url="https://download.fastgit.org/"\$others;
    url="https://ghproxy.com/"\$2;
    echo "download from github mirror \$url";
    /usr/bin/curl -gqb "" -fLC - --retry 3 --retry-delay 3 -o \$1 \$url;
    ;;
    *)
    url=\$2;
    /usr/bin/axel -n 12 -a -o \$1 \$url;
    ;;
esac
EOF
sudo chmod +x /var/local/aurconf

sudo cp /etc/makepkg.conf /etc/makepkg.conf.bak
sudo sed -i "/ftp/{s/curl.*/axel -n 15 -a -o %o %u'/}" /etc/makepkg.conf
sudo sed -i "/http/{s/curl.*/axel -n 15 -a -o %o %u'/}" /etc/makepkg.conf
sudo sed -i "s/https.*/https::\/var\/local\/aurconf %o %u\'/" /etc/makepkg.conf