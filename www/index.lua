 
-- see luci docs:
-- http://luci.subsignal.org/api/luci/
-- http://luci.subsignal.org/api/nixio/
local fs  = require "nixio.fs"
-- local sys = require "luci.sys"

local os = require "os"

-- uci, the OpenWRT configuration subsystem
-- see: http://wiki.openwrt.org/doc/uci
-- also see network.lua
-- wireless settings are in: /etc/config/wireless
local uci = require "luci.model.uci".cursor()
local util = require "luci.util"
local protocol = require "luci.http.protocol"
local http = require "luci.http"
-- local json = require "luci.json"

-- mustache-like template engine
package.path = package.path..";/www/hige.lua"
require 'hige'


function redirect(url)
  uhttpd.send("HTTP/1.0 303 See Here")
  uhttpd.send("Location: "..url)  
  uhttpd.send("Content-Type: text/html")
  uhttpd.send("\r\n\r\n")
  uhttpd.send('<html><head>')
  uhttpd.send('<meta http-equiv="refresh" content="0; URL='..url..'" />')
  uhttpd.send('</head><body>')
  uhttpd.send('</body></html>')
end 


function send_header(mime_type)
  uhttpd.send("HTTP/1.0 200 OK")
  uhttpd.send("Content-Type: "..mime_type)
  uhttpd.send("\r\n\r\n")
end

function serve_file(path, mime_type)
  send_header(mime_type)
  uhttpd.send(fs.readfile(path))
end


function print_wifis()
  send_header("text/html")
  uhttpd.send("<!doctype html>")
  uhttpd.send("<html><head></head><body>")
  -- ssid1 = uci:get("wireless", "@wifi-iface[0]", "ssid")
  uci:save("wireless")
  uci:foreach("wireless", "wifi-iface",
    function(s)
      if s['ssid'] then
        uhttpd.send("<br><br>"..s['ssid'].."<br><br>")
      else
        uhttpd.send("<br><br>invalid entry<br><br>")
      end
    end) 
  uhttpd.send("</body>")
  uhttpd.send("</html>")
end

function get_ssids()
  -- ssid1 = uci:get("wireless", "@wifi-iface[0]", "ssid")
  ssids = {}
  i = 1
  uci:foreach("wireless", "wifi-iface",
    function(s)
      if s['ssid'] then
        key = "ssid"..i
        ssids[key] = s['ssid']
        i = i+1
      end
    end) 
  -- ssids looks like: {ssid1="A", ssid2="B", ...}
  return ssids
end


function filter_ssid(str)
  chr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~!@#$%^&*()-_+={}[]:<>,.?"
  local s = ""
  for g in str:gmatch( "["..chr.."]" ) do
    s = s .. g
  end
  return s
end

function create_wifis(ssids)
  -- ssids looks like: {ssid1="A", ssid2="B", ssid3="C", ssid4="D"}
  -- check for valid SSIDs
  any_valid = false
  wifis = {}
  for i = 1,4,1 do
    ssid_cur = ssids['ssid'..i]
    if ssid_cur and ssid_cur ~= '' and string.len(ssid_cur) < 32 then
      -- table.insert(wifis, string.sub(filter_ssid(ssid_cur),1,31))
      table.insert(wifis, ssid_cur)
      any_valid = true
    end
  end

  if any_valid then
    uci:delete_all('wireless', 'wifi-iface')  -- delete all current
    for k,v in ipairs(wifis) do
      uci:section('wireless', 'wifi-iface', nil, {device='radio0', network='lan', mode='ap', ssid=v, encryption='none'})
    end
    uci:save("wireless")  -- saves until reboot
  end
  return any_valid
end


function save_wifis_permanently()
  uci:save("wireless")
  uci:commit('wireless')  -- write to files, persisten after reboot
end


function apply_wifis()
  uci:apply({'wireless'})  -- actually restart demons
  -- luci.sys.call("/etc/init.d/network restart")
end


function serve_template(template, params)
  send_header("text/html")
  uhttpd.send(hige.render(fs.readfile(template), params))
end



function handle_request(env)
  basename = fs.basename(env.REQUEST_URI)
  has_querystring = string.find(basename, '?')
  if has_querystring then
    basename = string.sub(basename, 1, has_querystring-1)
  end
  if  basename == "style.css" then
    serve_file("/www/style.css", "text/css")
  elseif  basename == "bootstrap.css" then
    serve_file("/www/bootstrap.css", "text/css")
  elseif  basename == "jquery.js" then
    serve_file("/www/jquery.js", "text/javascript")
  elseif  basename == "bootstrap.js" then
    serve_file("/www/bootstrap.js", "text/javascript")
  elseif  basename == "background.gif" then
    serve_file("/www/background.gif", "image/gif")    
  elseif  basename == "list" then
    print_wifis()
  elseif basename == "ready" then
    -- send_header("text/html")
    -- uhttpd.send('ready_steady')
    send_header("application/json")
    uhttpd.send('{"ret":"ready_steady"}')
    uhttpd.send('\n\n')
    -- ret = {"ret"="ready_steady"}
    -- uhttpd.send(http.write_json(ret))
  elseif basename == "tag" then
    qs = protocol.urldecode_params(env.QUERY_STRING or "")
    if qs['ssid1'] or qs['ssid2'] or qs['ssid3'] or qs['ssid4'] then
      ret = create_wifis(qs)
      if ret then  -- we have actually set some valid new wifis
        apply_wifis()
      end
    else  -- no new SSIDs to set

      for k,v in pairs(uhttpd) do
          -- print("key", k, "value", v)
          uhttpd.send(k.."\n")
      end

      uhttpd.send("0")
      -- redirect("index.html")
    end    
  else  -- catch all
    serve_template("/www/index.html", get_ssids())
  end
end



-- env looks like this:
-- printed with: uhttpd.send('<br><br>'..json.encode(env).."<br>")
-- {"SCRIPT_NAME":"/",
--  "HTTP_VERSION":1.1,
--  "SERVER_ADDR":"192.168.1.1",
--  "REMOTE_ADDR":"192.168.1.204",
--  "headers":{"Host":"192.168.1.1",
--             "Connection":"keep-alive",
--             "Cookie":"Language=en",
--             "Accept":"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
--             "User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:12.0) Gecko/20100101 Firefox/12.0",
--             "DNT":"1",
--             "Accept-Language":"en-us,en;q=0.5",
--             "Accept-Encoding":"gzip, deflate"},
--  "SERVER_PORT":80,
--  "REMOTE_PORT":57523,
--  "QUERY_STRING":"sadjfh=23&sadfl=4",
--  "REQUEST_URI":"/?sadjfh=23&sadfl=4",
--  "SERVER_PROTOCOL":"HTTP/1.1",
--  "REQUEST_METHOD":"GET"}



-- /etc/config/wireless
--
-- config wifi-device 'radio0'
--  option type 'mac80211'
--  option channel '11'
--  option macaddr 'f8:d1:11:2c:76:e4'
--  option hwmode '11ng'
--  option htmode 'HT20'
--  list ht_capab 'SHORT-GI-20'
--  list ht_capab 'SHORT-GI-40'
--  list ht_capab 'RX-STBC1'
--  list ht_capab 'DSSS_CCK-40'
--  option disabled '0'
-- 
-- config wifi-iface
--  option device 'radio0'
--  option network 'lan'
--  option mode 'ap'
--  option encryption 'none'
--  option ssid 'Whatever'
-- 
-- config wifi-iface
--  option device 'radio0'
--  option network 'lan'
--  option mode 'ap'
--  option ssid 'I am rich, BITCH!'
--  option encryption 'none'
-- 
-- config wifi-iface
--  option device 'radio0'
--  option network 'lan'
--  option mode 'ap'
--  option ssid 'Thats right bitches'
--  option encryption 'none'
-- 
-- config wifi-iface
--  option device 'radio0'
--  option network 'lan'
--  option mode 'ap'
--  option ssid 'What can you say in 32 chars?'
--  option encryption 'none'

