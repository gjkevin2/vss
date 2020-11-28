#!/bin/bash
# server='185.238.251.62'
server=$1
share=''
function v2share(){    
    temp=`echo -n $v2s|base64 --wrap=0`
    #repalce '-' and '_' with '+' and '/'
    temp=${temp//-/+}
    temp=${temp//_/\/}
    v2="${v2type}://${temp}#"$marks
    share=$share$(echo $v2|base64 --wrap=0)
    if [[ "$v2type" = "ss" ]]; then
        share=${share%??}"0K"
    fi
}

method='chacha20-ietf'
passwd='barfoo!'
port='10630'
marks='ray-ss'
v2type='ss'
v2s=$method:$passwd@$server:$port
v2share

method='chacha20-ietf-poly1305'
passwd='barfoo!'
port='8388'
marks='ss-libev'
v2type='ss'
v2s=$method:$passwd@$server:$port
v2share

port='23282'
uuid='74a2e3cf-2b2c-4afe-b4c9-fec7124bc941'
aid='0'
net='tcp'
marks=''
v2type='vmess'
#单引号里再用单引号引起来变量可以正常解析
v2s='{
  "v": "2",
  "ps": "'$v2type'",
  "add": "'$server'",
  "port": "'$port'",
  "id": "'$uuid'",
  "aid": "'$aid'",
  "net": "'$net'",
  "type": "none",
  "host": "",
  "path": "",
  "tls": ""
}'
v2share

cat >/usr/share/nginx/html/static/subs.md<<EOF
$share
EOF
