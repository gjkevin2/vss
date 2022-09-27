#!/bin/bash
sudo pacman -S --noconfirm iwd  # just wireless
sudo systemctl enable iwd
# start in-bound DHCP client
sudo tee /etc/iwd/main.conf<<-EOF
[General]
EnableNetworkConfiguration=true
EOF
sudo systemctl disable NetworkManager
sudo systemctl disable NetworkManager-dispatcher
# wired use systemd-networkd, create a bridge which also good to using mobile usb web 
sudo tee /etc/systemd/network/MyBridge.netdev<<-EOF
[NetDev]
Name=br0
Kind=bridge
EOF

sudo tee /etc/systemd/network/bind.network<<-EOF
[Match]
Name=en*

[Network]
Bridge=br0
EOF

sudo tee /etc/systemd/network/mybridge.network<<-EOF
[Match]
Name=br0

[Network]
DHCP=yes
EOF
sudo systemctl enable systemd-networkd
sudo systemctl enable systemd-resolved  # enable local DNS 


# modify polybar interface show
int=$(ip addr|grep "state UP"|awk -F ":" '{print $2}'|head -n1)
sed -r -i "s/(^interface\s+=)(.*)/\1$int/" ~/.config/polybar/config