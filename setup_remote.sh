#!/bin/sh

# to be executed on router remotely from setup.sh

# install packages for mod-lua
opkg install /root/*.ipk
# rm /root/*.ipk

# setup uhttpd to serve index.lua
# this is a catch-all, all requests go through it
# The config file is "/etc/config/uhttpd"
uci set uhttpd.main.lua_prefix=/
uci set uhttpd.main.lua_handler=/www/index.lua
uci commit uhttpd
/etc/init.d/uhttpd restart

# make router a captive portal by resolving all domains
# to its own IP address (restart of dnsmasq required)
echo "address=/#/192.168.1.1" >> /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart

# enable wifi radio, set default SSID
uci set wireless.@wifi-iface[0].ssid="Free Public WifiTagger"
uci set wireless.@wifi-device[0].disabled=0
uci commit wireless
/etc/init.d/network restart


