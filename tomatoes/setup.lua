-- file: setup.lua
local module = {}
local local_config = require("local_config")
local app = require("app")

local function blink()
    local state = gpio.HIGH
    tmr.alarm(5, 200, tmr.ALARM_AUTO, function()
      state = (state == 0) and gpio.HIGH or gpio.LOW
      gpio.write(config.LED_PIN, state)
    end)
end

local function stop_blinking()
    tmr.stop(5)
end



local function wifi_wait_ip()
  if wifi.sta.getip()== nil then
    blink()
    print("IP unavailable, Waiting...")
  else
    stop_blinking()
    tmr.stop(1)
    local database = require("database")
    print("\n====================================")
    print("ESP8266 mode is: " .. wifi.getmode())
    print("MAC address is: " .. wifi.ap.getmac())
    print("IP is "..wifi.sta.getip())
    print("====================================")
    database.insert('nodes', { node_ip = '"'..wifi.sta.getip()..'"' })
    unrequire('database')
    app.start()
  end
end

local function wifi_start(list_aps)
    if list_aps then
        for key,value in pairs(list_aps) do
            if local_config.SSID and local_config.SSID[key] then
                wifi.setmode(wifi.STATION);
                wifi.sta.config(key,local_config.SSID[key])
                wifi.sta.connect()
                print("Connecting to " .. key .. " ...")
                local_config.SSID = nil  -- can save memory
                tmr.alarm(1, 2500, 1, wifi_wait_ip)
            end
        end
    else
        print("Error getting AP list")
    end
end

local function configure_pins()
    gpio.mode(config.DHT_PIN, gpio.OUTPUT)
    gpio.mode(config.LED_PIN, gpio.OUTPUT)
    gpio.mode(config.YL_PIN, gpio.OUTPUT)
    gpio.write(config.YL_PIN, gpio.LOW)
    gpio.mode(config.CMW_PIN, gpio.INPUT, gpio.PULLUP)
    gpio.mode(config.RELAY_PIN, gpio.OUTPUT)
    gpio.write(config.RELAY_PIN, gpio.LOW)
    gpio.mode(config.MEASURE_ONLY_MODE_PIN, gpio.INPUT, gpio.PULLUP)
end

function module.start()
  print("Configuring pins ...")
  configure_pins()
  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION);
  wifi.sta.getap(wifi_start)
  print('Configuring soil_humidity module (ADC)')
end

return module
