#!/bin/bash
# cat里的内容根据he.net的ipv6通道里对应的系统输出内容
cat >/etc/network/interfaces.d/he-ipv6<<\EOF
auto he-ipv6
iface he-ipv6 inet6 v4tunnel
        address 2001:470:c:121c::2
        netmask 64
        endpoint 66.220.18.42
        local 154.9.238.181
        ttl 255
        gateway 2001:470:c:121c::1
EOF
echo 'source /etc/network/interfaces.d/*' >>/etc/network/interfaces
ifup he-ipv6

## 如果没有成功，需要安装 apt install -y net-tools iproute2
## 还没有生效，则重启网络试试 systemctl restart networking