#!/bin/bash
 # wget –no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh 
 # wget –no-check-certificate -O shadowsocks-libev.sh  https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-libev.sh
 wget –no-check-certificate -O shadowsocks-libev.sh https://raw.githubusercontent.com/gjkevin2/vss/master/shadowsocks-libev.sh
 chmod +x shadowsocks-libev.sh 
 ./shadowsocks-libev.sh 2>&1 | tee shadowsocks-libev.log