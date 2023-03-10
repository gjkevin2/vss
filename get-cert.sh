#!/bin/bash
curl https://get.acme.sh | sh -s email=gjkevin@163.com
~/.acme.sh/acme.sh --upgrade --auto-upgrade
mkdir $HOME/cert 2>/dev/nul
export DP_Id='192193'
export DP_Key='dc85648992cf2d738ee22815979e8a15'
# export CF_Key="b8a4d01054c1e780d4f8346a302c5ae0e988d" 
# export CF_Email="gjkevin2@163.com"
~/.acme.sh/acme.sh --register-account -m gjkevin2@163.com --server zerossl

echo '请输入顶级域名'
read domain
# mkdir $HOME/cert

~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_dp

~/.acme.sh/acme.sh --install-cert -d $domain \
--key-file       $HOME/cert/$domain.key  \
--fullchain-file $HOME/cert/fullchain.cer \
--reloadcmd     "service nginx force-reload"