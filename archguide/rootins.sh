#!/bin/bash
#drop command in /etc/profile and autologin
#sed -i "/rootins/d" /etc/profile
rm -f /root/.profile
rm -rf /etc/systemd/system/getty@tty1.service.d

#network
#nmtui
count=0
while [ $count -lt 10 ]
do
    ping -c 1 'www.baidu.com' 2>/dev/null|grep ttl && break
    sleep 2
    let count+=1
    echo "bad network $count"
done

#set local language
localectl set-locale LANG=zh_CN.UTF-8
#set time synchronizing
timedatectl set-ntp true

#creat user account
ura=$(cat /newu|head -n 1)
useradd -m -G wheel $ura
pswd=$(cat /newu|tail -n 1)
echo "$pswd">/home/$ura/pwd
/usr/bin/rm -f /newu
echo "$ura:$pswd" |chpasswd
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

cat >>/etc/pacman.conf<<-EOF
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF
sed -i "s/#\[multilib\]/\[multilib\]/" /etc/pacman.conf
sed -i "/^\[multilib\]/{N;s/#//}" /etc/pacman.conf
pacman -Sy
pacman -S --noconfirm archlinuxcn-keyring
pacman -S --noconfirm yay bash-completion

#aur speed up
bash /aurdl.sh

pacman -Sy
pacman -S --noconfirm gvim
ln -s /usr/bin/vim /usr/bin/vi

pacman -S --noconfirm xf86-video-vesa xorg

#headrs
pacman -S --noconfirm linux-headers

# evince can be replaced by okular;p7zip add pw support for file-roller; usbutils is usb tools
pacman -S --noconfirm pacman-contrib wget usbutils mlocate python-pip expect chromium git qalculate-gtk flameshot evince gimp file-roller p7zip mpv
updatedb
# no gui proxy
pacman -S --noconfirm xray
curl -o /etc/xray/client.json https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/clientlite.json
sed -i "s/xtls-rprx-direct/xtls-rprx-splice/" /etc/xray/client.json
systemctl enable xray
# install printer
# install complete,use localhost:631 to config
pacman -S --noconfirm cups cups-pdf
systemctl enable cups
# modify ssh long connnect 
sed -i -r "s/#\s*(Host\s+)/\1/g" /etc/ssh/ssh_config
echo "   ServerAliveCountMax 5"|tee -a  /etc/ssh/ssh_config
echo "   ServerAliveInterval 30"|tee -a  /etc/ssh/ssh_config
systemctl restart sshd

su $ura -s /bin/bash /uins.sh

reboot
