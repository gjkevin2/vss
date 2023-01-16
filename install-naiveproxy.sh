#!/bin/bash
# 获取ip和域名
serverip=$(ip addr|grep inet|grep -v 127.0.0.1|grep -v inet6|awk -F '/' '{print $1}'|tr -d "inet ")
testdomain=`sed -n "/preread_server/{n;p;}" /etc/nginx/nginx.conf |awk -F ' ' '{print $1}'`
servername=${testdomain#*.}

cd ~
# rm -rf shadowsocks-v* xray-plugin* v2ray-plugin*
lurl='https://api.github.com/repos/lxhao61/integrated-examples/releases/latest'
latest_version=`curl $lurl| grep tag_name |awk -F '[:,"]' '{print $5}'`
wget https://github.com/lxhao61/integrated-examples/releases/download/${latest_version}/caddy-linux-amd64.tar.gz
tar xf caddy-linux-amd64.tar.gz -C /usr/bin && rm /usr/bin/sha256
rm -f caddy-linux-amd64.tar.gz

mkdir /etc/caddy
cat >/etc/caddy/config.json<<-EOF
{
  "admin": {
    "disabled": true
  },
  "logging": {
    "sink": {
      "writer": {
        "output": "discard"
      }
    },
    "logs": {
      "default": {
        "writer": {
          "output": "discard"
        }
      }
    }
  },
  "apps": {
    "http": {
      "servers": {
        "srv0": {
          "listen": [
            ":4043"
          ],
          "routes": [
            {
              "handle": [
                {
                  "handler": "subroute",
                  "routes": [
                    {
                      "handle": [
                        {
                          "auth_pass_deprecated": "461ece30",
                          "auth_user_deprecated": "wpstest",
                          "handler": "forward_proxy",
                          "hide_ip": true,
                          "hide_via": true,
                          "probe_resistance": {}
                        }
                      ]
                    },
                    {
                      "match": [
                        {
                          "host": [
                            "n.$domain"
                          ]
                        }
                      ],
                      "handle": [
                        {
                          "handler": "file_server",
                          "root": "/usr/share/nginx/html",
                          "index_names": [
                            "index.html"
                          ]
                        }
                      ],
                      "terminal": true
                    }
                  ]
                }
              ]
            }
          ],
          "tls_connection_policies": [
            {
              "match": {
                "sni": [
                  "n.$domain"
                ]
              }
            }
          ],
          "automatic_https": {
            "disable": true
          }
        }
      }
    },
    "tls": {
      "certificates": {
        "load_files": [
          {
            "certificate": "/root/.acme.sh/$servername/fullchain.cer",
            "key": "/root/.acme.sh/$servername/$servername.key"
          }
        ]
      }
    }
  }
}
EOF

#server
cat > /lib/systemd/system/caddy.service <<-EOF
[Unit]
Description=Caddy Server
After=network.target
[Service]
Restart=on-abnormal
ExecStart=/usr/bin/caddy run --config /etc/caddy/config.json
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl stop caddy.service
systemctl start caddy.service
systemctl enable caddy.service