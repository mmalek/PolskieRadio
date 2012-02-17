
-------------------------------------------------------------------------------
-- Allows Squeezeplay players connected to MySqueezebox.com to play Polish
-- public radio streams
-------------------------------------------------------------------------------
-- Copyright 2012 Michal Malek <michalm@jabster.pl>
-------------------------------------------------------------------------------
-- This file is licensed under BSD. Please see the LICENSE file for details.
-------------------------------------------------------------------------------

-- stuff we use
local assert, ipairs, pairs, type = assert, ipairs, pairs, type

local oo                     = require("loop.simple")

local json                   = require("json")
local lom                    = require("lxp.lom")

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
local PODCAST_HOST = "www.polskieradio.pl"
local PODCAST_BASE = "Podcast"
local PODCAST_FEEDS = {
	{ text = "Bardzo Ważny Projekt",                                feed = "fe75a17b-3b54-4c70-a639-b332dfbac3a4" },
	{ text = "Biegam, bo lubię",                                    feed = "5757e01b-0754-4598-a74e-9059285223c1" },
	{ text = "Co w mowie piszczy",                                  feed = "c9051f3f-e5eb-4e39-82e9-a943e017536d" },
	{ text = "Dobronocka",                                          feed = "da0d7581-4fb7-446d-8d55-b778f10d0830" },
	{ text = "Europejski Magazyn Kulturalny",                       feed = "9635535f-13d0-42f5-a895-8c5e7a0f726a" },
	{ text = "Fajny film wczoraj widziałem",                        feed = "ab3dd76e-fcef-4446-b352-13fe6e75e007" },
	{ text = "Głosy z przeszłości",                                 feed = "11037aae-a0f3-4a2e-8853-17fa1d12c3f6" },
	{ text = "Instukcja obsługi człowieka",                         feed = "894e36d3-17e5-48e2-bd83-aad181c622ca" },
	{ text = "Jest taki obraz",                                     feed = "c1383df8-8582-40d6-90a3-bd30029f3607" },
	{ text = "Klub Ludzi Ciekawych Wszystkiego",                    feed = "2c77df19-395a-427c-b8f2-fa2fbf3f9eac" },
	{ text = "Klub Trójki",                                         feed = "ed6dc47e-7c5c-4af0-9ce5-f17272510f0d" },
	{ text = "Kulturalny Wieczór z Jedynką",                        feed = "ce516fd0-c774-46db-940c-35ea279303b8" },
	{ text = "Lista osobista",                                      feed = "8875a187-1d5b-479e-b762-e0b514a6e928" },
	{ text = "Na wyciągnięcie ręki",                                feed = "ff1444d6-e6e2-4d9a-b3bd-e8cd4b3e5af2" },
	{ text = "Notatnik Dwójki",                                     feed = "8c1328f7-d549-4e70-9691-e1804cc74df8" },
	{ text = "Puls Trójki",                                         feed = "7a5bd819-fce6-47af-a42d-06ab8f65043b" },
	{ text = "Raport o stanie świata",                              feed = "02ba1fbb-a0b3-436c-a517-931af8609368" },
	{ text = "Reportaż",                                            feed = "7bf37c2d-6975-4311-9707-d9c1031adf4c" },
	{ text = "Salon ekonomiczny Trójki i Dziennika Gazety Prawnej", feed = "d731f91b-1f1f-4f62-bcbe-e89d7a5ed50f" },
	{ text = "Salon polityczny Trójki",                             feed = "6e8788c0-1d6e-4cce-b04b-765a80ac52e0" },
	{ text = "Sezon na Dwójkę",                                     feed = "1ca42926-71ac-483d-8f94-a125305f537f" },
	{ text = "Słowa po zmroku",                                     feed = "ae1e4ae1-1f38-418b-b842-535ffcc43f60" },
	{ text = "Słynne powieści",                                     feed = "e64c2b0b-2c48-4483-a935-8b7dd408802a" },
	{ text = "Śniadanie w Trójce",                                  feed = "0ace19e8-ed65-4232-9f43-affc040ca14d" },
	{ text = "Sygnały dnia",                                        feed = "f8204f32-8522-4ae1-b081-284cc7b95508" },
	{ text = "Teren Kultura",                                       feed = "2ef02f5f-e604-49f3-9029-76e80ea7aded" },
	{ text = "Trójkowo, filmowo",                                   feed = "b5b30a95-662b-4554-be99-fa3f43d54c20" },
	{ text = "Tygodnik literacki",                                  feed = "aea2a083-26aa-4af7-8286-fb0f53b4c57a" },
	{ text = "Tym żył świat",                                       feed = "6a681240-327a-46e2-9eff-3339ecf8b3a5" },
	{ text = "W stronę sztuki",                                     feed = "dcfa48f3-7c0a-4acd-b8ad-1777df031c44" },
	{ text = "Za, a nawet przeciw",                                 feed = "c2a8a112-3d6a-41b4-b253-e96a0e585eb9" },
	{ text = "Zagadkowa niedziela",                                 feed = "ed4ef025-a23f-4746-a458-9fb51b158425" },
	{ text = "Zakładka literacka",                                  feed = "14017c7c-44f7-4241-8001-d1819af26638" },
	{ text = "Zapiski ze współczesności",                           feed = "8579fd71-b09e-4274-8bd8-c93efe7fb4ac" },
	{ text = "Zapraszamy do Trójki - popołudnie",                   feed = "ea372692-7321-4876-a5f8-38cd39f141db" },
	{ text = "Zapraszamy do Trójki - ranek",                        feed = "c9b49e69-cb4c-48e4-aca5-98c574981e2f" }
}

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

			menu:addItem( { text = self:string("PODCASTS"), callback = function(event,menuItem) self:showPodcastList( menuItem ) end } )
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

function showPodcastList(self, menuItem)

	local window = Window("text_list", menuItem.text)
	local menu = SimpleMenu("menu")
	window:addWidget(menu)

	for _,feed in pairs(PODCAST_FEEDS) do
		menu:addItem( { text = feed.text, callback = function(event,menuItem) self:showPodcastContent(menuItem, feed.feed) end } )
	end

	self:tieAndShowWindow(window)
	return window
end

function showPodcastContent(self, menuItem, feed)

	local window = Window("text_list", menuItem.text)
	local menu = SimpleMenu("menu")
	window:addWidget(menu)

	local function sink(chunk, err)
		if err then
			log:error( err )
		elseif chunk then
			local rss = lom.parse( chunk )
			for _, entry in ipairs(rss) do
				if type(entry) == 'table' and entry.tag == 'channel' then
					for _, channelEntry in ipairs(entry) do
						if type(channelEntry) == 'table' and channelEntry.tag == 'item' then
							local newMenuItem = {
								callback = _streamCallback,
								style = 'item_choice'
							}

							for _,itemEntry in ipairs(channelEntry) do
								if type(itemEntry) == 'table' and itemEntry.tag == 'enclosure' then
									newMenuItem.stream = itemEntry.attr.url
								elseif type(itemEntry) == 'table' and itemEntry.tag == 'title' then
									newMenuItem.text = itemEntry[1]
								end
							end

							if newMenuItem.stream and newMenuItem.text then
								menu:addItem( newMenuItem )
							end
						end
					end
				end
			end
		end
	end

	local http = SocketHttp(jnt, PODCAST_HOST, 80)
	local req = RequestHttp(sink, 'GET', 'http://' .. PODCAST_HOST .. '/' .. PODCAST_BASE .. '/' .. feed )

	-- go get it!
	http:fetch(req)

	self:tieAndShowWindow(window)
	return window
end
