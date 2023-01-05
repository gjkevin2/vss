#!/bin/bash
apt update && apt -y upgrade && apt -y install socat
apt -y install curl gawk
curl https://get.acme.sh | sh -s email=gjkevin@163.com
~/.acme.sh/acme.sh --upgrade --auto-upgrade
#export DP_Id='192193'
#export DP_Key='dc85648992cf2d738ee22815979e8a15'
export CF_Key="b8a4d01054c1e780d4f8346a302c5ae0e988d" 
export CF_Email="gjkevin2@163.com"

echo '请输入顶级域名'
read domain
mkdir $HOME/cert

# ~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_dp
~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_cf

#installcert
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   $HOME/cert/privkey.key \
        --fullchain-file $HOME/cert/fullchain.cer


#install nginx and fake web
apt -y install curl gnupg2 ca-certificates lsb-release
echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
apt-key fingerprint ABF5BD827BD9BF62
apt update
#systemctl unmask nginx.service
apt -y install nginx

# fakesite
mkdir /usr/share/nginx/html/static >/dev/null 2>&1
rm /usr/share/nginx/html/index.html
if [ ! -e /usr/share/nginx/html/fakesite.zip ];then
        cd /usr/share/nginx/html/
        wget https://raw.githubusercontent.com/gjkevin2/vss/master/fakesite.zip >/dev/null 2>&1
fi
unzip fakesite.zip >/dev/null 2>&1

systemctl enable nginx
systemctl stop nginx
systemctl start nginx