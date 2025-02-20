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

cd ~
lurl='https://api.github.com/repos/enfein/mieru/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"v]' '{print $6}'`

if check_sys packageManager yum; then
    wget https://github.com/enfein/mieru/releases/download/v${latest_version}/mita-${latest_version}-1.x86_64.rpm
    rpm -Uvh --force mita-${latest_version}-1.x86_64.rpm
elif check_sys packageManager apt; then
    wget https://github.com/enfein/mieru/releases/download/v${latest_version}/mita_${latest_version}_amd64.deb
    apt -y install ./mita_${latest_version}_amd64.deb
fi

mkdir /etc/mita >/dev/null 2>&1
cat >/etc/mita/mita.json<<-EOF
{
    "portBindings": [
        {
            "port": 2023,
            "protocol": "TCP"
        },
        {
            "port": 2203,
            "protocol": "UDP"
        }
    ],
    "users": [
        {
            "name": "wangys",
            "password": "461ece30"
        },
        {
            "name": "drive",
            "password": "461ece30"
        }
    ],
    "loggingLevel": "INFO",
    "mtu": 1400
}
EOF

mita apply config /etc/mita/mita.json

mita start

mita status