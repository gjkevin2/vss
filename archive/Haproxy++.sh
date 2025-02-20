#!/bin/bash
echo '请输入顶级域名'
read domain

# install HAProxy
curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor > /usr/share/keyrings/haproxy.debian.net.gpg
echo deb "[signed-by=/usr/share/keyrings/haproxy.debian.net.gpg]" http://haproxy.debian.net buster-backports-2.7 main > /etc/apt/sources.list.d/haproxy.list
apt update
apt -y install haproxy=2.7.\*

cat >/etc/haproxy/haproxy.cfg<<-EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    # chroot /var/lib/haproxy #注释掉，让下边进程路径为实际设置的。
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user root #默认以root用户运行。若修改，请修改为相应权限的用户。
    group root #默认以root组运行。若修改，请修改为相应权限的组。
    daemon

defaults
    log global
    mode    tcp
    option  tcplog
    option  dontlognull
        timeout connect 5s
        timeout client  300s
        timeout server  300s

frontend sni_proxy
    mode tcp
        bind *:443 #监听443端口
        tcp-request inspect-delay 5s
        tcp-request content accept if { req.ssl_hello_type 1 }

        acl acl_vless req_ssl_sni -i v.$domain #-i后面修改为自己规划对应vless+tcp+tls的域名
        acl acl_trojan req_ssl_sni -i t.$domain #-i后面修改为自己规划对应trojan+tcp+tls的域名
        acl acl_https req_ssl_sni -i www.$domain #-i后面修改为自己规划对应HTTPS server的域名

        use_backend vless if acl_vless
        use_backend trojan if acl_trojan
        use_backend https if acl_https

backend vless
        server vps_vless /dev/shm/vless.sock send-proxy-v2 #转给vless+tcp+tls监听进程，且启用第二版的PROXY protocol发送。

backend trojan
        server vps_trojan /dev/shm/trojan.sock send-proxy-v2 #转给trojan+tcp+tls监听进程，且启用第二版的PROXY protocol发送。

backend https
        server vps_web /dev/shm/https.sock send-proxy-v2 #转给HTTPS server监听进程，且启用第二版的PROXY protocol发送。
EOF
systemctl restart haproxy
systemctl

# install caddy
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt -y install caddy
# use plugin caddy
systemctl stop caddy
lurl='https://api.github.com/repos/lxhao61/integrated-examples/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"]' '{print $5}'`
wget https://github.com/lxhao61/integrated-examples/releases/download/${latest_version}/caddy-linux-amd64.tar.gz
tar xf caddy-linux-amd64.tar.gz -C /usr/bin && rm /usr/bin/sha256
rm -f caddy-linux-amd64.tar.gz

cat >/etc/caddy/caddy.json<<-EOF
{
  "admin": {
    "disabled": true
  },
  "logging": {
    "logs": {
      "default": {
        "writer": {
          "output": "file",
          "filename": "/var/log/caddy/error.log"
        },
        "level": "ERROR"
      }
    }
  },
  "storage": {
    "module": "file_system",
    "root": "/home/tls" //存放TLS证书的基本路径
  },
  "apps": {
    "http": {
      "servers": {
        "h1": {
          "listen": [":80"], //HTTP默认监听端口
          "routes": [{
            "handle": [{
              "handler": "static_response",
              "headers": {
                "Location": ["https://{http.request.host}{http.request.uri}"] //HTTP自动跳转HTTPS，让网站看起来更真实。
              },
              "status_code": 301
            }]
          }]
        },
        "h1h2c": {
          "listen": ["unix//dev/shm/h1h2c.sock"], //HTTP/1.1 server及H2C server监听进程
          "listener_wrappers": [{
            "wrapper": "proxy_protocol" //开启PROXY protocol接收
          }],
          "routes": [{
            "handle": [{
              "handler": "headers",
              "response": {
                "set": {
                  "Strict-Transport-Security": ["max-age=31536000; includeSubDomains; preload"] //启用HSTS
                }
              }
            },
            {
              "handler": "file_server",
              "root": "/usr/share/nginx/html" //修改为自己存放的WEB文件路径
            }]
          }],
          "protocols": ["h1","h2c"] //开启HTTP/1.1 server与H2C server支持
        },
        "https": {
          "listen": ["unix//dev/shm/https.sock"], //HTTPS server监听进程
          "listener_wrappers": [{
            "wrapper": "proxy_protocol" //开启PROXY protocol接收
          },
          {
            "wrapper": "tls" //HTTPS server开启PROXY protocol接收必须配置
          }],
          "routes": [{
            "match": [{
              "path": ["/SeuW56Es"] //与vless+h2c应用中path对应
            }],
            "handle": [{
              "handler": "reverse_proxy",
              "transport": {
                "protocol": "http",
                "versions": ["h2c","2"]
              },
              "upstreams": [{
                "dial": "unix//dev/shm/vh2c.sock" //转发给本机vless+h2c监听进程
              }]
            }]
          },
          {
            "match": [{
              "protocol": "grpc",
              "path": ["/SALdGZ9k/*"] //与shadowsocks+grpc应用中serviceName对应
            }],
            "handle": [{
              "handler": "reverse_proxy",
              "transport": {
                "protocol": "http",
                "versions": ["h2c","2"]
              },
              "upstreams": [{
                "dial": "127.0.0.1:2011" //转发给本机shadowsocks+grpc监听端口
              }],
              "flush_interval": -1,
              "headers": {
                "request": {
                  "set": {
                    "X-Real-Ip": ["{http.request.remote.host}"]
                  }
                }
              }
            }]
          },
          {
            "handle": [{
              "handler": "forward_proxy",
              "auth_user_deprecated": "user", //NaiveProxy用户，修改为自己的。
              "auth_pass_deprecated": "pass", //NaiveProxy密码，修改为自己的。
              "hide_ip": true,
              "hide_via": true,
              "probe_resistance": {}
            }]
          },
          {
            "handle": [{
              "handler": "headers",
              "response": {
                "set": {
                  "Strict-Transport-Security": ["max-age=31536000; includeSubDomains; preload"] //启用HSTS
                }
              }
            },
            {
              "handler": "file_server",
              "root": "/usr/share/nginx/html" //修改为自己存放的WEB文件路径
            }]
          }],
          "tls_connection_policies": [{
            "cipher_suites": ["TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256","TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384","TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"],
            "curves": ["x25519","secp521r1","secp384r1","secp256r1"]
          }],
          "protocols": ["h1","h2"] //开启HTTP/1.1 server与HTTP/2 server支持（HTTP/3 server不支持UDS监听）
        }
      }
    },
    "tls": {
      "certificates": {
        "automate": ["v.$domain","t.$domain","www.$domain"] //自动化管理TLS证书（包括获取、更新及加载证书）。修改为自己的域名。
      },
      "automation": {
        "policies": [{
          "issuers": [{
            "module": "acme" //acme表示从Let's Encrypt申请TLS证书，zerossl表示从ZeroSSL申请TLS证书。必须acme与zerossl二选一（固定TLS证书的目录便于引用）。
          }]
        }]
      }
    }
  }
}
//备注：
//1、申请免费TLS证书的域名不要超过五个，否则影响TLS证书的更新。
//2、从Let's Encrypt申请的普通TLS证书在‘/home/tls/certificates/acme-v02.api.letsencrypt.org-directory/zv.xx.yy’目录中。/home/tls为存放TLS证书的基本路径，zv.xx.yy为域名，目录根据域名变化。
//3、从ZeroSSL申请的普通TLS证书在‘/home/tls/certificates/acme.zerossl.com-v2-dv90/zv.xx.yy’目录中。/home/tls为存放TLS证书的基本路径，zv.xx.yy为域名，目录根据域名变化。 
//4、本配置仅支持申请普通TLS证书，若要申请通配符TLS证书请参考‘Caddy(Other Configuration) （Caddy的特殊应用配置方法。）’中对应介绍及对应配置示例。
EOF
systemctl stop caddy
systemctl start caddy
systemctl enable caddy


# install xray
#安装xray 和最新发行的 geoip.dat 和 geosite.dat,
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root

# 获取ip和域名
apt -y install gawk
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
testdomain=`sed -n "/preread_server/{n;p;}" /etc/nginx/nginx.conf |awk -F ' ' '{print $1}'`
servername=${testdomain#*.}

cat > /usr/local/etc/xray/config.json <<-EOF
{
  "log": {
    "loglevel": "warning",
    "error": "/var/log/xray/error.log", //若使用V2Ray，此处目录名称xray改成v2ray。
    "access": "/var/log/xray/access.log" //若使用V2Ray，此处目录名称xray改成v2ray。
  },
  "inbounds": [
    {
      "listen": "/dev/shm/vless.sock", //vless+tcp+tls监听进程
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "048e0bf2-dd56-11e9-aa37-5600024c1d6a", //修改为自己的UUID
            "email": "5443@gmail.com"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "path": "/HALdGZ9k", //通过路径分流
            "dest": "@vmess-ws", //分流后转给vmess+ws监听进程
            "xver": 2 //开启PROXY protocol发送，发送真实来源IP和端口给如下vmess+ws应用。1或2表示PROXY protocol版本。多级传递，建议配置2。
          },
          {
            "dest": "/dev/shm/h1h2c.sock", //h2与http/1.1回落进程（共用进程）
            "xver": 2 //开启PROXY protocol发送，发送真实来源IP和端口给Caddy。1或2表示PROXY protocol版本。与上一致，建议配置2。
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "ocspStapling": 3600, //Xray版本不小于v1.3.0才支持配置OCSP装订更新与证书热重载的时间间隔。目前V2Ray不支持，若使用V2Ray做服务端必须删除此项配置。
              "certificateFile": "/home/tls/certificates/acme-v02.api.letsencrypt.org-directory/zv.xx.yy/zv.xx.yy.crt", //换成自己的证书，绝对路径。
              "keyFile": "/home/tls/certificates/acme-v02.api.letsencrypt.org-directory/zv.xx.yy/zv.xx.yy.key" //换成自己的密钥，绝对路径。
            }
          ],
          "minVersion": "1.2", //Xray版本不小于v1.1.4才支持配置最小TLS版本。目前V2Ray不支持，若使用V2Ray做服务端必须删除此项配置。
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", //Xray版本不小于v1.1.4才支持配置密码套件。目前V2Ray不支持，若使用V2Ray做服务端必须删除此项配置。
          "alpn": [
            "h2", //启用h2连接需配置h2回落，否则不一致（裸奔）容易被墙探测出从而被封。
            "http/1.1" //启用http/1.1连接需配置http/1.1回落，否则不一致（裸奔）容易被墙探测出从而被封。
          ]
        },
        "tcpSettings": {
          "acceptProxyProtocol": true //开启PROXY protocol接收，接收Nginx或HAProxy SNI分流前真实来源IP和端口。
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "listen": "@vmess-ws", //vmess+ws监听进程
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "21376258-dd56-11e9-aa37-5600024c1d6a", //修改为自己的UUID
            "email": "2001@gmail.com"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true, //开启PROXY protocol接收，接收vless+tcp+tls分流前真实来源IP和端口。
          "path": "/HALdGZ9k" //修改为自己的path
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "listen": "/dev/shm/trojan.sock", //trojan+tcp+tls监听进程
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password":"diy6443", //修改为自己密码
            "email": "6443@gmail.com"
          }
        ],
        "fallbacks": [
          {
            "path": "/9ALdGZ9k", //通过路径分流
            "dest": "@trojan-ws", //分流后转给trojan+ws监听进程
            "xver": 2 //开启PROXY protocol发送，发送真实来源IP和端口给如下trojan+ws应用。1或2表示PROXY protocol版本。多级传递，建议配置2。
          },
          {
            "dest": "/dev/shm/h1h2c.sock", //h2与http/1.1回落进程（共用进程）
            "xver": 2 //开启PROXY protocol发送，发送真实来源IP和端口给Caddy。1或2表示PROXY protocol版本。与上一致，建议配置2。
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "ocspStapling": 3600, //Xray版本不小于v1.3.0才支持配置OCSP装订更新与证书热重载的时间间隔。目前V2Ray不支持，若使用V2Ray做服务端必须删除此项配置。
              "certificateFile": "/home/tls/certificates/acme-v02.api.letsencrypt.org-directory/zt.xx.yy/zt.xx.yy.crt", //换成自己的证书，绝对路径。
              "keyFile": "/home/tls/certificates/acme-v02.api.letsencrypt.org-directory/zt.xx.yy/zt.xx.yy.key" //换成自己的密钥，绝对路径。
            }
          ],
          "minVersion": "1.2", //Xray版本不小于v1.1.4才支持配置最小TLS版本。目前V2Ray不支持，若使用V2Ray做服务端必须删除此项配置。
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256", //Xray版本不小于v1.1.4才支持配置密码套件。目前V2Ray不支持，若使用V2Ray做服务端必须删除此项配置。
          "alpn": [
            "h2", //启用h2连接需配置h2回落，否则不一致（裸奔）容易被墙探测出从而被封。
            "http/1.1" //启用http/1.1连接需配置http/1.1回落，否则不一致（裸奔）容易被墙探测出从而被封。
          ]
        },
        "tcpSettings": {
          "acceptProxyProtocol": true //开启PROXY protocol接收，接收Nginx或HAProxy SNI分流前真实来源IP和端口。
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "listen": "@trojan-ws", //trojan+ws监听进程
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password":"diy2007", //修改为自己密码
            "email": "2007@gmail.com"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "acceptProxyProtocol": true, //开启PROXY protocol接收，接收trojan+tcp+tls分流前真实来源IP和端口。
          "path": "/9ALdGZ9k" //修改为自己的path
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "listen": "/dev/shm/vh2c.sock", //vless+h2c监听进程
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "048e0bf2-dd56-11e9-aa37-5600024c1d6a", //修改为自己的UUID
            "email": "2005@gmail.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "h2",
        "security": "none",
        "httpSettings": {
          "path": "/SeuW56Es" //修改为自己的path
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "listen": "127.0.0.1", //只监听本机，避免本机外的机器探测到下面端口。
      "port": 2011, //shadowsocks+grpc监听端口
      "protocol": "shadowsocks",
      "settings": {
        "method": "chacha20-poly1305",
        "password": "diy2011", //修改为自己的密码
        "email": "2011@gmail.com"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "SALdGZ9k" //修改为自己的gRPC服务名称，类似于HTTP/2中的Path。
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "port": 2052, //监听端口
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "0a652466-dd56-11e9-aa37-5600024c1d6a", //修改为自己的UUID
            "email": "2052@gmail.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "kcp",
        "security": "none",
        "kcpSettings": {
          "uplinkCapacity": 100,
          "downlinkCapacity": 100,
          "congestion": true, //启用拥塞控制
          "seed": "60VoqhfjP79nBQyU" //修改为自己的seed密码
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      }
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ]
}
EOF
systemctl stop xray
rm -rf /dev/shm/*
systemctl start xray
systemctl enable xray

#修改配置文件
cd ~
wget -O /usr/share/nginx/html/static/config.yaml https://raw.githubusercontent.com/gjkevin2/vss/master/config.yaml
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.yaml
sed -i 's/maindomain/'$servername'/g' /usr/share/nginx/html/static/config.yaml
wget -O /usr/share/nginx/html/static/config.json https://raw.githubusercontent.com/gjkevin2/vss/master/config.json
sed -i 's/serverip/'$serverip'/g' /usr/share/nginx/html/static/config.json
sed -i 's/servername/'$servername'/g' /usr/share/nginx/html/static/config.json
#生成ss，vmess订阅
bash create-ref.sh $serverip