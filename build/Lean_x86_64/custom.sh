
#!/bin/bash

# 安装额外依赖软件包
# sudo -E apt-get -y install rename

# 更新feeds文件
# sed -i 's@#src-git helloworld@src-git helloworld@g' feeds.conf.default # 启用helloworld
# sed -i 's@src-git luci@# src-git luci@g' feeds.conf.default # 禁用18.06Luci
# sed -i 's@## src-git luci@src-git luci@g' feeds.conf.default # 启用23.05Luci
cat feeds.conf.default

# 更新源
# ./scripts/feeds clean
./scripts/feeds update

# 添加第三方软件包
git clone https://github.com/db-one/dbone-packages.git -b 23.05 package/dbone-packages

# 删除部分默认包
rm -rf feeds/luci/applications/luci-app-qbittorrent
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/themes/luci-theme-argon

# 安装源
./scripts/feeds install -a -f

# 自定义定制选项
NET="package/base-files/luci2/bin/config_generate"
ZZZ="package/lean/default-settings/files/zzz-default-settings"
# 读取内核版本
KERNEL_PATCHVER=$(cat target/linux/x86/Makefile|grep KERNEL_PATCHVER | sed 's/^.\{17\}//g')
KERNEL_TESTING_PATCHVER=$(cat target/linux/x86/Makefile|grep KERNEL_TESTING_PATCHVER | sed 's/^.\{25\}//g')
if [[ $KERNEL_TESTING_PATCHVER > $KERNEL_PATCHVER ]]; then
  sed -i "s/$KERNEL_PATCHVER/$KERNEL_TESTING_PATCHVER/g" target/linux/x86/Makefile        # 修改内核版本为最新
  echo "内核版本已更新为 $KERNEL_TESTING_PATCHVER"
else
  echo "内核版本不需要更新"
fi

#
sed -i 's/192.168.1.1/192.168.100.252/g' package/base-files/luci/bin/config_generate
sed -i 's/192.168.1.1/192.168.100.252/g' package/base-files/files/bin/config_generate
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' package/lean/default-settings/files/zzz-default-settings
sed -i 's/256/1024/g' target/linux/x86/image/Makefile
sed -i 's#192.168.1.1#192.168.100.252#g' $NET                                                    # 定制默认IP
# sed -i 's#LEDE#OpenWr-X86#g' $NET                                                     # 修改默认名称为OpenWrt-X86
sed -i 's@.*CYXluq4wUazHjmCDBCqXF*@#&@g' $ZZZ                                             # 取消系统默认密码
sed -i "s/LEDE /ONE build $(TZ=UTC-8 date "+%Y.%m.%d") @ LEDE /g" $ZZZ              # 增加自己个性名称
echo "uci set luci.main.mediaurlbase=/luci-static/argon" >> $ZZZ                      # 设置默认主题(如果编译可会自动修改默认主题的，有可能会失效)

# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #

sed -i 's#localtime  = os.date()#localtime  = os.date("%Y年%m月%d日") .. " " .. translate(os.date("%A")) .. " " .. os.date("%X")#g' package/lean/autocore/files/*/index.htm               # 修改默认时间格式
sed -i 's#%D %V, %C#%D %V, %C Lean_x86_64#g' package/base-files/files/etc/banner               # 自定义banner显示
# sed -i 's@list listen_https@# list listen_https@g' package/network/services/uhttpd/files/uhttpd.config               # 停止监听443端口
# sed -i 's#option commit_interval 24h#option commit_interval 10m#g' feeds/packages/net/nlbwmon/files/nlbwmon.config               # 修改流量统计写入为10分钟
# sed -i 's#option database_generations 10#option database_generations 3#g' feeds/packages/net/nlbwmon/files/nlbwmon.config               # 修改流量统计数据周期
# sed -i 's#option database_directory /var/lib/nlbwmon#option database_directory /etc/config/nlbwmon_data#g' feeds/packages/net/nlbwmon/files/nlbwmon.config               # 修改流量统计数据存放默认位置
# sed -i 's#interval: 5#interval: 1#g' feeds/luci/applications/luci-app-wrtbwmon/htdocs/luci-static/wrtbwmon/wrtbwmon.js               # wrtbwmon默认刷新时间更改为1秒
sed -i '/exit 0/i\ethtool -s eth0 speed 10000 duplex full' package/base-files/files//etc/rc.local               # 强制显示2500M和全双工（默认PVE下VirtIO不识别）

# ●●●●●●●●●●●●●●●●●●●●●●●●定制部分●●●●●●●●●●●●●●●●●●●●●●●● #
# 移除 openwrt feeds 自带的核心库
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf package/passwall-packages
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages

# 移除 openwrt feeds 过时的luci版本
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf package/passwall-luci
rm -rf package/passwall-luci2
git clone https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci
git clone https://github.com/Openwrt-Passwall/openwrt-passwall2 package/passwall-luci2
sed -i 's/local RUN_NEW_DNSMASQ=1/local RUN_NEW_DNSMASQ=0/g' package/passwall-luci/luci-app-passwall/root/usr/share/passwall/app.sh
sed -i 's/local RUN_NEW_DNSMASQ=1/local RUN_NEW_DNSMASQ=0/g' package/passwall-luci2/luci-app-passwall2/root/usr/share/passwall2/app.sh

# ========================性能跑分========================
echo "rm -f /etc/uci-defaults/xxx-coremark" >> "$ZZZ"
cat >> $ZZZ <<EOF
cat /dev/null > /etc/bench.log
echo " (CpuMark : 191219.823122" >> /etc/bench.log
echo " Scores)" >> /etc/bench.log
EOF

# ================ 网络设置 =======================================

cat >> $ZZZ <<-EOF
# 设置网络-旁路由模式
uci set network.lan.gateway='192.168.100.253'                     # 旁路由设置 IPv4 网关
uci set network.lan.dns='223.5.5.5 119.29.29.29'            # 旁路由设置 DNS(多个DNS要用空格分开)
uci set dhcp.lan.ignore='1'                                  # 旁路由关闭DHCP功能
uci delete network.lan.type                                  # 旁路由桥接模式-禁用
uci set network.lan.delegate='0'                             # 去掉LAN口使用内置的 IPv6 管理(若用IPV6请把'0'改'1')
uci set dhcp.@dnsmasq[0].filter_aaaa='0'                     # 禁止解析 IPv6 DNS记录(若用IPV6请把'1'改'0')

# 设置防火墙-旁路由模式
uci set firewall.@defaults[0].syn_flood='0'                  # 禁用 SYN-flood 防御
uci set firewall.@defaults[0].flow_offloading='0'           # 禁用基于软件的NAT分载
uci set firewall.@defaults[0].flow_offloading_hw='0'       # 禁用基于硬件的NAT分载
uci set firewall.@defaults[0].fullcone='0'                   # 禁用 FullCone NAT
uci set firewall.@defaults[0].fullcone6='0'                  # 禁用 FullCone NAT6
uci set firewall.@zone[0].masq='1'                             # 启用LAN口 IP 动态伪装

# 旁路IPV6需要全部禁用
uci del network.lan.ip6assign                                 # IPV6分配长度-禁用
uci del dhcp.lan.ra                                             # 路由通告服务-禁用
uci del dhcp.lan.dhcpv6                                        # DHCPv6 服务-禁用
uci del dhcp.lan.ra_management                               # DHCPv6 模式-禁用

# 如果有用IPV6的话,可以使用以下命令创建IPV6客户端(LAN口)（去掉全部代码uci前面#号生效）
uci set network.ipv6=interface
uci set network.ipv6.proto='dhcpv6'
uci set network.ipv6.ifname='@lan'
uci set network.ipv6.reqaddress='try'
uci set network.ipv6.reqprefix='auto'
uci set firewall.@zone[0].network='lan ipv6'

uci commit dhcp
uci commit network
uci commit firewall

EOF

# 修改退出命令到最后
cd $HOME && sed -i '/exit 0/d' $ZZZ && echo "exit 0" >> $ZZZ

# ================ 网络设置 =======================================


# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #


# 创建自定义配置文件

cd $WORKPATH
touch ./.config

#
# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分●●●●●●●●●●●●●●●●●●●●●●●●
# 

# 
# 如果不对本区块做出任何编辑, 则生成默认配置固件. 
# 

# 以下为定制化固件选项和说明:
#

#
# 有些插件/选项是默认开启的, 如果想要关闭, 请参照以下示例进行编写:
# 
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#        ■|  # 取消编译VMware镜像:                    |■
#        ■|  cat >> .config <<EOF                   |■
#        ■|  # CONFIG_VMDK_IMAGES is not set        |■
#        ■|  EOF                                    |■
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#

# 
# 以下是一些提前准备好的一些插件选项.
# 直接取消注释相应代码块即可应用. 不要取消注释代码块上的汉字说明.
# 如果不需要代码块里的某一项配置, 只需要删除相应行.
#
# 如果需要其他插件, 请按照示例自行添加.
# 注意, 只需添加依赖链顶端的包. 如果你需要插件 A, 同时 A 依赖 B, 即只需要添加 A.
# 
# 无论你想要对固件进行怎样的定制, 都需要且只需要修改 EOF 回环内的内容.
# 


# 设置固件大小:
cat >> .config <<EOF
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y
# CONFIG_PACKAGE_automount is not set
# CONFIG_PACKAGE_autosamba is not set
CONFIG_PACKAGE_chinadns-ng=y
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-base64=y
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_dns2socks=y
CONFIG_PACKAGE_dnsmasq_full_nftset=y
# CONFIG_PACKAGE_etherwake is not set
# CONFIG_PACKAGE_firewall is not set
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_geoview=y
CONFIG_PACKAGE_haproxy=y
CONFIG_PACKAGE_ipt2socks=y
# CONFIG_PACKAGE_iptables-mod-conntrack-extra is not set
# CONFIG_PACKAGE_iptables-mod-fullconenat is not set
CONFIG_PACKAGE_jansson=y
# CONFIG_PACKAGE_kmod-crypto-ccm is not set
# CONFIG_PACKAGE_kmod-crypto-cmac is not set
# CONFIG_PACKAGE_kmod-crypto-des is not set
# CONFIG_PACKAGE_kmod-crypto-md4 is not set
# CONFIG_PACKAGE_kmod-crypto-md5 is not set
# CONFIG_PACKAGE_kmod-crypto-sha256 is not set
# CONFIG_PACKAGE_kmod-fs-exfat is not set
# CONFIG_PACKAGE_kmod-fs-ext4 is not set
# CONFIG_PACKAGE_kmod-fs-ksmbd is not set
# CONFIG_PACKAGE_kmod-fs-ntfs3 is not set
CONFIG_PACKAGE_kmod-inet-diag=y
# CONFIG_PACKAGE_kmod-ipt-conntrack-extra is not set
# CONFIG_PACKAGE_kmod-ipt-fullconenat is not set
# CONFIG_PACKAGE_kmod-lib-crc16 is not set
CONFIG_PACKAGE_kmod-netlink-diag=y
CONFIG_PACKAGE_kmod-nf-socket=y
CONFIG_PACKAGE_kmod-nft-core=y
CONFIG_PACKAGE_kmod-nft-fib=y
CONFIG_PACKAGE_kmod-nft-fullcone=y
CONFIG_PACKAGE_kmod-nft-nat=y
CONFIG_PACKAGE_kmod-nft-offload=y
CONFIG_PACKAGE_kmod-nft-socket=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
# CONFIG_PACKAGE_kmod-oid-registry is not set
# CONFIG_PACKAGE_kmod-scsi-core is not set
# CONFIG_PACKAGE_kmod-usb-storage is not set
# CONFIG_PACKAGE_kmod-usb-storage-extras is not set
# CONFIG_PACKAGE_kmod-usb-storage-uas is not set
CONFIG_PACKAGE_kmod-usb-xhci-hcd=y
CONFIG_PACKAGE_kmod-usb3=y
# CONFIG_PACKAGE_ksmbd-server is not set
CONFIG_PACKAGE_libatomic=y
CONFIG_PACKAGE_libltdl=y
CONFIG_PACKAGE_liblua5.4=y
CONFIG_PACKAGE_libnftnl=y
# CONFIG_PACKAGE_libnl-core is not set
# CONFIG_PACKAGE_libnl-genl is not set
CONFIG_PACKAGE_libpcre2=y
CONFIG_PACKAGE_libuci-lua=y
CONFIG_PACKAGE_libyaml=y
# CONFIG_PACKAGE_luci-app-arpbind is not set
# CONFIG_PACKAGE_luci-app-ddns is not set
# CONFIG_PACKAGE_luci-app-ksmbd is not set
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-passwall2_Basic_Core_All=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Haproxy=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Geoview=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
# CONFIG_PACKAGE_luci-app-rclone_INCLUDE_rclone-ng is not set
# CONFIG_PACKAGE_luci-app-rclone_INCLUDE_rclone-webui is not set
# CONFIG_PACKAGE_luci-app-upnp is not set
# CONFIG_PACKAGE_luci-app-vlmcsd is not set
# CONFIG_PACKAGE_luci-app-vsftpd is not set
# CONFIG_PACKAGE_luci-app-wol is not set
CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_lyaml=y
CONFIG_PACKAGE_microsocks=y
# CONFIG_PACKAGE_miniupnpd is not set
CONFIG_PACKAGE_nftables-json=y
CONFIG_PACKAGE_resolveip=y
CONFIG_PACKAGE_sing-box=y
CONFIG_PACKAGE_tcping=y
CONFIG_PACKAGE_unzip=y
CONFIG_PACKAGE_v2ray-geoip=y
CONFIG_PACKAGE_v2ray-geosite=y
# CONFIG_PACKAGE_vlmcsd is not set
# CONFIG_PACKAGE_vsftpd is not set
# CONFIG_PACKAGE_wsdd2 is not set
CONFIG_PACKAGE_xray-core=y
CONFIG_PCRE2_JIT_ENABLED=y
CONFIG_QCOW2_IMAGES=y
CONFIG_SING_BOX_BUILD_ACME=y
CONFIG_SING_BOX_BUILD_CLASH_API=y
CONFIG_SING_BOX_BUILD_GVISOR=y
CONFIG_SING_BOX_BUILD_QUIC=y
CONFIG_SING_BOX_BUILD_TAILSCALE=y
CONFIG_SING_BOX_BUILD_UTLS=y
CONFIG_SING_BOX_BUILD_WIREGUARD=y
CONFIG_TARGET_KERNEL_PARTSIZE=78
CONFIG_TARGET_ROOTFS_PARTSIZE=548
# CONFIG_PACKAGE_libev is not set
# CONFIG_PACKAGE_libsodium is not set
# CONFIG_PACKAGE_libudns is not set
# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client is not set
# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Simple_Obfs is not set
# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_V2ray_Plugin is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin is not set
# CONFIG_PACKAGE_shadowsocks-rust-sslocal is not set
# CONFIG_PACKAGE_shadowsocksr-libev-ssr-local is not set
# CONFIG_PACKAGE_shadowsocksr-libev-ssr-redir is not set
# CONFIG_PACKAGE_simple-obfs-client is not set
# CONFIG_PACKAGE_v2ray-plugin is not set

EOF

# 
# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分结束●●●●●●●●●●●●●●●●●●●●●●●● #
# 

sed -i 's/^[ \t]*//g' ./.config

# 返回目录
cd $HOME

# 配置文件创建完成
