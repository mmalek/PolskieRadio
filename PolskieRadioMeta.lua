
-------------------------------------------------------------------------------
-- Allows Squeezeplay players connected to MySqueezebox.com to play Polish
-- public radio streams
-------------------------------------------------------------------------------
-- Copyright 2012 Michal Malek <michalm@jabster.pl>
-------------------------------------------------------------------------------
-- This file is licensed under BSD. Please see the LICENSE file for details.
-------------------------------------------------------------------------------


local oo            = require("loop.simple")

local AppletMeta    = require("jive.AppletMeta")

local appletManager = appletManager
local jiveMain      = jiveMain

local jnt           = jnt

module(...)
oo.class(_M, AppletMeta)


function jiveVersion(meta)
	return 1, 1
end

function registerApplet(meta)
	jnt:subscribe(meta)
	meta.menu = meta:menuItem('PolskieRadio', 'home', 'POLISH_RADIO', function(applet, ...) applet:show(...) end)
	jiveMain:addItem(meta.menu)
end
