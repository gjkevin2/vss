#!/bin/bash
check_sys(){
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [[ -f /etc/redhat-release ]]; then
        release='centos'
        systemPackage='yum'
    elif grep -Eqi 'debian|raspbian' /etc/issue; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /etc/issue; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /etc/issue; then
        release='centos'
        systemPackage='yum'
    elif grep -Eqi 'debian|raspbian' /proc/version; then
        release='debian'
        systemPackage='apt'
    elif grep -Eqi 'ubuntu' /proc/version; then
        release='ubuntu'
        systemPackage='apt'
    elif grep -Eqi 'centos|red hat|redhat' /proc/version; then
        release='centos'
        systemPackage='yum'
    fi

    if [[ "${checkType}" == 'sysRelease' ]]; then
        if [ "${value}" == "${release}" ]; then
            return 0
        else
            return 1
        fi
    elif [[ "${checkType}" == 'packageManager' ]]; then
        if [ "${value}" == "${systemPackage}" ]; then
            return 0
        else
            return 1
        fi
    fi
}

if check_sys packageManager yum; then
    # official site stop renew, use another to update
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
    yum -y update
    yum install -y vim socat curl gawk unzip
elif check_sys packageManager apt; then
    apt update && apt -y upgrade && apt -y install socat
    apt -y install curl gawk unzip
fi

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

~/.acme.sh/acme.sh --install-cert -d $domain \
--key-file       $HOME/cert/$domain.key  \
--fullchain-file $HOME/cert/fullchain.cer \
--reloadcmd     "service nginx force-reload"


# fakesite
mkdir /usr/share/nginx/html/static >/dev/null 2>&1
rm /usr/share/nginx/html/index.html
if [ ! -e /usr/share/nginx/html/fakesite.zip ];then
        cd /usr/share/nginx/html/
        wget https://raw.githubusercontent.com/gjkevin2/vss/master/fakesite.zip >/dev/null 2>&1
fi
unzip fakesite.zip >/dev/null 2>&1

systemctl stop nginx
systemctl start nginx