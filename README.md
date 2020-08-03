RouterWars
=============

RouterWars is a access point mod hack for people to leave messages via a wireless network broadcast SSID and custom firmware, i.e. so instead of seeing 'NETGEAR' in the menu of wifi networks in range, you might see 'Watch out for the Cop on 4th and Perry'. 

Each ID is a string that can be edited through a web interface to broadcast to anyone within range of the routers broadcast. When connecting to any of the SSIDs the access point sets up a captive portal to reroute any web page requests to the web interface. It can be used to leave anonymous messages to people within its range, warnings to activists or protesters in the area or even to troll your neighbors.

This project was made possible by the support of Clinic for Open Source Arts (COSA) http://clinicopensourcearts.org/
and is under a GPL-3.0 License.


Setup Process
=============
- buy a TP-Link WiFi Router (reference https://openwrt.org/toh/hwdata/tp-link/start for supported models)
- flash firmware
- setup ssh and login password (sexylama)
- run setup.sh
  - chmod +x setup.sh
  - ./setup.sh
- restart access point
- connect to "Free Public WifiTagger"
- open any url -> web interface should open



Flash Firmware
---------------
- plugin router to ethernet (not wan port)
- open web interface at http://192.168.0.1/ or http://192.168.1.1/
  - user: admin
  - password: admin
- restore factory settings if anythings was changed
- run system upgrade uploading the firmware with the "factory" suffix
  - openwrt-ar71xx-generic-tl-wr741nd-v4-squashfs-factory.bin
- do not interrupt upload

Setup SSH and Login Password
-----------------------------
- after restart you can now telnet to router "telnet 192.168.1.1" and
- set a password with "passwd"
- then telnet gets disabled and ssh login works with "ssh root@192.168.1.1"
- also "ssh -o UserKnownHostsFile=/dev/null root@192.168.1.1" if you have key problems

Run setup.sh
-------------
- this will copy a bunch of files to the router
- amoung them setup_remote.sh
- which it will then also execute

Troubleshooting
----------------
- if something doesn't work ssh to router and
- run setup_remote.sh manually
- check output for errors


Need to Know More
==================
- guide
  - http://wiki.openwrt.org/toh/tp-link/tl-wr741nd
- firmware
  - https://openwrt.org/downloads#browse_the_openwrtlede_firmware_repository
- packages
  - https://openwrt.org/packages/start

shell
=======
- ssh root@192.168.1.1
  - pass: colorado19
- remotely execute stuff
  - ssh nortd@nortd.com 'cd /www/; mkdir images;'
- copy stuff
  - scp index.lua root@192.168.1.1:/www/
- disk info 
  - df -h
- uci ... general configuration see: http://wiki.openwrt.org/doc/uci
- enable wifi
  - uci set wireless.@wifi-device[0].disabled=0
- login without host key verification
  - ssh -o UserKnownHostsFile=/dev/null root@192.168.1.1

Upgrade Firmware
----------------
- copy firmware with "sysupgrade" suffix to /tmp on router
- rename to tplink.bin
- run "mtd -r write /tmp/tplink.bin firmware"


Install Lua Webserver stuff (latest firmware includes this)
------------------------------
- liblua
- lua
- uhttpd - http://wiki.openwrt.org/doc/uci/uhttpd
  - /etc/init.d/uhttpd enable
  - /etc/init.d/uhttpd start
- [uhttpd-mod-lua]
- luci-lib-core - https://luci.subsignal.org/trac/browser
	- libuci-lua
- luci-lib-web
	- luci-lib-sys
	- luci-lib-nixio
	- luci-lib-lmo
  - luci-sgi-cgi
	- [luci-sgi-uhttpd - /usr/lib/lua/luci/sgi/uhttpd.lua]
- [luci-lib-json]

### docs
- http://luci.subsignal.org/api/luci/
- http://luci.subsignal.org/api/nixio/
- scp lua_5.1.4-8_ar71xx.ipk root@192.168.1.1:/root/


setting up uhttp-mod-lua
------------------------
- opkg install uhttpd-mod-lua
- uci set uhttpd.main.lua_prefix=/ ... using root disable statis file served
- uci set uhttpd.main.lua_handler=/www/index.lua
- uci commit uhttpd  ... make changed persistent after reboot
- /etc/init.d/uhttpd restart
- wget -qO- http://127.0.0.1/

### index.lua
function handle_request(env)
        uhttpd.send("HTTP/1.0 200 OK\r\n")
        uhttpd.send("Content-Type: text/plain\r\n\r\n")
        uhttpd.send("Hello world.\n")
end



wireless stuff
---------------
- config file
  - /etc/config/wireless
- restart network
  - /etc/init.d/network restart
- using uci
  - uci get wireless.@wifi-iface[0].ssid
  - uci set wireless.@wifi-iface[0].ssid="What up?"
  - uci commit wireless

More package info
-------------------

- luci-lib-core
	/usr/lib/lua/luci/store.lua
	/usr/lib/lua/luci/fs.lua
	/sbin/luci-reload
	/usr/lib/lua/luci/model/network.lua
	/usr/lib/lua/luci/ip.lua
	/usr/lib/lua/luci/debug.lua
	/usr/lib/lua/luci/util.lua
	/etc/config/ucitrack
	/usr/lib/lua/luci/ltn12.lua
	/usr/lib/lua/luci/ccache.lua
	/usr/lib/lua/luci/model/uci.lua
	/usr/lib/lua/luci/init.lua
	/usr/lib/lua/luci/version.lua
	/usr/lib/lua/luci/model/firewall.lua


CAPTIVE PORTAL
----------------
Use dnsmsqr to wildcard all domains to the routers IP.
In "/etc/dnsmasq.conf" add "address=/#/192.168.1.1" and restart dnsmasq.
The "#" could also be a "com" to reroute all .com domains.



Typical HTTP HEADER
-----------------------
DOCUMENT_ROOT='/www'
GATEWAY_INTERFACE='CGI/1.1'
HTTP_ACCEPT='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
HTTP_ACCEPT_ENCODING='gzip, deflate'
HTTP_ACCEPT_LANGUAGE='en-US,en;q=0.5'
HTTP_CONNECTION='keep-alive'
HTTP_COOKIE='SessionID_R3=0; FirstMenu=Admin_9; SecondMenu=Admin_9_1; ThirdMenu=Admin_9_1_0; Language=de'
HTTP_HOST='192.168.1.1'
IFS=' 	
'
OPTIND='1'
PATH='/sbin:/usr/sbin:/bin:/usr/bin'
PPID='1050'
PS1='\w \$ '
PS2='> '
PS4='+ '
PWD='/www'
QUERY_STRING=''
REDIRECT_STATUS='200'
REMOTE_ADDR='192.168.1.211'
REMOTE_HOST='192.168.1.211'
REMOTE_PORT='56381'
REQUEST_METHOD='GET'
REQUEST_URI='/cgi-bin/print_env.sh'
SCRIPT_FILENAME='/www/cgi-bin/print_env.sh'
SCRIPT_NAME='/cgi-bin/print_env.sh'
SERVER_ADDR='192.168.1.1'
SERVER_NAME='192.168.1.1'
SERVER_PORT='80'
SERVER_PROTOCOL='HTTP/1.1'
SERVER_SOFTWARE='uHTTPd'

