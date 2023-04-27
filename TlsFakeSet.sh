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
--fullchain-file $HOME/cert/fullchain.cer
# --reloadcmd     "service nginx force-reload"


#install nginx and fake web
if check_sys packageManager yum; then
    rpm -ivh http://nginx.org/packages/centos/8/x86_64/RPMS/nginx-1.22.1-1.el8.ngx.x86_64.rpm
    # yum -y install nginx
elif check_sys packageManager apt; then
    apt -y install curl gnupg2 ca-certificates lsb-release
    echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
    # apt-key fingerprint ABF5BD827BD9BF62
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
    apt update
    #systemctl unmask nginx.service
    apt -y install nginx

    # remove nginx
    # apt -y autoremove --purge nginx
    # # reinstrall nginx
    # apt -y install nginx
fi

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

# sed -i 's#/var/run/nginx.pid#/run/nginx.pid#g' /etc/nginx/nginx.conf
sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
systemctl daemon-reload
systemctl enable nginx
systemctl stop nginx
systemctl start nginx
# docker run -p 80:80 -p 443:443 --name nginx --restart=always -v /etc/nginx/nginx.conf:/etc/nginx/nginx.conf -v /etc/nginx/conf.d:/etc/nginx/conf.d -v /usr/share/nginx/html:/usr/share/nginx/html -v /var/log/nginx:/var/log/nginx -v /root/.acme.sh/$domain:/root/.acme.sh/$domain -d nginx