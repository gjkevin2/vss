#!/bin/bash
yum -y update && yum -y install curl  && yum -y install socat
curl https://get.acme.sh | sh
export DP_Id='192193'
export DP_Key='dc85648992cf2d738ee22815979e8a15'

domain="flyrain.tk"
mkdir $HOME/cert

~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_dp

#installcert
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   $HOME/cert/privkey.key \
        --fullchain-file $HOME/cert/fullchain.cer