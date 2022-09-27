#!/bin/bash
tpack=Vimix-1080p
wget https://gitee.com/gjkevin/dfiles/attach_files/614780/download/vimixmod.tar.xz 
#wget https://gitee.com/gjkevin/dfiles/attach_files/614595/download/unicode.pf2
tar xvJf vimixmod.tar.xz
sudo cp -r $tpack/Vimix /boot/grub/themes
rm -rf Vimix-1080p vimixmod.tar.xz
#disp=`xrandr |grep current|awk -F "," '{print $2}'|awk '{print $2$3$4}'`

#sudo sed -i "/grub_lang=/a\GRUB_THEME=\"\/boot\/grub\/themes\/Vimix\/theme.txt\"\\nGRUB_GFXMODE=\"$dispx32\"" /etc/grub.d/00_header
sudo sed -i "/grub_lang=/a\GRUB_THEME=\"\/boot\/grub\/themes\/Vimix\/theme.txt\"" /etc/grub.d/00_header
#sudo mv /usr/share/grub/unicode.pf2 /usr/share/grub/unicode.pf2.back
#sudo mv unicode.pf2 /usr/share/grub/ 
sudo grub-mkconfig -o /boot/grub/grub.cfg
