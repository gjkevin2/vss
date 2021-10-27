#!/bin/bash
yum -y install epel-release
yum -y install snapd
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap
reboot