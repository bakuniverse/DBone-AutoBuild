#!/bin/bash

#进入工作目录
cd $HOME

# 移除对uhttpd的依赖
sed -i '/luci-light/d' feeds/luci/collections/luci/Makefile
echo 设置 Nginx 默认配置
nginx_config_path="feeds/packages/net/nginx-util/files/nginx.config"
echo 使用 cat 和 heredoc 覆盖写入 nginx.config 文件
cat > "$nginx_config_path" <<'EOF'
config main 'global'
        option uci_enable 'true'

config server '_lan'
        list listen '443 ssl default_server'
        list listen '[::]:443 ssl default_server'
        option server_name '_lan'
        list include 'restrict_locally'
        list include 'conf.d/*.locations'
        option uci_manage_ssl 'self-signed'
        option ssl_certificate '/etc/nginx/conf.d/_lan.crt'
        option ssl_certificate_key '/etc/nginx/conf.d/_lan.key'
        option ssl_session_cache 'shared:SSL:32k'
        option ssl_session_timeout '64m'
        option access_log 'off; # logd openwrt'

config server 'http_only'
        list listen '80'
        list listen '[::]:80'
        option server_name 'http_only'
        list include 'conf.d/*.locations'
        option access_log 'off; # logd openwrt'
EOF

echo 优化Nginx配置
nginx_template="feeds/packages/net/nginx-util/files/uci.conf.template"
if [ -f "$nginx_template" ]; then
  if ! grep -q "client_body_in_file_only clean;" "$nginx_template"; then
    sed -i "/client_max_body_size 128M;/a\\
        client_body_in_file_only clean;\\
        client_body_temp_path /mnt/tmp;" "$nginx_template"
  fi
fi

echo 对ubus接口安全和性能优化 
luci_support_script="feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support"
if [ -f "$luci_support_script" ]; then
  if ! grep -q "client_body_in_file_only off;" "$luci_support_script"; then
    sed -i '/ubus_parallel_req 2;/a\
        client_body_in_file_only off;\
        client_max_body_size 1M;' "$luci_support_script"

  fi
fi



