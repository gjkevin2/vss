#!/bin/bash
# 安装
wget https://gitee.com/gjkevin/dfiles/releases/download/v0.5/sing-box-linux-amd64.tar.gz
tar zxvf sing-box-linux-amd64.tar.gz
rm -rf sing-box-linux-amd64.tar.gz sing-box
mv sing-box-* sing-box
chmod +x sing-box/sing-box

# 配置
mkdir -p /usr/local/etc/sing-box
cat > /usr/local/etc/sing-box/config.json <<-EOF
{
  "log": {
    "level": "warning",
    "timestamp": true
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  },
  "dns": {
    "servers": [
      {
        "tag": "local",
        "type": "local"
      },
      {
        "tag": "google",
        "type": "https",
        "server": "dns.google",
        "domain_resolver": "local",
        "detour": "proxy"
      }
    ],
    "rules": [
      {
        "rule_set": "geosite-cn",
        "server": "local"
      },
      {
        "rule_set": "anti-ad",
        "action": "predefined",
        "rcode": "REFUSED"
      }
    ],
    "strategy": "ipv4_only",
    "final": "google"
  },
  "inbounds": [
    {
      "type": "http",
      "tag": "http-in",
      "listen": "127.0.0.1",
      "listen_port": 7890,
      "tcp_fast_open": true,
      "users": []
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "type": "vless",
      "server": "158742.xyz",
      "server_port": 443,
      "domain_resolver": "local",
      "uuid": "461edf16-8619-4f46-8e1e-e3994c8c00a2",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "www.microsoft.com",
        "alpn": [
          "h2"
        ],
        "insecure": false,
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "Y8cBV8RyH9hSkdy0ATDC9T4s0hzMq1rUXU_YmH6Fgj4",
          "short_id": "b2c86d5449d237fa"
        }
      },
      "packet_encoding": ""
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "default_domain_resolver": {
      "server": "google"
    },
    "auto_detect_interface": true,
    "rules": [
      {
        "action": "sniff"
      },
      {
        "protocol": "dns",
        "action": "hijack-dns"
      },
      {
        "rule_set": "anti-ad",
        "action": "reject"
      },
      {
        "domain_suffix": [
          "appcenter.ms",
          "firebase.io",
          "crashlytics.com"
        ],
        "action": "reject"
      },
      {
        "domain_suffix": [
          "google.com",
          "gstatic.com",
          "googleapis.com",
          "googlevideo.com"
        ],
        "outbound": "proxy"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geoip-cn",
          "geosite-cn"
        ],
        "outbound": "direct"
      },
      {
        "outbound": "proxy"
      }
    ],
    "rule_set": [
      {
        "tag": "anti-ad",
        "type": "remote",
        "format": "binary",
        "url": "https://anti-ad.net/anti-ad-sing-box.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geosite-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://cdn.jsdelivr.net/gh/lyc8503/sing-box-rules@rule-set-geosite/geosite-cn.srs",
        "download_detour": "direct"
      },
      {
        "tag": "geoip-cn",
        "type": "remote",
        "format": "binary",
        "url": "https://cdn.jsdelivr.net/gh/lyc8503/sing-box-rules@rule-set-geoip/geoip-cn.srs",
        "download_detour": "direct"
      }
    ]
  }
}
EOF

# 创建systemd服务
cat >/etc/systemd/system/sing-box.service<<-EOF
[Unit]
Description=Sing-box Proxy Service
Documentation=https://sing-box.sagernet.org/
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$HOME/sing-box/sing-box run -c /usr/local/etc/sing-box/config.json

# 重启策略：在异常退出时自动重启
Restart=on-failure
RestartSec=5s

# 优雅停止信号
KillMode=mixed
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable sing-box
systemctl start sing-box