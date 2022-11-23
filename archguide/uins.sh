#!/bin/bash
cd /opt
echo $(cat ~/pwd)|sudo -S wget https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/prompt_fish.sh
sudo tee -a /etc/bash.bashrc >/dev/null <<-EOF
source /opt/prompt_fish.sh
EOF
echo -e "source /opt/prompt_fish.sh">>~/.bashrc
source ~/.bashrc
#zsh
bash <(curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/zsh-conf.sh')

# install wifi driver
# yay -S --noconfirm rtl8821cu-dkms-git

#dwm
bash <(curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/bspwmins.sh')

# install and config fcitx5
yay -S --noconfirm fcitx5-rime fcitx5-gtk fcitx5-qt
cat >>~/.xprofile<<\EOF
export QT_IM_MODULE=fcitx
export GTK_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
EOF
yay -S --noconfirm rime-cloverpinyin
mkdir -p ~/.local/share/fcitx5/rime/
cat >~/.local/share/fcitx5/rime/default.custom.yaml<<-EOF
patch:
  "menu/page_size": 8 
  schema_list:
    - schema: clover
EOF
# close emoji and characterist input
cat >~/.local/share/fcitx5/rime/clover.custom.yaml<<-EOF
patch:
  switches:
    - name: zh_simp_s2t
      reset: 0
      states: [ 简, 繁 ]
    - name: emoji_suggestion
      reset: 0
      states: [ "�️️\uFE0E", "�️️\uFE0F" ]
    - name: symbol_support
      reset: 0
      states: [ "无符", "符" ]
    - name: ascii_punct
      reset: 0
      states: [ 。，, ．， ]
    - name: full_shape
      reset: 0
      states: [ 半, 全 ]
    - name: ascii_mode
      reset: 0
      states: [ 中, 英 ]
EOF

echo PATH=$PATH:~/.local/bin>>~/.profile
export PATH=$PATH:~/.local/bin
# set pip.conf
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
# install some packages
pip install wheel
# add tk for python,matplotlib
sudo pacman -S --noconfirm tk

#config mpv
curl --create-dirs -o ~/.config/mpv/input.conf https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/input.conf
curl --create-dirs -o ~/.config/mpv/mpv.conf https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/mpv.conf

#set systemctl for user
cat>~/.runonce.sh<<-EOF
systemctl enable mpd --user
systemctl start mpd --user
echo $(cat ~/pwd)|sudo -S systemctl enable cups
echo $(cat ~/pwd)|sudo -S systemctl start cups
echo $(cat ~/pwd)|sudo -S systemctl enable xray
echo $(cat ~/pwd)|sudo -S systemctl start xray
sed -i "/runonce/d" ~/.profile
rm \$0
EOF
echo "bash ~/.runonce.sh">>~/.profile

#vim-common
bash <(curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/selective-ins/vimcommon.sh')

#vim for c++
#bash <(curl 'https://gitee.com/gjkevin/dfiles/raw/master/archguide/selective-ins/vimforcpp.sh')

#vim for rust
# bash <(curl 'https://gitee.com/gjkevin/dfiles/raw/master/archguide/selective-ins/vimforrust.sh')

# xdman use script
# bash <(curl 'https://gitee.com/gjkevin/dfiles/raw/master/archguide/selective-ins/xdmins.sh')
# or just use yay
# yay -S --noconfirm xdman

# install sublime-text
bash <(curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/subl-ins.sh')

#install vscode
# yay -S --noconfirm visual-studio-code-bin

# add symbol font and emoji
# yay -S --noconfirm ttf-symbola
sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/819859/download/Symbola.ttf
sudo pacman -S --noconfirm noto-fonts-emoji

# chinese fonts
cfont=14_SourceHanSerifCN.zip
lurl='https://api.github.com/repos/adobe-fonts/source-han-serif/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"]' '{print $5}'`
otf=/usr/share/fonts/OTF
sudo wget -P $otf https://ghproxy.com/https://github.com/adobe-fonts/source-han-serif/releases/download/$latest_version/$cfont
sudo unzip $otf/$cfont -d $otf && sudo mv $otf/SubsetOTF/CN/*.* $otf && sudo rm -rf $otf/$cfont $otf/SubsetOTF $otf/LICENSE.txt
# sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/737598/download/YaHei_Consolas_Hybrid_1.12.ttf
# download full version from https://mirrors.tuna.tsinghua.edu.cn/github-release/be5invis/Sarasa-Gothic/LatestRelease/
# sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/815979/download/sarasa-fixed-sc-regular.ttf
# sudo wget -P /usr/share/fonts/OTF https://gitee.com/gjkevin/dfiles/attach_files/819850/download/SourceHanSerifSC-Medium.otf
# sudo wget -P /usr/share/fonts/OTF https://gitee.com/gjkevin/dfiles/attach_files/871904/download/SourceHanSerifSC-Bold.otf
# sudo wget -P /usr/share/fonts/OTF https://ghproxy.com/https://github.com/loseblue/yaheiInconsolata.ttf/blob/master/yaheiInconsolata.otf
# sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/737567/download/SourceHanSerifCN-Regular.ttf

# refresh matplotlib cache
# rm -rf ~/.cache/matplotlib

# mod polybar text
sed -r -i 's/(^font-0 = )(.*)/\1"Source Han Serif CN:style=Medium:pixelsize=12;1"/' ~/.config/polybar/config

#set alacritty
if [ -e ~/.config/alacritty.yml ];then
    # download url: https://github.com/googlefonts/Inconsolata/releases/tag/v3.000
    fc-list|grep "Inconsolata NF"||(
    # sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/attach_files/811409/download/Inconsolata-Regular.ttf
    sudo wget -P /usr/share/fonts/TTF https://gitee.com/gjkevin/dfiles/releases/download/v0.3/Inconsolata%20Regular%20Nerd%20Font%20Complete%20Windows%20Compatible.ttf
    sudo fc-cache -fv
    )
    #fc-list |grep "YaHei_Consolas_Hybrid" >/dev/null&&sed -i "s/\(family: \).*/\1YaHei Consolas Hybrid/" ~/.config/alacritty.yml
    sed -i "s/\(family: \).*/\1Inconsolata NF/" ~/.config/alacritty.yml
else
    sudo fc-cache -fv
fi

# dual system config, assert if file exist, otherwise scripts go wrong and exit
if [ -e /var/lib/os-prober/labels ];then
    sudo grep "Windows" /var/lib/os-prober/labels && echo $(cat ~/pwd)|sudo -S hwclock -w -l
fi

#cleanup
echo $(cat ~/pwd)|sudo -S /usr/bin/rm -f /*.sh
/usr/bin/rm -f ~/pwd
# mkdir ~/music ~/Desktop 2>/dev/null


#echo -e "\e[33myou can use 'xprop | grep WM_CLASS' to get the program window name.\e[0m"
#echo -e "\e[33mAfter entering the command line, click program window you want to get the class name in 2th space.\e[0m"
#echo -e "\e[33myou can use the name in 'bspc rule'.\e[0m"
#echo -e "\e[32mwhen you reboot you can use this to install \e[33moffice:\e[32m\n yay -S wps-office ttf-wps-fonts\e[0m"
#echo -e "use yay -S wps-office-mui-zh-cn to change language or download zh_cn packs from my gitee"
#echo -e "\e[32mplease notice the /etc/xray/client.json, check the inbound port\e[0m"


#echo -e "\n\e[31mdo you use dual system?[yN]\e[0m"
#read dual
#if [[ "$dual" == "y" || "$dual" == "Y" ]];then
    # real system,local time write to CMOS
#    echo $pws|sudo -S hwclock -w -l
#fi

exit
