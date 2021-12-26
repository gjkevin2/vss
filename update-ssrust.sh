#!/bin/bash
systemctl stop ss.service

cd ~
rm -rf shadowsocks-v* xray-plugin* v2ray-plugin*
lurl='https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${latest_version}/shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz
tar xf shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz -C /usr/local/bin
rm -f shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz

# v2ray-plugin
vurl='https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest'
latest_version2=`curl $vurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/v2ray-plugin/releases/download/v${latest_version2}/v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz
tar xf v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz -C /usr/local/bin
mv /usr/local/bin/v2ray-plugin_linux_amd64 /usr/local/bin/v2ray-plugin
rm -f v2ray-plugin-linux-amd64-v${latest_version2}.tar.gz

# xray-plugin
vurl='https://api.github.com/repos/teddysun/xray-plugin/releases/latest'
latest_version3=`curl $vurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/teddysun/xray-plugin/releases/download/v${latest_version3}/xray-plugin-linux-amd64-v${latest_version3}.tar.gz
tar xf xray-plugin-linux-amd64-v${latest_version3}.tar.gz -C /usr/local/bin
mv /usr/local/bin/xray-plugin_linux_amd64 /usr/local/bin/xray-plugin
rm -f xray-plugin-linux-amd64-v${latest_version3}.tar.gz

systemctl start ss.service