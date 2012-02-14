
-------------------------------------------------------------------------------
-- Allows Squeezeplay players connected to MySqueezebox.com to play Polish
-- public radio streams
-------------------------------------------------------------------------------
-- Copyright 2012 Michal Malek <michalm@jabster.pl>
-------------------------------------------------------------------------------
-- This file is licensed under BSD. Please see the LICENSE file for details.
-------------------------------------------------------------------------------

-- stuff we use
local assert, getmetatable, ipairs, pairs, pcall, setmetatable, tonumber, tostring = assert, getmetatable, ipairs, pairs, pcall, setmetatable, tonumber, tostring

local oo                     = require("loop.simple")

local json                   = require("json")

local Applet                 = require("jive.Applet")
local SocketHttp             = require("jive.net.SocketHttp")
local RequestHttp            = require("jive.net.RequestHttp")
local Framework              = require("jive.ui.Framework")
local Icon                   = require("jive.ui.Icon")
local Window                 = require("jive.ui.Window")
local SimpleMenu             = require("jive.ui.SimpleMenu")
local Timer                  = require("jive.ui.Timer")
local debug                  = require("jive.utils.debug")
local Player                 = require("jive.slim.Player")

local appletManager          = appletManager
local jiveMain               = jiveMain
local jnt                    = jnt

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

local function _getIconSink(icon)
	local iconSink = icon:sink()
	return function(chunk, err)
		if iconSink(chunk, err) then
			local prefSize = jiveMain:getSkinParam('THUMB_SIZE')
			local image = icon:getImage()
			local imageWidth,imageHeight = image:getSize()
			local shrinkFactor = math.max(imageWidth,imageHeight) / prefSize
			icon:setValue( image:shrink(shrinkFactor,shrinkFactor) )
		end
	end
end

module(..., Framework.constants)
oo.class(_M, Applet)

function show(self, menuItem)

	local window = Window("text_list", menuItem.text)
	local menu = SimpleMenu("menu")
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
			local cat2Menus = {}
			local channels = json.decode(chunk).channel
 			for i,channel in ipairs(channels) do
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
					local req = RequestHttp(_getIconSink(newMenuItem.icon), 'GET', channel.image )
					local uri = req:getURI()
					local http = SocketHttp(jnt, uri.host, uri.port, uri.host)
					http:fetch(req)

					
					local menuItems = cat2Menus[channel.category]
					if menuItems == nil then
						menuItems = {}
					end
					menuItems[#menuItems + 1] = newMenuItem
					cat2Menus[channel.category] = menuItems
				end
 			end

			for category,subItems in pairs(cat2Menus) do
				menu:addItem( { text = category, callback = function(event,menuItem) self:showCategoryItems(menuItem,subItems) end } )
			end

			menu:addItem( { text = self:string("PODCASTS"), callback = function(event,menuItem) self:showPodcasts( menuItem ) end } )
		end
	end

	local http = SocketHttp(jnt, CHANNELS_HOST, 80)
	local req = RequestHttp(sink, 'GET', 'http://' .. CHANNELS_HOST .. '/' .. CHANNELS_QUERY )

	-- go get it!
	http:fetch(req)
	
	return window
end

function showCategoryItems(self, menuItem, subItems)

	local window = Window("text_list", menuItem.text)
	local menu = SimpleMenu("menu")
	menu:setItems(subItems)
	window:addWidget(menu)

	self:tieAndShowWindow(window)

	return window
end

function showPodcasts(self, menuItem)

	local window = Window("text_list", menuItem.text)
	local menu = SimpleMenu("menu")
	window:addWidget(menu)

	self:tieAndShowWindow(window)

	return window
end
