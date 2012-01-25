
-------------------------------------------------------------------------------
-- Allows Squeezeplay players connected to MySqueezebox.com to play Polish
-- public radio streams
-------------------------------------------------------------------------------
-- Copyright 2012 Michal Malek <michalm@jabster.pl>
-------------------------------------------------------------------------------
-- This file is licensed under BSD. Please see the LICENSE file for details.
-------------------------------------------------------------------------------

-- stuff we use
local assert, getmetatable, ipairs, pcall, setmetatable, tonumber, tostring = assert, getmetatable, ipairs, pcall, setmetatable, tonumber, tostring

local oo                     = require("loop.simple")

local string                 = require("string")
local table                  = require("jive.utils.table")
local io                     = require("io")
local SocketHttp             = require("jive.net.SocketHttp")
local RequestHttp            = require("jive.net.RequestHttp")
local json                   = require("json")

local Applet                 = require("jive.Applet")
local System                 = require("jive.System")
local Framework              = require("jive.ui.Framework")
local Icon                   = require("jive.ui.Icon")
local Label                  = require("jive.ui.Label")
local Textarea               = require("jive.ui.Textarea")
local Window                 = require("jive.ui.Window")
local Popup                  = require("jive.ui.Popup")
local SimpleMenu             = require("jive.ui.SimpleMenu")
local Timer                  = require("jive.ui.Timer")
local Player                 = require("jive.slim.Player")
local jnt                    = jnt

local JIVE_VERSION           = jive.JIVE_VERSION

local debug                  = require("jive.utils.debug")
local appletManager          = appletManager

local CHANNELS_HOST = "moje.polskieradio.pl"
local CHANNELS_QUERY = "api/?key=20439fdf-be66-4852-9ded-1476873cfa22&output=json"

local _streamCallback = function(event, menuItem)
	local action = event:getType() == ACTION and event:getAction() or event:getType() == EVENT_ACTION and "play"
	local player = Player:getLocalPlayer()
	local server = player:getSlimServer()
	server:userRequest(nil,	player:getId(), { "playlist", "play", menuItem.stream, menuItem.text })

	appletManager:callService('goNowPlaying', Window.transitionPushLeft, false)
end

local function _channelStreamUrl(channel)
	for i,stream in ipairs(channel.AlternateStationsStreams) do
		if stream.name == "MP3-AAC" then
			return stream.link
		end
	end
	return nil
end

module(..., Framework.constants)
oo.class(_M, Applet)

function show(self, menuItem)
	
	local window = Window("text_list", menuItem.text)
	local menu = SimpleMenu("menu")
	--window:addWidget(menu)
	--local textArea = Textarea("text", "Jakistam tekst", "\n")
	--window:addWidget(textArea)
	window:addWidget(menu)

	self:tieAndShowWindow(window)

	--menu:lock()
	local timer = Timer(1000,
		function()
			log:info("timer end")
			--window:show()
		end, true)
	timer:start()
	log:info("timer start")

	local function sink(chunk, err)
		if err then
			log:error( err )
		elseif chunk then
			self.channels = json.decode(chunk).channel
 			for i,channel in ipairs(self.channels) do
				--log:info("received JSON element: ", )
				local newMenuItem = {
					id = channel.id,
					text = channel.title,
					icon = Icon("icon"),
					callback = _streamCallback,
					stream = _channelStreamUrl(channel),
					style = 'item_choice'
				}

				if newMenuItem.stream then
					local req = RequestHttp(newMenuItem.icon:sink(), 'GET', channel.image )
					local uri = req:getURI()
					local http = SocketHttp(jnt, uri.host, uri.port, uri.host)
					http:fetch(req)
					menu:addItem(newMenuItem)
				end
 			end
		end
	end
	
	local http = SocketHttp(jnt, CHANNELS_HOST, 80)
	local req = RequestHttp(sink, 'GET', 'http://' .. CHANNELS_HOST .. '/' .. CHANNELS_QUERY )

	-- go get it!
	http:fetch(req)
	
	return window
end
