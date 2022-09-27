#!/bin/bash
#git config --local proxy.http "socks5://127.0.001:10808"
sudo pacman -S --noconfirm hunspell qt5-webkit qt5-multimedia qt5-tools libeb
cd /opt
sudo git clone https://ghproxy.com/https://github.com/goldendict/goldendict.git
cd goldendict
sudo qmake "CONFIG+=chinese_conversion_support" 
make clean && make
sudo make install
echo "please change the audio to external"
echo "settings--audio-- external audio,set to mpd"
