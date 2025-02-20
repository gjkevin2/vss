#!/bin/bash
# install
curl -s https://install.zerotier.com/ | bash
systemctl start zerotier-one.service
systemctl enable zerotier-one.service

# join network
zerotier-cli join ebe7fbd4456716e3

# create moon template
cd /var/lib/zerotier-one
zerotier-idtool initmoon identity.public > moon.json
server_ip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
#'[]' need \
sed -i 's/"stableEndpoints": \[\]/"stableEndpoints": \["'"$server_ip"'\/9993"\]/' moon.json

# create secret signfile
zerotier-idtool genmoon moon.json 

# create folder
mkdir moons.d 2>/dev/null
cp *.moon moons.d/

# reboot service
systemctl restart zerotier-one.service