#!/bin/bash
# 启用缓存
grep "proxy_cache_path" /etc/nginx/nginx.conf || {
  sed -i "/http {/a\\\tproxy_cache_path /var/cache/nginx/github levels=1:2 keys_zone=github_cache:10m max_size=10g inactive=168h use_temp_path=off;" /etc/nginx/nginx.conf
}

cat >>/etc/nginx/conf.d/github-accelerator.conf<<\EOF
# 定义缓存路径和区域 (必须在http块内，通常放在nginx.conf的http块中)
# 注意：以下三行需要添加到 /etc/nginx/nginx.conf 的 http { ... } 块内，而不是这个server配置文件中。
# proxy_cache_path /var/cache/nginx/github levels=1:2 keys_zone=github_cache:10m max_size=10g inactive=168h use_temp_path=off;

server {
    listen 80;
    # 如果配置了SSL，也监听443
    # listen 443 ssl http2;
    server_name your-accelerator.com; # 替换为你的域名

    # SSL证书配置 (如果启用HTTPS)
    # ssl_certificate /path/to/your/fullchain.pem;
    # ssl_certificate_key /path/to/your/privkey.pem;

    # 根路径，提供一个简单的状态页面
    location / {
        add_header Content-Type text/plain;
        return 200 'GitHub Download Accelerator is Running!\n\nUsage:\n- Raw: https://your-accelerator.com/raw/:owner/:repo/:branch/:path\n- Release: https://your-accelerator.com/release/:owner/:repo/:tag/:filename\n';
    }

    # 核心配置1：加速 GitHub Raw 文件
    # 访问格式： https://your-domain.com/raw/:owner/:repo/:branch/:path
    location ~ ^/raw/(?<owner>[^/]+)/(?<repo>[^/]+)/(?<branch>[^/]+)/(?<path>.+)$ {
        # 拼接目标URL
        proxy_pass https://raw.githubusercontent.com/$owner/$repo/$branch/$path;

        # 修改请求头，确保GitHub能正确响应
        proxy_set_header Host raw.githubusercontent.com;
        proxy_set_header Referer $http_referer;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Accept-Encoding ""; # 清空，让Nginx处理压缩
        proxy_set_header User-Agent $http_user_agent; # 传递原始User-Agent

        # 缓存配置 (核心！)
        proxy_cache github_cache;
        proxy_cache_key $scheme$proxy_host$request_uri; # 缓存键
        proxy_cache_valid 200 206 304 7d; # 成功状态码缓存7天
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_ignore_headers Cache-Control Expires Set-Cookie; # 强制缓存，忽略源站no-cache头

        # 添加响应头，方便调试缓存状态
        add_header X-Cache-Status $upstream_cache_status;
        add_header X-Accel-By "GitHub-Accelerator";
        add_header Cache-Control "public, max-age=604800"; # 告诉客户端缓存7天

        # 代理设置
        proxy_buffering on;
        proxy_redirect off;
    }

    # 核心配置2：加速 GitHub Release 文件
    # 访问格式： https://your-domain.com/release/:owner/:repo/:tag/:filename
    location ~ ^/release/(?<owner>[^/]+)/(?<repo>[^/]+)/(?<tag>[^/]+)/(?<filename>.+)$ {
        # 拼接目标URL (注意Release文件的URL模式)
        proxy_pass https://github.com/$owner/$repo/releases/download/$tag/$filename;

        # 修改请求头
        proxy_set_header Host github.com;
        proxy_set_header Referer $http_referer;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Accept-Encoding "";
        proxy_set_header User-Agent $http_user_agent;

        # 缓存配置 (Release文件通常更大，缓存很重要)
        proxy_cache github_cache;
        proxy_cache_key $scheme$proxy_host$request_uri;
        proxy_cache_valid 200 206 304 30d; # Release文件缓存30天，通常不会变
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_ignore_headers Cache-Control Expires Set-Cookie;

        # 添加响应头
        add_header X-Cache-Status $upstream_cache_status;
        add_header X-Accel-By "GitHub-Accelerator";
        add_header Cache-Control "public, max-age=2592000"; # 告诉客户端缓存30天

        # 代理设置
        proxy_buffering on;
        proxy_redirect off;
        # 设置文件下载时的名字（可选）
        add_header Content-Disposition 'attachment; filename="$args"';
    }

    # 其他一些有用的重写规则（可选）
    # 1. 兼容 ghproxy.com 的路径风格 (如 /gh/...)
    location /gh/ {
        proxy_pass https://raw.githubusercontent.com/;
        proxy_set_header Host raw.githubusercontent.com;
        # ... (其他配置与上面的raw块类似，可以复制过去)
    }

    # 2. 加速仓库源码归档（zip/tar.gz）
    # location ~ ^/archive/(?<owner>[^/]+)/(?<repo>[^/]+)/(?<ref>.+)\.(zip|tar\.gz)$ {
    #     proxy_pass https://github.com/$owner/$repo/archive/$ref.$1;
    #     ... (配置缓存和头)
    # }
}
EOF

nginx -t
nginx -t
nginx -t | -s 