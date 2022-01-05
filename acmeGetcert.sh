#!/bin/bash
apt update && apt -y upgrade && apt -y install socat
apt -y install curl gawk
curl https://get.acme.sh | sh -s email=gjkevin@163.com
~/.acme.sh/acme.sh --upgrade --auto-upgrade
export DP_Id='192193'
export DP_Key='dc85648992cf2d738ee22815979e8a15'

echo '请输入顶级域名'
read domain

~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_dp

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
uwsgi -ini /~/dist/uwsgi/uwsgi.ini
