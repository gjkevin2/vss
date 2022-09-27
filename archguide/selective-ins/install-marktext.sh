#/bin/bash

filedown(){
    if [ ! -f ${1##*/} ];then
        /usr/bin/axel -n 12 -a $1
    fi
}

cd ~
lurl='https://api.github.com/repos/marktext/marktext/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
# echo ${latest_version}
filedown https://ghproxy.com/https://github.com/marktext/marktext/releases/download/v${latest_version}/marktext-x64.tar.gz
sudo tar zxf marktext-x64.tar.gz -C /opt
rm marktext-x64.tar.gz
sudo ln -s /opt/marktext-x64/marktext /usr/bin/marktext