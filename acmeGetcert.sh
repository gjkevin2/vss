#!/bin/bash
apt update && apt -y upgrade && apt -y install socat
apt -y install curl gawk
curl https://get.acme.sh | sh -s email=gjkevin@163.com
~/.acme.sh/acme.sh --upgrade --auto-upgrade
export Namesilo_Key='f0a93865dc9fa62ec111'

echo '请输入顶级域名'
read domain

# namesilo 解析太慢，使用900，其他可以不用这个选项
~/.acme.sh/acme.sh --issue --dns dns_namesilo --dnssleep 900 -d $domain -d *.$domain 

#installcert
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   $HOME/cert/privkey.key \
        --fullchain-file $HOME/cert/fullchain.cer \
        --reloadcmd  "service nginx force-reload"

#for Rss
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   /usr/share/nginx/html/RSS/privkey.pem \
        --fullchain-file /usr/share/nginx/html/RSS/fullchain.pem \
        --reloadcmd  "service nginx force-reload"

# restart flask
source ~/dist/venv/bin/activate
# uwsgi -ini ~/dist/uwsgi/uwsgi.ini
pkill -9 uwsgi
systemctl stop uclient
systemctl start uclient
