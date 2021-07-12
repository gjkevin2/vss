#!/bin/bash
maindomain=flyrain.tk
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
cat >>/etc/nginx/nginx.conf<<-EOF
stream {
        # SNI识别，将一个个域名映射成一个配置名
        map \$ssl_preread_server_name \$stream_map {
                x.$maindomain beforextls;
                t.$maindomain beforetrojan;
                s.$maindomain beforess;
                www.$maindomain web;
        }
        # upstream,也就是流量上游的配置
        upstream beforextls { # 在流量到达XTLS之前，先用stream模块将Proxy protocol的外衣扒掉
                server 127.0.0.1:50011;
        }
        upstream xtls {
                server 127.0.0.1:50001;
        }
        upstream beforetrojan {
                server 127.0.0.1:50012; 
        }
        upstream trojan {
                server 127.0.0.1:50002; 
        }
        upstream beforess {
                server 127.0.0.1:50013;
        }
        upstream ss {
                server 127.0.0.1:50003;
        }
        upstream web { # web服务器只监听本地443端口
                server 127.0.0.1:443;
        }
        server {
                listen $serverip:443      reuseport;
                # listen [::]:443 reuseport;
                proxy_pass      \$stream_map;
                ssl_preread     on;
                proxy_protocol on; # 开启Proxy protocol
        }
        # 脱去proxy伪装
        server {
                listen 127.0.0.1:7999 proxy_protocol;# 开启Proxy protocol
                proxy_pass xtls; # 以真实的XTLS作为上游，这一层是与XTLS交互的“媒人”
  }
}
EOF
cat > /etc/nginx/conf.d/v2ray.conf <<-EOF
server {
    listen 80;
    server_name $maindomain;
    location / {
        proxy_ssl_server_name on;
        proxy_pass https://imeizi.me;
    }
}
server {
        return 301 https://x.$maindomain;
                listen 80;
                server_name x.$maindomain;
}
server {
        return 301 https://t.$maindomain;
                listen 80;
                server_name t.$maindomain;
}
server {
        return 301 https://s.$maindomain;
                listen 80;
                server_name s.$maindomain;
}
EOF
systemctl stop nginx
systemctl start nginx