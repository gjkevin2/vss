#!/bin/bash

filedown(){
    if [ ! -f ${1##*/} ];then
        /usr/bin/axel -n 12 -a $1
    fi
}

cd ~
# install wps-office
yay -S --noconfirm wps-office ttf-wps-fonts

echo "start install chinese support"
# attach_files
# atta=`curl https://gitee.com/gjkevin/dfiles/releases/v0.4|awk -F 'attach_files' '{print $3}'|awk -F '"' '{print $1}'`
# atta_ver=`echo ${atta%.tar.xz*}|awk -F 'zh_cn_' '{print $2}'`
# attach_files='https://gitee.com/gjkevin/dfiles/attach_files'$atta
# github attafiles
atta=`curl https://api.github.com/repos/gjkevin2/vss/releases/latest|grep "name"|grep "zh_cn"|awk -F ':|"' '{print $5}'`
atta_ver=`echo ${atta%.tar.xz*}|awk -F 'zh_cn_' '{print $2}'`
attach_files='https://ghproxy.com/https://github.com/gjkevin2/vss/releases/download/archlinux-ins/'$atta
# echo $attach_files

# wps最新版本
ver=`curl https://linux.wps.cn |grep 'banner_txt'|awk -F '[><]' '{print $3}'`
mainver=${ver##*.}

if [ $atta_ver == $ver ];then
    filedown $attach_files
else 
    # wps下载地址
    filedown https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2019/${mainver}/wps-office_${ver}_amd64.deb

    ar -x wps-office_${ver}_amd64.deb
    rm -f control.tar.gz debian-binary wps-office_${ver}_amd64.deb

    # 解包
    tar Jxf data.tar.xz ./opt/kingsoft/wps-office/office6/mui/zh_CN
    # 将zh_CN文件夹打包，作为中文包
    cd opt/kingsoft/wps-office/office*/mui
    tar Jcf ~/zh_cn_${ver}.tar.xz ./zh_CN
    cd ~

    # 删除临时文件
    rm -rf opt data.tar.xz

    # 最后出来的zh_cn_${ver}.tar.xz就是最后的文件

    # alarm
    echo "please update the zh_CN pack in the gitee repo"
fi
# 使用该包
sudo tar Jxf zh_cn_*.tar.xz -C /usr/lib/office*/mui/

echo "install complete!"
