#!/bin/bash
yum -y update && yum -y install curl  && yum -y install socat
curl https://get.acme.sh | sh
export DP_Id='192193'
export DP_Key='dc85648992cf2d738ee22815979e8a15'

echo '请输入顶级域名'
read domain
mkdir $HOME/cert

~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_dp

#installcert
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   $HOME/cert/privkey.key \
        --fullchain-file $HOME/cert/fullchain.cer

#install nginx and fake web
cat >/etc/yum.repos.d/nginx.repo<<-EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
yum -y install  nginx

mkdir /usr/share/nginx/html/static >/dev/null 2>&1
cd /etc/nginx/conf.d
aconf=$(ls |grep -v default)
rm -rf $aconf
cat > $domain.conf <<-EOF
server {
    listen 80;
    server_name $domain;
    root /usr/share/nginx/html;
    location / {
        proxy_ssl_server_name on;
        proxy_pass https://imeizi.me;
    }
    location = /robots.txt {
    }
    location ^~ /subscribe/  {
        alias /usr/share/nginx/html/static/;
    }
}
EOF
systemctl enable nginx
systemctl stop nginx
systemctl start nginx
