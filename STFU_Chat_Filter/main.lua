-- Addon table.
STFU = {
	["filter_lang"] = "",
	["in_sanctuary"] = false,
}

local this_addon = "STFU_Chat_Filter"
local debug = false

-- Event handlers.
-- NOTE: The "zone changed" events are mutually exclusive (only 1 fires).
local f = CreateFrame("FRAME")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_INDOORS")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

function f:OnEvent(event, ...)
	f[event](f, ...)
end

function f:ADDON_LOADED(name)
	if name == this_addon then
		STFU:init()
	end
end

function f:PLAYER_ENTERING_WORLD()
	-- Triggers at login, /reloadui and loading screen transitions.
	-- NOTE: We also need to detect sanctuary status, since the zone change
	-- events don't fire on /reloadui (but they do fire on login).
	STFU:detect_language()
	STFU:detect_sanctuary()
end

function f:ZONE_CHANGED()
	-- Fires when walking between differently named outdoors areas.
	STFU:detect_sanctuary()
end

function f:ZONE_CHANGED_INDOORS()
	-- Fires when walking into interiors, such as city shops or inns.
	STFU:detect_sanctuary()
end

function f:ZONE_CHANGED_NEW_AREA()
	-- Fires when doing a major area switch (when the "channels" switch).
	STFU:detect_sanctuary()
end

f:SetScript("OnEvent", f.OnEvent)

-- Addon functions.
function STFU:init()
	-- Register chat filter.
	-- NOTE: Only filters chat box, not the speech bubbles above their heads.
	local function chat_filter(self, msg_type, msg, author, lang, ...)
		local hide_msg = false

		-- Hide opposite-faction messages when in sanctuaries (such as Dalaran
		-- and Shattrath). We don't filter in the wild, to preserve awareness.
		-- NOTE: There is no risk of "city /yells" being seen while outside the
		-- city, in a "non-sanctuary area", because yells are only transmitted
		-- to people inside the same city borders.
		if STFU.in_sanctuary and lang == STFU.filter_lang then
			hide_msg = true
		end

		if debug and hide_msg then
			DEFAULT_CHAT_FRAME:AddMessage("Filtered: (" .. msg_type .. ") (" .. lang .. ") [" .. author .. "] " .. msg)
		end

		return hide_msg
	end

	for _, msg_type in pairs({ "SAY", "YELL" }) do
		ChatFrame_AddMessageEventFilter("CHAT_MSG_" .. msg_type, chat_filter)
	end
end

function STFU:detect_language()
	-- Determine which language to filter from chat.
	-- NOTE: Only filters the main language, since nobody uses sub-languages.
	STFU.filter_lang = "Common"
	if UnitFactionGroup("player") == "Alliance" then
		STFU.filter_lang = "Orcish"
	end
end

function STFU:detect_sanctuary()
	-- Check if player is in a non-PvP "sanctuary" (Dalaran, Shattrath, etc).
	local pvp_type = GetZonePVPInfo()
	STFU.in_sanctuary = (pvp_type == "sanctuary")

	if debug then
		DEFAULT_CHAT_FRAME:AddMessage("Sanctuary: " .. (STFU.in_sanctuary and "yes" or "no"))
	end
end
