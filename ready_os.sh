# check package management
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

# check server location
stat=0
res=$(timeout 0.3 ping -c 1 'www.google.com' 2>/dev/null|grep ttl)
if [[ $res != '' ]] ;then
    n=$(echo $res | awk -F' ' '{print $7}')
    if [[ ${n:4} > 150 ]];then
        stat=1
    fi
else
    stat=1
fi

# mod ssh colors
sed -i "s/# export LS/export LS/g" ~/.bashrc
sed -i "s/# alias ls/alias ls/g" ~/.bashrc
sed -i "s/# alias ll/alias ll/g" ~/.bashrc
sed -i "s/# alias l/alias l/g" ~/.bashrc
grep "^PS1" ~/.bashrc ||{
    cat >>~/.bashrc<<\EOF
PS1='\[\e[1;32m\][\u@\h \W]\$\[\e[0m\] '
EOF
}
source ~/.bashrc


# some necessary packages
if check_sys packageManager yum; then
    yum install -y epel-release curl wget make vim screen npm git
    # 更新的开发工具
    toolset='gcc-toolset-11'
    yum -y install $toolset
    # 永久更新
    mv /usr/bin/gcc /usr/bin/gcc-bak
    ln -s /opt/rh/$toolset/root/bin/gcc /usr/bin/gcc
    mv /usr/bin/g++ /usr/bin/g++-bak
    ln -s /opt/rh/$toolset/root/bin/g++ /usr/bin/g++
    mv /usr/bin/as /usr/bin/as-bak
    ln -s /opt/rh/$toolset/root/bin/as /usr/bin/as
elif check_sys packageManager apt; then
    # 此处为debian11
    # 若为国内服务器，修改镜像源
    originsource=mirrors.ustc.edu.cn       
    [[ $stat==1 ]] && sed -i "s@deb.debian.org@$originsource@g" /etc/apt/sources.list
    [[ $stat==1 ]] && sed -i "s@//.*.ubuntu.com@//$originsource@g" /etc/apt/sources.list
    # 更新
    apt -y update && apt -y upgrade
    # "build-essential",它包含了 GNU 编辑器集合，GNU 调试器，和其他编译软件所必需的开发库和工具。
    apt -y install curl wget make git screen build-essential vim npm python3-pip python3-venv
fi

# 安装并更新nodejs
if [[ $stat==1 ]];then
    npm config set registry https://registry.npmmirror.com
fi
npm install -g n
if [[ $stat==1 ]];then
    export N_NODE_MIRROR=https://npmmirror.com/mirrors/node
fi
n latest
# 关闭捐赠
npm config set fund false --location=global

# enable ssh login; virtualbox need port transfer in web settings in virtualbox
# this hash password is generate by "openssl passwd -6 'vsst0515'"
# delete user use "deluser xxx && rm -rf /home/xxx"
useradd -m -p '$6$LOOPt/fopyySGn2/$6vR4IyGbB82BaSNJcdu9r9dI08lx27XWW4b.38s6CTpyKqcTRkR7HKIh05JLsb3m332q6/lG/pbT1dlJu643T/' vpstest
sed -i "s/^#Port 22/Port 2323/g" /etc/ssh/sshd_config
# sed -i "s/^#PermitRootLogin.*$/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i "s/#PasswordAuthentication/PasswordAuthentication/g" /etc/ssh/sshd_config
systemctl restart sshd

# install nginx
if check_sys sysRelease centos; then
    yum install yum-utils
    cat >/etc/yum.repos.d/nginx.repo<<\EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
    yum -y install nginx
elif check_sys packageManager apt;then
    if check_sys sysRelease debian; then
        apt -y install debian-archive-keyring
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx" |tee /etc/apt/sources.list.d/nginx.list
    else
        apt -y install ubuntu-keyring
        echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" |tee /etc/apt/sources.list.d/nginx.list
    fi
    apt -y install curl gnupg2 ca-certificates lsb-release
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor |tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" |tee /etc/apt/preferences.d/99nginx
    apt update
    #systemctl unmask nginx.service
    apt -y install nginx

    # remove nginx
    # apt -y autoremove --purge nginx
    # # reinstrall nginx
    # apt -y install nginx
fi

sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
systemctl daemon-reload
systemctl enable nginx
systemctl restart nginx