#!/bin/bash
port=5060
echo "请输入网站域名"
read domain

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

# gcc、dev(el)是uwsgi需要
if check_sys packageManager yum; then
    yum install -y gcc python3`python3 --version | awk -F '[ .]' '{print $3}'`-devel
elif check_sys packageManager apt; then
    # python3-venv是venv需要,libpcre3-dev是uwsgi需要(若需要编译)
    apt install -y gcc python3-dev python3-venv libpcre3-dev
fi
rm -rf venv
python3 -m venv venv
source venv/bin/activate
# upgrade packages and install wheel
# must upgrade pip ,otherwise alert "bdist_wheel" error
python3 -m pip install --upgrade pip
pip3 install wheel flask requests
# pip3 install -r requirements.txt
# uwsgi 要加上–no-cache-dir,否则pip不会重新编译pcre进去
pip3 install uwsgi --no-cache-dir

rm -rf uwsgi
mkdir uwsgi
touch uwsgi/uwsgi.pid uwsgi/uwsgi.status
cat >uwsgi/uwsgi.ini<<-EOF
[uwsgi]
#端口号
socket=:${port}
#项目目录
chdir=$(pwd)
#虚拟环境的路径
virtualenv=%(chdir)/venv 
#项目启动文件
module=flaskr:app
#进程数量
processes=4
#线程数量
threads=2
#允许主进程
master=True
#传输大小
buffer-size=65536
#静态文件指定，nginx可以不用，在nginx里处理
#static-map=/static=$(pwd)/flaskr/static
#使程序后台运行
daemonize=%(chdir)/uwsgi/Server.log
#python文件更新及时生效
py-autoreload=1
#pid和status文件
stats=%(chdir)/uwsgi/uwsgi.status
pidfile=%(chdir)/uwsgi/uwsgi.pid
EOF
pkill -9 uwsgi
#run on boot in redhat
# echo '#!/bin/bash'>/etc/rc.d/init.d/uwsgiauto
# echo '#chkconfig: 2345 80 90'>>/etc/rc.d/init.d/uwsgiauto
# echo 'description: uwsgi auto start'>>/etc/rc.d/init.d/uwsgiauto
# echo "uwsgi --ini $(pwd)/uwsgi/uwsgi.ini">>/etc/rc.d/init.d/uwsgiauto
# chmod +x /etc/rc.d/init.d/uwsgiauto
# chkconfig --add uwsgiauto

# run on boot  (uwsgi要用绝对路径，因为虚拟环境下没有安装到PATH)
# 注意uwsgi以daemon模式运行的，有一个瞬间退出的中间父进程，所以需要使用forking类型
# forking类型要指定PIDFile，否则systemd会取猜，猜错了会出大问题
cat >/lib/systemd/system/uclient.service<<-EOF
[Unit]
Description=uwsgi project

[Service]
Type=forking
PIDFile=$(pwd)/uwsgi/uwsgi.pid
ExecStart=$(pwd)/venv/bin/uwsgi --ini $(pwd)/uwsgi/uwsgi.ini
ExecReload=$(pwd)/venv/bin/uwsgi --reload $(pwd)/uwsgi/uwsgi.pid
ExecStop=$(pwd)/venv/bin/uwsgi --stop $(pwd)/uwsgi/uwsgi.pid
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl stop uclient
systemctl enable uclient
systemctl start uclient


#nginx set
# 存在default时，使用sed添加一个路径
if [ -f /etc/nginx/conf.d/default.conf ]; then
    sed -i "/location \/ {/{N;N;N;s/$/\n\tlocation ~\* (table|ftest|output\/)$ {\n\t\tinclude uwsgi_params;\n\t\tuwsgi_pass 127.0.0.1:${port};\n\t}\n/}" /etc/nginx/conf.d/default.conf
    # sed -i "/uwsgi_pass/{N;N;s/$/\n\tlocation \/static {\n\t\talias $(pwd)\/flaskr\/static\/;\n\t}\n/}" /etc/nginx/conf.d/default.conf
    sed -i "/uwsgi_pass/{N;N;s/$/\n\tlocation \/static {\n\t\talias \/root\/formattable\/flaskr\/static\/;\n\t}\n/}" /etc/nginx/conf.d/default.conf
else
    #uwsgi的路由放到根目录，不用等号
    cat >>/etc/nginx/conf.d/default.conf<<-EOF
server {
        listen 80;
        server_name $domain;
        location / {
                include uwsgi_params;
                uwsgi_pass 127.0.0.1:${port};
        }
}
EOF
fi


# ~/.acme.sh/acme.sh --installcert -d $basedomain \
#         --key-file   $(pwd)/privkey.key \
#         --fullchain-file $(pwd)/fullchain.cer

# cat >>/etc/nginx/conf.d/default.conf<<-EOF
# server {
#         listen 80;
#         server_name $domain;
#         location =/weixin/ {                # for weixin url use port 80
#                 include uwsgi_params;
#                 uwsgi_pass 127.0.0.1:5050;
#         }
#         location / {
#             rewrite  ^(.*)$  https://\$server_name\$1 permanent;
#         }
# }

# server {
#         listen 443 ssl;
#         server_name $domain;
#         ssl_certificate  $(pwd)/fullchain.cer;
#         ssl_certificate_key $(pwd)/privkey.key;
#         ssl_session_timeout 5m;
#         ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
#         ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
#         ssl_prefer_server_ciphers on;
#         location / {
#                 include uwsgi_params;
#                 uwsgi_pass 127.0.0.1:5050;
#         }

#         location /static  {
#                alias $(pwd)/flaskr/static;
#         }
# }

# EOF
nginx -s reload
systemctl stop nginx
systemctl start nginx
