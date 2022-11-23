#!/bin/bash
echo -e "\e[32mset an user account\e[0m"
read ura
echo -e "\e[32mset normal user password\e[0m"
read pswd

timedatectl set-ntp true
fdisk -l
echo -e "\e[31mplease select your partition to install linux\e[0m"
read lp
mkfs.ext4 $lp
mount $lp /mnt

# curl 'https://archlinux.org/mirrorlist/?country=CN' | sed -e 's/#Server/Server/' -e '/^#/d'>/etc/pacman.d/mirrorlist
# echo -e "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch">/etc/pacman.d/mirrorlist
#echo -e "Server = http://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch">/etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
#cat /mnt/etc/fstab

# set mirrorlist
# reflector --country China --age 24 --protocol https --sort rate --save /mnt/etc/pacman.d/mirrorlist

#add user:passwd to a file
echo "$ura">/mnt/newu
echo "$pswd">>/mnt/newu

# download all scripts
curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/chrootins.sh' >/mnt/chrootins.sh
curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/rootins.sh' >/mnt/rootins.sh
curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/aurdl.sh' >/mnt/aurdl.sh
curl 'https://ghproxy.com/https://raw.githubusercontent.com/gjkevin2/vss/master/archguide/uins.sh' >/mnt/uins.sh

chmod +x /mnt/chrootins.sh
arch-chroot /mnt /chrootins.sh

echo -e "\e[33mplease reject the boot medium when shutdown complete,then boot again,press Enter to shutdown\e[0m"
read p
shutdown -h now
