#!/bin/bash
dd if=/dev/zero of=/swapfile bs=2048 count=1048576 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo -e "/swapfile none swap defaults 0 0">>/etc/fstab
cat /etc/fstab
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# live system's sys time to hardware,default UTC
hwclock -w

pacman -Sy
pacman -S --noconfirm gvim
ln -s /usr/bin/vim /usr/bin/vi

sed -r -i "s/#(en_US.UTF-8 UTF-8)/\1/" /etc/locale.gen
sed -r -i "s/#(zh_CN.UTF-8 UTF-8)/\1/" /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

echo "Archlinux">/etc/hostname
cat >/etc/hosts<<-EOF
127.0.0.1   localhost
::1 localhost
127.0.1.1   Archlinux.localdomain   Archlinux
EOF

# set network
# pacman -S --noconfirm networkmanager
# systemctl enable NetworkManager
pacman -S --noconfirm iwd  # just wireless
systemctl enable iwd
mkdir /etc/iwd 2>/dev/null
# chain to /etc/resolv.conf
rm -rf /etc/resolv.conf
ln -sf /run/systemd/network/resolv.conf /etc/resolv.conf
cat >/etc/iwd/main.conf<<-EOF
[General]
EnableNetworkConfiguration=true

[Network]
EnableIPv6=true
EOF
# wired use systemd-networkd, create a bridge which also good to using mobile usb web 
cat >/etc/systemd/network/MyBridge.netdev<<-EOF
[NetDev]
Name=br0
Kind=bridge
EOF
cat >/etc/systemd/network/bind.network<<-EOF
[Match]
Name=en*

[Network]
Bridge=br0
EOF
cat >/etc/systemd/network/mybridge.network<<-EOF
[Match]
Name=br0

[Network]
DHCP=yes
EOF
systemctl enable systemd-networkd
systemctl enable systemd-resolved  # enable local DNS 


#set root passwd to root
echo "root:root" |chpasswd
#bootloder
pacman -S --noconfirm grub os-prober
cat /proc/cpuinfo|grep "Intel" >/dev/null 2>&1 && pacman -S --noconfirm intel-ucode ||pacman -S --noconfirm amd-ucode
# set for win
echo GRUB_DISABLE_OS_PROBER=false >> /etc/default/grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

#autologin use root
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat >/etc/systemd/system/getty@tty1.service.d/override.conf<<-EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin root --noclear %I \$TERM
EOF
#echo "bash /rootins.sh">>/etc/profile
echo "bash /rootins.sh">>/root/.profile
exit