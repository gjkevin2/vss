#!/bin/bash
cd ~
rm -rf shadowsocks-v*
lurl='https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/v${latest_version}/shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz
tar xf shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz -C /usr/local/bin
rm -f shadowsocks-v${latest_version}.x86_64-unknown-linux-gnu.tar.xz

systemctl restart ss.service

