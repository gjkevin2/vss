#!/bin/bash
apt update && apt -y upgrade && apt -y install socat
apt -y install curl gawk
curl https://get.acme.sh | sh -s email=gjkevin@163.com
~/.acme.sh/acme.sh --upgrade --auto-upgrade
export DP_Id='192193'
export DP_Key='dc85648992cf2d738ee22815979e8a15'

echo '请输入顶级域名'
read domain
mkdir $HOME/cert

~/.acme.sh/acme.sh --issue -d $domain -d *.$domain --dns dns_dp

#installcert
~/.acme.sh/acme.sh --installcert -d $domain \
        --key-file   $HOME/cert/privkey.key \
        --fullchain-file $HOME/cert/fullchain.cer

#install nginx and fake web
apt -y install curl gnupg2 ca-certificates lsb-release
echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
apt-key fingerprint ABF5BD827BD9BF62
apt update
#systemctl unmask nginx.service
apt -y install nginx

# set sni bypass
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
sed -i '/^stream {/,$d' /etc/nginx/nginx.conf
cat >>/etc/nginx/nginx.conf<<-EOF
stream {
        # SNI recognize
        map \$ssl_preread_server_name \$stream_map {
                x.$domain beforextls;
                tx.$domain beforetrojanxtls;
                g.$domain grpc;
                t.$domain beforetrojan;
                tg.$domain beforetrojango;
                s.$domain beforess;
                sx.$domain beforessx;
                www.$domain web;
        }
        upstream beforextls { # remove "Proxy protocol"
                server 127.0.0.1:50011;
        }
        upstream xtls {
                server 127.0.0.1:50001;
        }
        upstream beforetrojanxtls {
                server 127.0.0.1:50017;
        }
        upstream trojanxtls {
                server 127.0.0.1:1310;
        }
        upstream grpc {
                server 127.0.0.1:50018;
        }
        upstream beforetrojan {
                server 127.0.0.1:50012; 
        }
        upstream trojan {
                server 127.0.0.1:50002; 
        }
        upstream beforetrojango {
                server 127.0.0.1:50019; 
        }
        upstream trojango {
                server 127.0.0.1:50009; 
        }
        upstream beforess {
                server 127.0.0.1:50013;
        }
        upstream ss {
                server 127.0.0.1:50003;
        }
        upstream beforessx {
                server 127.0.0.1:50213;
        }
        upstream ssx {
                server 127.0.0.1:50203;
        }
        upstream web { # just local port 443
                server 127.0.0.1:443;
        }
        server {
                listen $serverip:443      reuseport;  # listen server port 443
                # listen [::]:443 reuseport;
                proxy_pass      \$stream_map;
                ssl_preread     on;
                proxy_protocol on;                    # start Proxy protocol
        }
        # remove proxy protocol
        server {
                listen 127.0.0.1:50011 proxy_protocol;
                proxy_pass xtls;   # redirect to xtls 
        }
        server {
                listen 127.0.0.1:50017 proxy_protocol;
                proxy_pass trojanxtls;   # redirect to trojanxtls 
        }
        server {
                listen 127.0.0.1:50012 proxy_protocol;
                proxy_pass trojan;   # redirect to trojan 
        }
        server {
                listen 127.0.0.1:50019 proxy_protocol;
                proxy_pass trojango;   # redirect to trojango
        }
        server {
                listen 127.0.0.1:50013 proxy_protocol;
                proxy_pass ss;   # redirect to ss 
        }
        server {
                listen 127.0.0.1:50213 proxy_protocol;
                proxy_pass ssx;   # redirect to ssx
        }
}
EOF

mkdir /usr/share/nginx/html/static >/dev/null 2>&1
cd /usr/share/nginx/html/
wget https://raw.githubusercontent.com/gjkevin2/vss/master/fakesite.zip >/dev/null 2>&1
unzip fakesite.zip >/dev/null 2>&1

cd /etc/nginx/conf.d
aconf=$(ls |grep -v default)
rm -rf $aconf
cat > $domain.conf <<-EOF
server {
        listen 80;
        server_name $domain;
        root /usr/share/nginx/html;
        location = /robots.txt {
        }
        location ^~ /subscribe/  {
                alias /usr/share/nginx/html/static/;
        }
}
server {
        listen 80;
        server_name x.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name tx.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name g.$domain;
        return 301 http://$domain;
}
server {
        listen 127.0.0.1:50018 ssl http2 proxy_protocol;
        set_real_ip_from 127.0.0.1;
        server_name g.$domain;

        ssl_certificate /root/cert/fullchain.cer; 
        ssl_certificate_key /root/cert/privkey.key;
        # ssl_protocols TLSv1.2 TLSv1.3;
        # ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305;
        # ssl_prefer_server_ciphers on;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always; #启用HSTS
        root /usr/share/nginx/html;

        location /test { #与vless+grpc应用中serviceName对应
            if (\$content_type !~ "application/grpc") {
                return 404;
            }
            client_max_body_size 0;
            client_body_timeout 1071906480m;
            grpc_read_timeout 1071906480m;
            grpc_pass grpc://127.0.0.1:50008; 
        }
}
server {
        listen 80;
        server_name t.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name tg.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name s.$domain;
        return 301 http://$domain;
}
server {
        listen 80;
        server_name sx.$domain;
        return 301 http://$domain;
}
EOF
# repair pid file
sed -i "/ExecStartPost/d" /lib/systemd/system/nginx.service
sed -i "/PIDFile/a\ExecStartPost=/bin/sleep 0.1" /lib/systemd/system/nginx.service
# (re)start nginx
systemctl enable nginx
systemctl stop nginx
systemctl start nginx
