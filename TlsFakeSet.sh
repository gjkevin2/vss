#!/bin/bash
apt update && apt -y upgrade && apt -y install socat
apt -y install curl gawk unzip
curl https://get.acme.sh | sh -s email=gjkevin@163.com
~/.acme.sh/acme.sh --upgrade --auto-upgrade
export DP_Id='192193'
export DP_Key='dc85648992cf2d738ee22815979e8a15'
# export CF_Key="b8a4d01054c1e780d4f8346a302c5ae0e988d" 
# export CF_Email="gjkevin2@163.com"
~/.acme.sh/acme.sh --register-account -m gjkevin2@163.com --server zerossl

echo '请输入顶级域名'
read domain
mkdir $HOME/cert

~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_dp
# ~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_cf

#installcert
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   $HOME/cert/privkey.key \
        --fullchain-file $HOME/cert/fullchain.cer


#install nginx and fake web
apt -y install curl gnupg2 ca-certificates lsb-release
echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
# curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
# apt-key fingerprint ABF5BD827BD9BF62
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
apt update
#systemctl unmask nginx.service
apt -y install nginx

# remove nginx
# apt -y remove nginx
# apt -y purge nginx
# # reinstrall nginx
# apt -y install nginx

# install Docker
# wget -qO- get.docker.com | bash
# # 查看 Docker 版本
# #docker version

# # set Docker start on boot
# systemctl start docker
# systemctl enable docker

# # pull mirror and set auto renew software
# docker pull nginx
# docker pull containrrr/watchtower

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
# docker run -p 80:80 -p 443:443 --name nginx --restart=always -v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf -v /etc/nginx/conf.d:/etc/nginx/conf.d -v /usr/share/nginx/html:/usr/share/nginx/html -v /var/log/nginx:/var/log/nginx -v /root/.acme.sh/$domain:/root/.acme.sh/$domain -d nginx