##########################################################################
# File Name: aria2ins.sh
# Author: kevin
# mail: gjkevin@163.com
# Created Time: 2022年07月14日 星期四 13时59分16秒
#########################################################################
#!/bin/zsh
sudo pacman -Sy --noconfirm aria2
# new a file :aria2.session
mkdir ~/.aria2
touch ~/.aria2/aria2.session

sudo tee /etc/systemd/system/aria2cd.service<<-EOF
[Unit]
Description=aria2 Daemon

[Service]
Type=simple
ExecStart=/usr/bin/aria2c --conf-path=$HOME/dfiles/archguide/aria2.conf

[Install]
WantedBy=default.target
EOF

sudo systemctl enable aria2cd
sudo systemctl start aria2cd
