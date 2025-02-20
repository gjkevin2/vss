#!/bin/bash
port=5070
echo "请输入网站域名"
read domain
chdir=~/gitproxy
venv=$HOME/formattable/venv

mkdir -p $chdir/app 2>/dev/nul
cd $chdir/app
wget -Omain.py https://raw.githubusercontent.com/hunshcn/gh-proxy/master/app/main.py

source ${venv}/bin/activate && cd ..
pip install requests

mkdir uwsgi
touch uwsgi/uwsgi.pid uwsgi/uwsgi.status
cat >uwsgi/uwsgi.ini<<-EOF
[uwsgi]
#端口号
socket=:${port}
#项目目录
chdir=${chdir}
#虚拟环境的路径
virtualenv=${venv} 
#项目启动文件
wsgi-file=app/main.py
callable=app
#进程数量
processes=4
#线程数量
threads=2
#允许主进程
master=True
#传输大小
buffer-size=65536
#使程序后台运行
daemonize=%(chdir)/uwsgi/Server.log
#python文件更新及时生效
py-autoreload=1
#pid和status文件
stats=%(chdir)/uwsgi/uwsgi.status
pidfile=%(chdir)/uwsgi/uwsgi.pid
EOF
pkill -9 uwsgi

cat >/lib/systemd/system/gh.service<<-EOF
[Unit]
Description=githubproxy project

[Service]
Type=forking
PIDFile=${chdir}/uwsgi/uwsgi.pid
ExecStart=${venv}/bin/uwsgi --ini ${chdir}/uwsgi/uwsgi.ini
ExecReload=${venv}/bin/uwsgi --reload ${chdir}/uwsgi/uwsgi.pid
ExecStop=${venv}/bin/uwsgi --stop ${chdir}/uwsgi/uwsgi.pid
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl stop gh
systemctl enable gh
systemctl start gh


#nginx set
# 存在default时，使用sed添加一个路径,处理一些路径及对应静态资源
if [ -f /etc/nginx/conf.d/default.conf ]; then
    sed -i "/location \/ {/{N;N;N;N;s/$/\n\tlocation \/gh\/ {\n\t\tinclude uwsgi_params;\n\t\tuwsgi_pass 127.0.0.1:${port};\n\t}\n/}" /etc/nginx/conf.d/default.conf
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

nginx -s reload
systemctl stop nginx
systemctl start nginx
