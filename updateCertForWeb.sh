#!/bin/bash
# renew cert for website. cert is just auto renewal,just install to cert folder you used.
echo '请输入顶级域名'
read domain
~/.acme.sh/acme.sh --install-cert -d $domain \
--key-file       $HOME/cert/$domain.key  \
--fullchain-file $HOME/cert/fullchain.cer
--reloadcmd     "service nginx force-reload"