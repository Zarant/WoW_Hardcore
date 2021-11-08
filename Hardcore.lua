--[[
Copyright 2020 Sean Kennedy
The Hardcore AddOn is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of Hardcore.

The Hardcore AddOn is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Hardcore AddOn is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the Hardcore AddOn. If not, see <http://www.gnu.org/licenses/>.
--]]

--[[ Const variables ]]--
local GRIEF_WARNING_OFF = 0
local GRIEF_WARNING_SAME_FACTION = 1
local GRIEF_WARNING_ENEMY_FACTION = 2
local GRIEF_WARNING_BOTH_FACTIONS = 3

--[[ Global saved variables ]]--
Hardcore_Settings = {
	notify = true,
	level_list = {},
}

--[[ Character saved variables ]]--
Hardcore_Character = {
	guid = "",
	time_tracked = 0, -- seconds
	time_played = 0, -- seconds
	accumulated_time_diff = 0, -- seconds
	tracked_played_percentage = 0,
	deaths = {},
	bubble_hearth_incidents = {},
	played_time_gap_warnings = {},
	trade_partners = {},
	grief_warning_conditions = GRIEF_WARNING_BOTH_FACTIONS,
}

--[[ Local variables ]]--
local debug = false
local pulses = {}
local online_pulsing = {}
local guild_versions = {}
local guild_versions_status = {}
local guild_online = {}
local guild_highest_version = '0.0.0'
local guild_roster_loading = false

local bubble_hearth_vars = {
	spell_id = 8690,
	bubble_name = "Divine Shield",
	light_of_elune_name = "Light of Elune",
}

-- addon communication
local CTL = _G.ChatThrottleLib
local COMM_NAME = "HardcoreAddon"
local COMM_PULSE_FREQUENCY = 10
local COMM_PULSE_CHECK_FREQUENCY = COMM_PULSE_FREQUENCY * 2
local COMM_UPDATE_BREAK = 4
local COMM_DELAY = 5
local COMM_BATCH_SIZE = 4
local COMM_COMMAND_DELIM = "$"
local COMM_FIELD_DELIM = "|"
local COMM_RECORD_DELIM = "^"
local COMM_COMMANDS = {"PULSE", "ADD", nil}

-- stuff
local PLAYER_NAME, _ = nil
local PLAYER_GUID = nil
local PLAYER_FACTION = nil
local GENDER_GREETING = {"guildmate", "brother", "sister"}
local recent_levelup = nil
local Last_Attack_Source = nil
local PICTURE_DELAY = .65
local HIDE_RTP_CHAT_MSG_BUFFER = 0 -- number of messages in queue
local HIDE_RTP_CHAT_MSG_BUFFER_MAX = 2 -- number of maximum messages to wait for
local STARTED_BUBBLE_HEARTH_INFO = nil
local RECEIVED_FIRST_PLAYED_TIME_MSG = false
local PLAYED_TIME_GAP_THRESH = 600 -- seconds
local PLAYED_TIME_PERC_THRESH = 90 -- [0, 100]
local PLAYED_TIME_MIN_PLAYED_THRESH = 6000 -- seconds
local COLOR_RED = "|c00ff0000"
local COLOR_GREEN = "|c0000ff00"
local COLOR_YELLOW = "|c00ffff00"
local STRING_ADDON_STATUS_SUBTITLE = "Guild Addon Status"
local STRING_ADDON_STATUS_SUBTITLE_LOADING = "Guild Addon Status (Loading)"

-- frame display
local display = "Rules"
local displaylist = Hardcore_Settings.level_list
local icon = nil

-- available alert frame/icon styles
local MEDIA_DIR = "Interface\\AddOns\\Hardcore\\Media\\"
local ALERT_STYLES = {
	logo = {
		frame = Hardcore_Alert_Frame, -- frame object
		text = Hardcore_Alert_Text, -- text layer
		icon = Hardcore_Alert_Icon, -- icon layer
		file = "logo-emblem.blp", -- string
		delay = COMM_DELAY, -- int seconds
		alertSound = 8959
	},
	death = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-death.blp",
		delay = COMM_DELAY,
		alertSound = nil
	},
	hc_green = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-green.blp",
		delay = COMM_DELAY,
		alertSound = 8959
	},
	hc_red = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = COMM_DELAY,
		alertSound = 8959
	},
	spirithealer = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-spirithealer.blp",
		delay = COMM_DELAY,
		alertSound = 8959
	},
	bubble = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 8,
		alertSound = 8959
	},
	hc_enabled = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file  = "alert-hc-red.blp",
		delay = 10,
		alertSound = nil
	},
	hc_pvp_warning = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file  = "hc-pvp-alert.blp",
		delay = 10,
		alertSound = 8192
	},
}
Hardcore_Alert_Frame:SetScale(0.7)

-- the big frame object for our addon
local Hardcore = CreateFrame("Frame", "Hardcore", nil, "BackdropTemplate")
Hardcore.ALERT_STYLES = ALERT_STYLES

Hardcore_Frame:ApplyBackdrop()

--[[ Command line handler ]]--

local function SlashHandler(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if cmd == "levels" then
		Hardcore:Levels()
	elseif cmd == "alllevels" then
		Hardcore:Levels(true)
	elseif cmd == "show" then
		Hardcore_Frame:Show()
	elseif cmd == "hide" then
		-- they can click the hide button, dont really need a command for this
		Hardcore_Frame:Hide()
	elseif cmd == "debug" then
		debug = not debug
		Hardcore:Print("Debugging set to " .. tostring(debug))
	elseif cmd == "notify" then
		Hardcore_Settings.notify = not Hardcore_Settings.notify
		if true == Hardcore_Settings.notify then
			Hardcore:Print("Notification enabled")
		else
			Hardcore:Print("Notification disabled")
		end
	elseif cmd == "griefalert" then
		local grief_alert_option = ""
		for substring in args:gmatch("%S+") do
			grief_alert_option = substring
		end
		if grief_alert_option == "off" then
			Hardcore_Character.grief_warning_conditions = GRIEF_WARNING_OFF
			Hardcore:Print("Grief alert set to off.")
		elseif grief_alert_option == "horde" then
			if PLAYER_FACTION == "Horde" then
				Hardcore_Character.grief_warning_conditions = GRIEF_WARNING_SAME_FACTION
				Hardcore:Print("Grief alert set to same faction.")
			else
				Hardcore_Character.grief_warning_conditions = GRIEF_WARNING_ENEMY_FACTION
				Hardcore:Print("Grief alert set to enemy faction.")
			end
		elseif grief_alert_option == "alliance" then
			if PLAYER_FACTION == "Alliance" then
				Hardcore_Character.grief_warning_conditions = GRIEF_WARNING_SAME_FACTION
				Hardcore:Print("Grief alert set to same faction.")
			else
				Hardcore_Character.grief_warning_conditions = GRIEF_WARNING_ENEMY_FACTION
				Hardcore:Print("Grief alert set to enemy faction.")
			end
		elseif grief_alert_option == "both" then
			Hardcore_Character.grief_warning_conditions = GRIEF_WARNING_BOTH_FACTIONS
			Hardcore:Print("Grief alert set to both factions.")
		else
			local grief_alert_setting_msg = ""
			if Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_OFF then
				grief_alert_setting_msg = "off"
			elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_SAME_FACTION then
				if PLAYER_FACTION == "Alliance" then
					grief_alert_setting_msg = "same faction (alliance)"
				else
					grief_alert_setting_msg = "same faction (horde)"
				end
			elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_ENEMY_FACTION then
				if PLAYER_FACTION == "Alliance" then
					grief_alert_setting_msg = "enemy faction (horde)"
				else
					grief_alert_setting_msg = "enemy faction (alliance)"
				end
			elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_BOTH_FACTIONS then
				grief_alert_setting_msg = "both factions"
			end
			Hardcore:Print("Grief alert is currently set to: " .. grief_alert_setting_msg)
			Hardcore:Print("|cff00ff00Grief alert options:|roff horde alliance both")
		end
	-- Alert debug code
	elseif cmd == "alert" then
		local head, tail = "", {}
		for substring in args:gmatch("%S+") do
			if head == "" then
				head = substring
			else
				table.insert(tail, substring)
			end
		end

		local style, message = head, table.concat(tail, " ")
		local styleConfig
		if ALERT_STYLES[style] then
			styleConfig = ALERT_STYLES[style]
		else
			styleConfig = ALERT_STYLES.hc_red
		end

		Hardcore:ShowAlertFrame(styleConfig, message)
	-- End Alert debug code

	else
		-- If not handled above, display some sort of help message
		Hardcore:Print("|cff00ff00Syntax:|r/hardcore [command] [options]")
		Hardcore:Print("|cff00ff00Commands:|rshow deaths levels enable disable griefalert")
	end
end

SLASH_HARDCORE1, SLASH_HARDCORE2 = '/hardcore', '/hc'
SlashCmdList["HARDCORE"] = SlashHandler

local saved_variable_meta = {
	{ key = "guid", initial_data = UnitGUID("player") },
	{ key = "time_tracked", initial_data = 0 },
	{ key = "time_played", initial_data = 0 },
	{ key = "accumulated_time_diff", initial_data = 0 },
	{ key = "tracked_played_percentage", initial_data = 0 },
	{ key = "deaths", initial_data = {} },
	{ key = "bubble_hearth_incidents", initial_data = {} },
	{ key = "played_time_gap_warnings", initial_data = {} },
	{ key = "trade_partners", initial_data = {} },
	{ key = "grief_warning_conditions", initial_data = GRIEF_WARNING_BOTH_FACTIONS }
}

function Hardcore:InitializeSavedVariables()
	if Hardcore_Character == nil then
		Hardcore_Character = {}
	end

	for i, v in ipairs(saved_variable_meta) do
		if Hardcore_Character[v.key] == nil then
			Hardcore_Character[v.key] = v.initial_data
		end
	end
end

function Hardcore:ForceResetSavedVariables()
	for i, v in ipairs(saved_variable_meta) do
		Hardcore_Character[v.key] = v.initial_data
	end
end

--[[ Override default WoW UI ]]--

TradeFrameTradeButton:SetScript("OnClick", function()
	table.insert(Hardcore_Character.trade_partners, TradeFrameRecipientNameText:GetText())
	Hardcore_Character.trade_partners = Hardcore_FilterUnique(Hardcore_Character.trade_partners)
	AcceptTrade()
end)

--[[ Startup ]]--

function Hardcore:Startup()
	-- the entry point of our addon
	-- called inside loading screen before player sees world, some api functions are not available yet.

	-- event handling helper
	self:SetScript("OnEvent", function(self, event, ...)
		self[event](self, ...)
	end)

	-- actually start loading the addon once player ui is loading
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LOGIN")
end

--[[ Events ]]--

function Hardcore:PLAYER_LOGIN()
	Hardcore:HandleLegacyDeaths()

	-- cache player data
	_, class, _ = UnitClass("player")
	PLAYER_NAME, _ = UnitName("player")
	PLAYER_GUID = UnitGUID("player")
	PLAYER_FACTION, _ = UnitFactionGroup("player")
	local PLAYER_LEVEL = UnitLevel("player")

	-- fires on first loading
	self:RegisterEvent("PLAYER_UNGHOST")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("TIME_PLAYED_MSG")

	-- Register spell cast events for paladin for checking bubble hearth
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	Hardcore:InitializeSavedVariables()

	-- different guid means new character with the same name
	if Hardcore_Character.guid ~= PLAYER_GUID then
		Hardcore:ForceResetSavedVariables()
	end

	-- cache player name
	PLAYER_NAME, _ = UnitName("player")

	-- Show recording reminder
	Hardcore:RecordReminder()

	-- minimap button
	Hardcore:initMinimapButton()

	-- initiate pulse heartbeat
	Hardcore:InitiatePulse()

	-- initiate pulse heartbeat check
	Hardcore:InitiatePulseCheck()

	-- check players version against highest version
	local FULL_PLAYER_NAME = Hardcore_GetPlayerPlusRealmName()
	Hardcore:CheckVersionsAndUpdate(FULL_PLAYER_NAME, GetAddOnMetadata('Hardcore', 'Version'))
end

function Hardcore:UNIT_SPELLCAST_START(...)
	local unit, _, spell_id, _, _ = ...
	if unit == "player" and spell_id == bubble_hearth_vars.spell_id then
		for i = 1, 40 do
			name, _, _, _, _, _, _, _, _, _, _ = UnitBuff("player", i)
			if name == nil then
				STARTED_BUBBLE_HEARTH_INFO = nil
				return
			elseif name == bubble_hearth_vars.bubble_name or name == bubble_hearth_vars.light_of_elune_name then
				STARTED_BUBBLE_HEARTH_INFO = {}
				STARTED_BUBBLE_HEARTH_INFO.start_cast = date("%m/%d/%y %H:%M:%S")
				STARTED_BUBBLE_HEARTH_INFO.aura_type = name
				Hardcore:Print("WARNING: Bubble-hearth Detected\nCancel or risk invalidation")

				Hardcore:ShowAlertFrame(ALERT_STYLES.hc_red, "Bubble-hearth Detected\nCancel or risk invalidation")

				return
			end
		end
	end
end

function Hardcore:UNIT_SPELLCAST_STOP(...)
	local unit, _, spell_id, _, _ = ...
	-- 8690 is hearth spellid
	if STARTED_BUBBLE_HEARTH_INFO ~= nil then
		if unit == "player" and spell_id == bubble_hearth_vars.spell_id then
			Hardcore:Print("NOTE: Bubble-hearth Cancelled")
			Hardcore:ShowAlertFrame(ALERT_STYLES.hc_green, "Bubble-hearth Cancelled")
			STARTED_BUBBLE_HEARTH_INFO = nil
		end
	end
end

function Hardcore:UNIT_SPELLCAST_SUCCEEDED(...)
	local unit, _, spell_id, _, _ = ...
	-- 8690 is hearth spellid
	if STARTED_BUBBLE_HEARTH_INFO ~= nil then
		if unit == "player" and spell_id == bubble_hearth_vars.spell_id then
			Hardcore:Print("Completed Bubble-hearth")
			local bubble_hearth_info = {}
			bubble_hearth_info.start_cast = STARTED_BUBBLE_HEARTH_INFO.start_cast
			bubble_hearth_info.finish_cast = date("%m/%d/%y %H:%M:%S")
			bubble_hearth_info.guid = PLAYER_GUID
			bubble_hearth_info.aura_type = STARTED_BUBBLE_HEARTH_INFO.aura_type
			if Hardcore_Character.bubble_hearth_incidents == nil then
				Hardcore_Character.bubble_hearth_incidents = {}
				Hardcore_Character.bubble_hearth_incidents[1] = bubble_hearth_info
			else
				table.insert(Hardcore_Character.bubble_hearth_incidents, bubble_hearth_info)
			end

			Hardcore:PrintBubbleHearthInfractions()
			local message = PLAYER_NAME .. " just received a Bubble-hearth infraction at " ..
								bubble_hearth_info.start_cast
			SendChatMessage(message, "GUILD", nil, nil)
			Hardcore:ShowAlertFrame(ALERT_STYLES.hc_red, "Bubble-hearth Infraction\nContact a Mod immediately.")

			STARTED_BUBBLE_HEARTH_INFO = nil
		end
	end
end

function Hardcore:PLAYER_ENTERING_WORLD()
	-- cache player name
	PLAYER_NAME, _ = UnitName("player")
	Hardcore:PrintBubbleHearthInfractions()

	-- initialize addon communication
	if (not C_ChatInfo.IsAddonMessagePrefixRegistered(COMM_NAME)) then
		C_ChatInfo.RegisterAddonMessagePrefix(COMM_NAME)
	end

	-- Hook TargetFrame classification and warn if PvP enabled and enemy faction 
	hooksecurefunc("TargetFrame_CheckClassification",function(self, lock)
		if Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_BOTH_FACTIONS then
			if UnitIsPVP("target") and UnitGUID("target") ~= PLAYER_GUID then
				local faction, _ = UnitFactionGroup("target")
				if faction ~= nil then
					if faction ~= PLAYER_FACTION then
						local target_name, _ = UnitName("target")
						Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
					elseif UnitPlayerControlled("target") then
						local target_name, _ = UnitName("target")
						Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
					end
				end
			end
		elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_ENEMY_FACTION then
			if UnitGUID("target") ~= PLAYER_GUID and UnitIsPVP("target")  then
				local faction, _ = UnitFactionGroup("target")
				if faction ~= nil then
					if (faction ~= PLAYER_FACTION) then
						local target_name, _ = UnitName("target")
						Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
					end
				end
			end
		elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_SAME_FACTION then
			if UnitGUID("target") ~= PLAYER_GUID and UnitIsPVP("target")  then
				local faction, _ = UnitFactionGroup("target")
				if faction ~= nil then
					if faction == PLAYER_FACTION and UnitPlayerControlled("target") then
						local target_name, _ = UnitName("target")
						Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
					end
				end
			end
		end
	end);
end

function Hardcore:PLAYER_ALIVE()
	if #Hardcore_Character.deaths == 0 then
		return
	end

	if Hardcore_Character.deaths[#Hardcore_Character.deaths].player_alive_trigger == nil then
		Hardcore_Character.deaths[#Hardcore_Character.deaths].player_alive_trigger = date("%m/%d/%y %H:%M:%S")
	end
end

function Hardcore:PLAYER_DEAD()

	-- screenshot
	C_Timer.After(PICTURE_DELAY, Screenshot)

	-- Update deaths
	if #Hardcore_Character.deaths == 0 or (#Hardcore_Character.deaths > 0 and Hardcore_Character.deaths[#Hardcore_Character.deaths].player_alive_trigger ~= nil) then
		table.insert(Hardcore_Character.deaths, {
			player_dead_trigger = date("%m/%d/%y %H:%M:%S"),
			player_alive_trigger = nil
		})
	end

	-- Get information
	local playerId = UnitGUID("player")
	local playerName, realmName = UnitName("player")
	local localizedClass, englishClass = UnitClass("player")
	local playerLevel = UnitLevel("player")
	local mapId = C_Map.GetBestMapForUnit("player")
	local mapName = C_Map.GetMapInfo(mapId).name
	local playerGreet = GENDER_GREETING[UnitSex("player")]

	-- Send message to guild
	local messageFormat = "Our brave %s, %s the %s, has died at level %d in %s"
	local messageString = string.format(messageFormat, playerGreet, playerName, localizedClass, playerLevel, mapName)
	if not (Last_Attack_Source == nil) then
		messageString = string.format("%s to a %s", messageString, Last_Attack_Source)
		Last_Attack_Source = nil
	end
	SendChatMessage(messageString, "GUILD", nil, nil)

	-- Send add command to addon for this death
	local deathData = string.format("%s%s%s%s%s%s%s%s%s%s%s", playerId, COMM_FIELD_DELIM, playerName, COMM_FIELD_DELIM,
		localizedClass, COMM_FIELD_DELIM, playerLevel, COMM_FIELD_DELIM, mapId, COMM_FIELD_DELIM, time())

	local commMessage = COMM_COMMANDS[2] .. COMM_COMMAND_DELIM .. deathData
	if CTL then
		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
	end
end

function Hardcore:PLAYER_UNGHOST()
	if UnitIsDeadOrGhost("player") == 1 then
		return
	end -- prevent message on ghost login or zone

	local playerName, _ = UnitName("player")
	local message = playerName .. " has resurrected!"
	SendChatMessage(message, "GUILD", nil, nil)

	Hardcore:ShowAlertFrame(ALERT_STYLES.spirithealer, message)
end

function Hardcore:MAIL_SHOW()
	Hardcore:Print("Hardcore mode is enabled, mailbox access is blocked.")
	CloseMail()
end

function Hardcore:AUCTION_HOUSE_SHOW()
	Hardcore:Print("Hardcore mode is enabled, auction house access is blocked.")
	CloseAuctionHouse()
end

function Hardcore:PLAYER_LEVEL_UP(...)
	-- store the recent level up to use in TIME_PLAYED_MSG
	local level, healthDelta, powerDelta, numNewTalents, numNewPvpTalentSlots, strengthDelta, agilityDelta,
		staminaDelta, intellectDelta = ...
	recent_levelup = level

	-- just in case... make sure recent level up gets reset after 3 secs
	C_Timer.After(3, function()
		recent_levelup = nil
	end)

	-- get time played, see TIME_PLAYED_MSG
	RequestTimePlayed()

	-- take screenshot (got this idea from DingPics addon)
	-- wait a bit so the yellow animation appears
	C_Timer.After(PICTURE_DELAY, Screenshot)
end

function Hardcore:TIME_PLAYED_MSG(...)
	local totalTimePlayed, _ = ...
	Hardcore_Character.time_played = totalTimePlayed

	-- Check to see if the gap since the last recording is too long.  When receiving played time for the first time.
	if RECEIVED_FIRST_PLAYED_TIME_MSG == false and Hardcore_Character.accumulated_time_diff ~= nil then

		-- Check playtime gap percentage
		if Hardcore_Character.time_played ~= 0 then
			Hardcore_Character.tracked_played_percentage = Hardcore_Character.time_tracked /
																 Hardcore_Character.time_played * 100.0
		else
			Hardcore_Character.tracked_played_percentage = 100.0
		end

		local debug_message = "Playtime gap percentage: " .. Hardcore_Character.tracked_played_percentage .. "%."
		Hardcore:Debug(debug_message)

		-- Only warn user about playtime percentage if percentage is low enough and enough playtime is logged.
		if Hardcore_Character.tracked_played_percentage < PLAYED_TIME_PERC_THRESH and Hardcore_Character.time_played >
			PLAYED_TIME_MIN_PLAYED_THRESH then
			local message =
				"\124cffFF0000Detected that the player's addon active time is much lower than played time. Please record the rest of your run."
			Hardcore:Print(message)
		end

		-- Check playtime gap since last session
		local duration_since_last_recording = Hardcore_Character.time_played - Hardcore_Character.time_tracked -
													Hardcore_Character.accumulated_time_diff
		debug_message = "Playtime gap duration: " .. duration_since_last_recording .. " seconds."
		Hardcore:Debug(debug_message)

		if duration_since_last_recording > PLAYED_TIME_GAP_THRESH then
			local played_time_gap_info = {}
			played_time_gap_info.duration_since_last_recording = duration_since_last_recording
			played_time_gap_info.date = date("%m/%d/%y %H:%M:%S")
			if Hardcore_Character.played_time_gap_warnings == nil then
				Hardcore_Character.played_time_gap_warnings = {}
				Hardcore_Character.played_time_gap_warnings[1] = played_time_gap_info
			else
				table.insert(Hardcore_Character.played_time_gap_warnings, played_time_gap_info)
			end
			local message = "\124cffFF0000Addon/Playtime gap detected at date" ..
								Hardcore_Character.played_time_gap_warnings[#Hardcore_Character.played_time_gap_warnings]
									.date .. " with a duration: " ..
								Hardcore_Character.played_time_gap_warnings[#Hardcore_Character.played_time_gap_warnings]
									.duration_since_last_recording .. " seconds."
			Hardcore:Print(message)
		end
	end

	RECEIVED_FIRST_PLAYED_TIME_MSG = true

	if recent_levelup ~= nil then
		-- cache this to make sure it doesn't disapeer
		local recent = recent_levelup
		-- nil this to ensure it's not called twice
		recent_levelup = nil

		-- make sure list is initialized
		if Hardcore_Settings.level_list == nil then
			Hardcore_Settings.level_list = {}
		end

		-- info for level up record
		local totalTimePlayed, timePlayedThisLevel = ...
		local playerName, _ = UnitName("player")

		-- create the record
		local mylevelup = {}
		mylevelup["level"] = recent
		mylevelup["playedtime"] = totalTimePlayed
		mylevelup["realm"] = GetRealmName()
		mylevelup["player"] = playerName
		mylevelup["localtime"] = date()

		-- clear existing records if someone deleted / remade character
		-- since this is level 2, this must be a brand new character
		if recent == 2 then
			for i, v in ipairs(Hardcore_Settings.level_list) do
				-- find previous records with same name / realm and rename them so we don't misidentify them
				if v["realm"] == mylevelup["realm"] and v["player"] == mylevelup["player"] then
					-- copy the record and rename it
					local renamed = v
					renamed["player"] = renamed["player"] .. "-old"
					Hardcore_Settings.level_list[i] = renamed
				end
			end
		end

		-- if we found previous level, show the last level time
		for i, v in ipairs(Hardcore_Settings.level_list) do
			-- find last level up
			if v["realm"] == mylevelup["realm"] and v["player"] == mylevelup["player"] and v["level"] == recent - 1 then
				-- show message to user with calculated time between levels
				Hardcore:Print("Level " .. (recent - 1) .. "-" .. recent .. " time played: " ..
									 SecondsToTime(totalTimePlayed - v["playedtime"]))
			end
		end

		-- store level record
		table.insert(Hardcore_Settings.level_list, mylevelup)
	end
end

local Cached_ChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
ChatFrame_DisplayTimePlayed = function(...)
	if HIDE_RTP_CHAT_MSG_BUFFER > 0 then
		HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER - 1
		return
	end
	return Cached_ChatFrame_DisplayTimePlayed(...)
end

function Hardcore:RequestTimePlayed()
	HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER + 1
	if HIDE_RTP_CHAT_MSG_BUFFER > HIDE_RTP_CHAT_MSG_BUFFER_MAX then
		HIDE_RTP_CHAT_MSG_BUFFER = HIDE_RTP_CHAT_MSG_BUFFER_MAX 
	end
	RequestTimePlayed()
end

function Hardcore:CHAT_MSG_ADDON(prefix, datastr, scope, sender)
	-- Ignore messages that are not ours
	if COMM_NAME == prefix then
		-- Get the command
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)

		-- Determine what command was sent
		if command == COMM_COMMANDS[2] then
			Hardcore:Add(data)
		elseif command == COMM_COMMANDS[1] then
			Hardcore:ReceivePulse(data, sender)
		else
			-- Hardcore:Debug("Unknown command :"..command)
		end
	end
end

function Hardcore:COMBAT_LOG_EVENT_UNFILTERED(...)
	-- local time, token, hidding, source_serial, source_name, caster_flags, caster_flags2, target_serial, target_name, target_flags, target_flags2, ability_id, ability_name, ability_type, extraSpellID, extraSpellName, extraSchool = CombatLogGetCurrentEventInfo()
	local _, ev, _, _, source_name, _, _, _, _, _, _, _, _, _, _, _, _ = CombatLogGetCurrentEventInfo()

	if not (source_name == PLAYER_NAME) then
		if not (source_name == nil) then
			if string.find(ev, "DAMAGE") ~= nil then
				Last_Attack_Source = source_name
			end
		end
	end
end

function Hardcore:GUILD_ROSTER_UPDATE(...)
	guild_roster_loading = false

	-- Create a new dictionary of just online people every time roster is updated
	guild_online = {}

	-- Hardcore:Debug('guild roster update')
	local numTotal, numOnline, numOnlineAndMobile = GetNumGuildMembers();
	for i = 1, numOnline, 1 do
		local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status,
			class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)

		-- name is nil after a gquit, so nil check here
		if name then
			guild_online[name] = {
				name = name,
				level = level,
				classDisplayName = classDisplayName
			}
		end
	end

	Hardcore:UpdateGuildRosterRows()
	if display == "AddonStatus" then
		Hardcore_SubTitle:SetText(STRING_ADDON_STATUS_SUBTITLE)
	end
end

--[[ Utility Methods ]]--

function Hardcore:Print(msg)
	print("|cffed9121Hardcore|r: " .. (msg or ""))
end

function Hardcore:Debug(msg)
	if true == debug then
		print("|cfffd9122HCDebug|r: " .. (msg or ""))
	end
end

-- Alert UI
function Hardcore:ShowAlertFrame(styleConfig, message)
	-- message is any text accepted by FontString:SetText(message)

	message = message or ""

	local data = styleConfig or ALERT_STYLES["hc_red"]
	local frame, text, icon, file, delay, alertSound = data.frame, data.text, data.icon, data.file, data.delay, data.alertSound

	filename = MEDIA_DIR .. file
	icon:SetTexture(filename)
	text:SetText(message)

	frame:Show()

	if alertSound then PlaySound(alertSound) end

	-- HACK:
	-- There's a bug here where a sequence of overlapping notifications share one 'hide' timer
	-- There should be a step here that unbinds all-but-the-last notification's Hide() callback
	C_Timer.After(delay, function()
		frame:Hide()
	end)
end

function Hardcore:Add(data)
	-- Add the record if needed
	if true == Hardcore:ValidateEntry(data) then
		Hardcore:Debug("Adding new record " .. data)

		-- Display the death locally
		local _, name, class_name, level, map_id, _ = string.split(COMM_FIELD_DELIM, data)
		local class_color = Hardcore:GetClassColorText(class_name)
		local map_name = C_Map.GetMapInfo(tonumber(map_id)).name
		local messageFormat = "%s the %s%s|r has died at level %d in %s"
		local messageString = string.format(messageFormat, name, class_color, class_name, level, map_name)

		Hardcore:ShowAlertFrame(ALERT_STYLES.death, messageString)
	end
end

function Hardcore:Levels(all)
	-- default parameter value
	if all == nil then
		all = false
	end

	if Hardcore_Settings.level_list ~= nil and #Hardcore_Settings.level_list > 0 then
		local playerName, _ = UnitName("player")
		local playerRealm = GetRealmName()
		local mylevels = {}

		-- find relevant records
		for i, v in ipairs(Hardcore_Settings.level_list) do
			-- find records from current character
			if v["realm"] == playerRealm and v["player"] == playerName then
				table.insert(mylevels, v)
			end

			-- find old records as well
			if all and (v["player"] == (playerName .. "-old")) then

				table.insert(mylevels, v)
			end
		end

		if #mylevels > 0 then
			-- for some reason this string concat doesn't work unless stored in variable
			-- local headerstr = "==== " .. playerName .. " ==== " .. playerRealm .. " ===="
			-- Hardcore:Print(headerstr)
			for i, v in ipairs(mylevels) do
				-- for all command show name to distinguish old and new records
				-- local nameheader = all and v["player"] .. " = " or ""
				-- print the level row
				Hardcore:Print("Levels:")
				Hardcore:Print(Hardcore:FormatRow(v), nil, "Levels")
				-- Hardcore:Print(nameheader .. v["level"] .. " = " .. SecondsToTime(v["playedtime"]) .. " = " .. v["localtime"])
			end
		else
			Hardcore:Print("No levels for " .. playerName)
		end
	else
		Hardcore:Print("No levels recorded")
	end
end

function Hardcore:FormatRow(row, fullcolor, formattype)
	local row_str = ""

	if row ~= nil then
		if formattype == "Levels" then
			row_str = string.format("%-17s%s%-10s|r%-10s%-25s%-s", row["player"], "", row["level"],
				SecondsToTime(row["playedtime"]), "", row["localtime"])
		elseif formattype == "Deaths" then
			-- this is a death row
			if Hardcore:ValidateEntry(row) then
				local _, name, classname, level, mapId, tod = string.split(COMM_FIELD_DELIM, row)
				local mapName = C_Map.GetMapInfo(mapId).name
				local color = Hardcore:GetClassColorText(classname)
				if fullcolor then
					row_str = string.format("%s%-17s%-10s%-10s%-25s%-s|r", color, name, classname, level, mapName,
						date("%Y-%m-%d %H:%M:%S", tod))
				else
					row_str = string.format("%-17s%s%-10s|r%-10s%-25s%-s", name, color, classname, level, mapName,
						date("%Y-%m-%d %H:%M:%S", tod))
				end
			end
		elseif formattype == "AddonStatus" then
			if row.name == nil then
				row_str = row
			else
				local FULL_PLAYER_NAME = Hardcore_GetPlayerPlusRealmName()
				local statusText
				local color

				-- Player has sent an addon pulse and is online... or its you
				if (online_pulsing[row.name] and guild_online[row.name]) or row.name == FULL_PLAYER_NAME then

					local version

					if row.name == FULL_PLAYER_NAME then
						version = GetAddOnMetadata('Hardcore', 'Version')
					else
						version = guild_versions[row.name]
					end

					if guild_versions_status[row.name] == 'updated' then
						color = COLOR_GREEN
					else
						color = COLOR_YELLOW
					end

					statusText = 'HC Addon: Detected (' .. version .. ')'
				else
					statusText = 'HC Addon: Not Detected'
					color = COLOR_RED
				end

				row_str = string.format("%sLv: %s %s (%s)", color, row.level, row.name, statusText)
			end

		elseif formattype == "Rules" then
			row_str = row
		elseif formattype == "GetVerified" then
			row_str = row
		end
	end

	return row_str
end

function Hardcore:GetValue(row, value)
	local playerid, name, classname, level, mapid, tod = string.split(COMM_FIELD_DELIM, row)
	if "playerid" == value then
		return playerid
	elseif "class" == value then
		return classname
	elseif "name" == value then
		return name
	elseif "level" == value then
		return level
	elseif "zone" == value then
		return mapid
	elseif "tod" == value then
		return tod
	else
		-- Default to returning everything
		return playerid, name, classname, level, mapid, tod
	end

	return nil
end

function Hardcore:GetClassColorText(classname)
	if "Druid" == classname then
		return "|c00ff7d0a"
	elseif "Hunter" == classname then
		return "|c00a9d271"
	elseif "Mage" == classname then
		return "|c0040c7eb"
	elseif "Paladin" == classname then
		return "|c00f58cba"
	elseif "Priest" == classname then
		return "|c00ffffff"
	elseif "Rogue" == classname then
		return "|c00fff569"
	elseif "Shaman" == classname then
		return "|c000070de"
	elseif "Warlock" == classname then
		return "|c008787ed"
	elseif "Warrior" == classname then
		return "|c00c79c6e"
	end

	Hardcore:Debug("ERROR: classname not found")
	return "|c00c41f3b" -- Red
end

function Hardcore:ValidateEntry(data)
	local playerId, name, classname, level, mapId, tod = string.split(COMM_FIELD_DELIM, data)

	if nil == playerId then
		Hardcore:Debug("ERROR: 'playerId' field is nil")
		return false
	end

	if nil == name then
		Hardcore:Debug("ERROR: 'name' field is nil")
		return false
	end

	if nil == classname then
		Hardcore:Debug("ERROR: 'class' field is nil")
		return false
	end

	if nil == level then
		Hardcore:Debug("ERROR: 'level' field is nil")
		return false
	elseif 1 == tonumber(level) then
		Hardcore:Debug("WARN: Ignoring level 1 death")
		return false
	end

	if nil == mapId then
		Hardcore:Debug("ERROR: 'mapId' field is nil")
		return false
	end

	if nil == tod then
		Hardcore:Debug("ERROR: 'tod' field is nil")
		return false
	end

	return true
end

--[[ UI Methods ]]--

-- switch between displays
function Hardcore:SwitchDisplay(displayparam)

	if displayparam ~= nil then
		display = displayparam
	end

	-- refresh the page
	Hardcore_Frame_OnShow()
end

function Hardcore_SortByLevel(pipe1, pipe2)
	return pipe1.level < pipe2.level
end

function Hardcore_Frame_OnShow()
	Hardcore:Debug('display: ' .. display)
	-- refresh data source
	if display == "Levels" then
		displaylist = Hardcore_Settings.level_list
		Hardcore_Name_Sort:Show()
		Hardcore_Class_Sort:Show()
		Hardcore_Level_Sort:Show()
		Hardcore_Zone_Sort:Show()
		Hardcore_TOD_Sort:Show()
	elseif display == "GetVerified" then
		-- hide buttons 
		Hardcore_Name_Sort:Hide()
		Hardcore_Class_Sort:Hide()
		Hardcore_Level_Sort:Hide()
		Hardcore_Zone_Sort:Hide()
		Hardcore_TOD_Sort:Hide()
		DeathListEntry3:Hide()

		local verificationstring = Hardcore:GenerateVerificationString()
		local f = {}
		table.insert(f, "To get verified, copy the string below and visit the classichc website.")
		table.insert(f, "")
		table.insert(f, verificationstring)
		displaylist = f
	elseif display == "AddonStatus" then

		-- handles loading and loading state
		Hardcore:FetchGuildRoster()
		Hardcore:UpdateGuildRosterRows()

	elseif display == "Rules" then
		-- hide buttons 
		Hardcore_Name_Sort:Hide()
		Hardcore_Class_Sort:Hide()
		Hardcore_Level_Sort:Hide()
		Hardcore_Zone_Sort:Hide()
		Hardcore_TOD_Sort:Hide()

		-- hard coded rules table lol
		local f = {}
		table.insert(f, "For more info, rules, news, hall of legends, challenges, and more\n")
		table.insert(f, "visit the classichc website.")
		table.insert(f, "Help is available on discord (link on website)")
		table.insert(f, "")
		table.insert(f, "All professions allowed")
		table.insert(f, "No restriction on talents")
		table.insert(f, "")
		table.insert(f, "You can use gear that you pickup or craft")
		table.insert(f, "No Auction house, No mailbox, No trading")
		table.insert(f, "")
		table.insert(f, "No grouping in open world")
		table.insert(f, "")
		table.insert(f, "Buffs from others are allowed, don't ask for others for buffs")
		table.insert(f, "")
		table.insert(f, "Dungeon Groups are authorized but only ONE run of each Dungeon per character")
		table.insert(f, "Everyone in party must be following hardcore rules")
		table.insert(f, "Everyone must be in level range of the meeting stone.")
		table.insert(f, "Group at the meeting stone to start the dungeon.")
		table.insert(f, "You can invite people who are on the way.")
		table.insert(f, "")
		table.insert(f, "If you level up inside of the dungeon and exceed the meeting stone requirement you can stay")
		table.insert(f, "Warlocks are allowed to summon players to the meeting stone")
		table.insert(f, "")
		table.insert(f, "Warlocks can’t resurrect via SS")
		table.insert(f, "Shamans can’t resurrect via Ankh")
		table.insert(f, "Paladins can’t Bubble Hearth")
		table.insert(f, "No Light of Elune + Hearthstone")
		table.insert(f, "")
		table.insert(f, "You need a record your journey to be verified")
		table.insert(f, "Stream or record and upload to youtube or twitch")
		table.insert(f, "then submit the playlist of your run on the verification page")
		table.insert(f, "")
		table.insert(f,
			"At 60 you earn your IMMORTALITY and become a full fledged character with insane bragging rights ")
		table.insert(f, "")
		table.insert(f, "")
		table.insert(f, "=============== DUOS ===============")
		table.insert(f, "")
		table.insert(f, "You must not leave the same zone as each other")
		table.insert(f, "*unless you are a Druid going to Moonglade to complete essential class quests")
		table.insert(f, "You must choose a combo that spawns in the same starting location.")
		table.insert(f, "")
		table.insert(f, "If one of you dies, the other must fall on the sword and the run is over.")
		table.insert(f, "")
		table.insert(f, "You can trade your duo partner found or crafted items, including gold")
		table.insert(f, "")
		table.insert(f, "Multiboxing goes against the spirit of the Hardcore Challenge and is not allowed")
		table.insert(f, "")
		displaylist = f
	end

	if display ~= "GetVerified" then
		Hardcore_VerificationString:Hide()
	end

	-- subtitle text
	if display == "Levels" and #displaylist > 0 then
		Hardcore_SubTitle:SetText("You've leveled up " .. tostring(#displaylist) .. " times!")
	elseif display == "AddonStatus" and guild_roster_loading then
		Hardcore_SubTitle:SetText(STRING_ADDON_STATUS_SUBTITLE_LOADING)
	else
		Hardcore_SubTitle:SetText("DEATH = DELETE")
	end

	Hardcore_Deathlist_ScrollBar_Update()

end

function Hardcore_Deathlist_ScrollBar_Update()
	-- max value
	if not (displaylist == nil) then
		FauxScrollFrame_Update(MyModScrollBar, #displaylist, 20, 16)

		-- loop through lines adding data
		for line = 1, 20 do
			local lineplusoffset = line + FauxScrollFrame_GetOffset(MyModScrollBar)
			local button = getglobal("DeathListEntry" .. line)
			if lineplusoffset <= #displaylist then
				-- get data
				local row = Hardcore:FormatRow(displaylist[lineplusoffset], true, display)
				if row then
					-- Hacky way to display the verification string in a EditBox
					-- Currently the UI is a table that gets rendered to a list of buttons
					-- Requires a big refactor to fix
					if display == "GetVerified" and line == 3 then
						Hardcore_VerificationString:SetText(row)
						Hardcore_VerificationString:Show()
					else
						button:SetText(row)
						button:Show()
					end
				else
					button:Hide()
				end
			else
				button:Hide()
			end
		end
	end
end

function Hardcore:RecordReminder()
	if Hardcore_Settings.notify == false then
		return
	end

	Hardcore:ShowAlertFrame(ALERT_STYLES.hc_enabled, "Character Activity is Being Monitored")

end

----------------------------------------------------------------------
-- Minimap button (no reload required)
----------------------------------------------------------------------

function Hardcore:initMinimapButton()

	-- Minimap button click function
	local function MiniBtnClickFunc(arg1)

		-- Prevent options panel from showing if Blizzard options panel is showing
		if InterfaceOptionsFrame:IsShown() or VideoOptionsFrame:IsShown() or ChatConfigFrame:IsShown() then
			return
		end
		-- Prevent options panel from showing if Blizzard Store is showing
		if StoreFrame and StoreFrame:GetAttribute("isshown") then
			return
		end
		-- Left button down
		if arg1 == "LeftButton" then

			-- Control key 
			if IsControlKeyDown() and not IsShiftKeyDown() then
				Hardcore:ToggleMinimapIcon()
				return
			end

			-- Shift key and control key 
			if IsShiftKeyDown() and IsControlKeyDown() then
				return
			end

			-- No modifier key toggles the options panel
			if Hardcore_Frame:IsShown() then
				Hardcore_Frame:Hide()
			else
				Hardcore_Frame:Show()
			end
		end
	end

	-- Create minimap button using LibDBIcon
	local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("Hardcore", {
		type = "data source",
		text = "Hardcore",
		icon = "Interface\\AddOns\\Hardcore\\Media\\logo-emblem.blp",
		OnClick = function(self, btn)
			MiniBtnClickFunc(btn)
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Hardcore")
			tooltip:AddLine("|cFFCFCFCFclick|r show window")
			tooltip:AddLine("|cFFCFCFCFctrl click|r toggle minimap button")
		end
	})

	icon = LibStub("LibDBIcon-1.0", true)
	icon:Register("Hardcore", miniButton, Hardcore_Settings)

	-- -- Function to toggle LibDBIcon
	-- function SetLibDBIconFunc()
	-- 	if Hardcore_Settings["hide"] == nil or Hardcore_Settings["hide"] == true then
	-- 		Hardcore_Settings["hide"] = false
	-- 		icon:Show("Hardcore")
	-- 	else
	-- 		Hardcore_Settings["hide"] = true
	-- 		icon:Hide("Hardcore")
	-- 	end
	-- end

	if (Hardcore_Settings["hide"] == false) then
		icon:Show("Hardcore")
	end

	-- -- Set LibDBIcon when option is clicked and on startup
	-- SetLibDBIconFunc()
end

function Hardcore:ToggleMinimapIcon()
	if icon then

		if Hardcore_Settings["hide"] == nil or Hardcore_Settings["hide"] == true then
			Hardcore_Settings["hide"] = false
			icon:Show("Hardcore")
		else
			Hardcore_Settings["hide"] = true
			icon:Hide("Hardcore")
		end
	end
end

function Hardcore:PrintBubbleHearthInfractions()
	if Hardcore_Character.bubble_hearth_incidents ~= nil then
		for i, v in ipairs(Hardcore_Character.bubble_hearth_incidents) do
			if v.guid == PLAYER_GUID then
				message = "\124cffFF0000Player has a " .. v.aura_type .. " hearth infraction at date " .. v.start_cast
				Hardcore:Print(message)
			end
		end
	end
end

local ATTRIBUTE_SEPARATOR = "_"
function Hardcore:GenerateVerificationString()
	local _, class, _, race, _, name = GetPlayerInfoByGUID(UnitGUID("player"))
	local realm = GetRealmName()
	local level = UnitLevel("player")

	local tradePartners = Hardcore_join(Hardcore_Character.trade_partners, ",")
	local baseVerificationData = {Hardcore_Character.guid, realm, race, class, name, level,
									Hardcore_Character.time_played, Hardcore_Character.time_tracked,
									#Hardcore_Character.deaths, tradePartners}
	local baseVerificationString = Hardcore_join(Hardcore_map(baseVerificationData, Hardcore_stringOrNumberToUnicode),
		ATTRIBUTE_SEPARATOR)
	local bubbleHearthIncidentsVerificationString = Hardcore_tableToUnicode(Hardcore_Character.bubble_hearth_incidents)
	local playedtimeGapsVerificationString = Hardcore_tableToUnicode(Hardcore_Character.played_time_gap_warnings)

	return Hardcore_join({baseVerificationString, bubbleHearthIncidentsVerificationString,
							playedtimeGapsVerificationString}, ATTRIBUTE_SEPARATOR)
end

--[[ Timers ]]--
function Hardcore:InitiatePulse()
	-- Set send pulses ticker
	C_Timer.NewTicker(COMM_PULSE_FREQUENCY, function()
		local isInGuild = GetGuildInfo("player")
		if CTL and isInGuild then
			-- Send along the version we're using
			local version = GetAddOnMetadata("Hardcore", "Version")
			local commMessage = COMM_COMMANDS[1] .. COMM_COMMAND_DELIM .. version
			CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")
		end
	end)
end

function Hardcore:InitiatePulseCheck()
	C_Timer.NewTicker(COMM_PULSE_CHECK_FREQUENCY, function()
		if Hardcore_Frame:IsShown() and display == "AddonStatus" then
			Hardcore:FetchGuildRoster()
		end

		-- Hardcore:Debug('Checking pulses now')
		online_pulsing = {}

		for player, status in pairs(guild_online) do
			local pulsetime = pulses[player]

			if not pulsetime or ((time() - pulsetime) > COMM_PULSE_CHECK_FREQUENCY) then
				online_pulsing[player] = false
			else
				online_pulsing[player] = true
			end
		end
	end)
end

function Hardcore:ReceivePulse(data, sender)
	local FULL_PLAYER_NAME = Hardcore_GetPlayerPlusRealmName()

	if sender == FULL_PLAYER_NAME then
		return
	end

	-- Hardcore:Debug('Received pulse from: '..sender..'. data: '..data)

	Hardcore:CheckVersionsAndUpdate(sender, data)

	-- Set my versions
	local version = GetAddOnMetadata("Hardcore", "Version")
	if version ~= guild_highest_version then
		guild_versions_status[FULL_PLAYER_NAME] = 'outdated'
	end

	pulses[sender] = time()
end

function Hardcore:CheckVersionsAndUpdate(playername, versionstring)

	if guild_highest_version == nil then
		guild_highest_version = GetAddOnMetadata('Hardcore', 'Version')
	end

	-- Hardcore:Debug('Comparing: data: '..versionstring.. ' to guild_highest_version: '..guild_highest_version)
	if versionstring ~= guild_highest_version then

		local greaterVersion = Hardcore_GetGreaterVersion(versionstring, guild_highest_version)
		-- Hardcore:Debug('higest is: '..greaterVersion)

		-- if received pulse is newer version, update the local, highest version
		if guild_highest_version ~= greaterVersion then
			-- Hardcore:Debug('setting higestversion to: '..greaterVersion)

			guild_highest_version = greaterVersion
			-- invalidate status table
			guild_versions_status = {}
			guild_versions_status[playername] = 'updated'

		else -- if received pulse is older version, set sender to outdated
			-- Hardcore:Debug('setting sender to: outdated')
			guild_versions_status[playername] = 'outdated'
		end
	else -- if received pulse has same version, set to updated
		guild_versions_status[playername] = 'updated'
	end

	guild_versions[playername] = versionstring
end

function Hardcore:UpdateGuildRosterRows()
	if display == "AddonStatus" then
		local f = {}
		for name, playerData in pairs(guild_online) do
			table.insert(f, playerData)
		end
		table.sort(f, Hardcore_SortByLevel)
		displaylist = f

		Hardcore_Deathlist_ScrollBar_Update()
	end
end

function Hardcore:FetchGuildRoster()
	guild_roster_loading = true
	local num_ellipsis = 4

	-- Request a new roster update when we show the addonstatus list
	SetGuildRosterShowOffline(false)
	requestGuildRoster = C_Timer.NewTicker(2, function()
		if guild_roster_loading then

			if display == "AddonStatus" then
				Hardcore_SubTitle:SetText(STRING_ADDON_STATUS_SUBTITLE_LOADING)
			end
			GuildRoster()
		else
			requestGuildRoster:Cancel()
		end
	end)
end

function Hardcore:HandleLegacyDeaths()
	if type(Hardcore_Character.deaths) == "number" then
		local deathcount = Hardcore_Character.deaths
		Hardcore_Character.deaths = {}
		for i = 1, deathcount do
			table.insert(Hardcore_Character.deaths, {
				player_dead_trigger = date("%m/%d/%y %H:%M:%S"),
				player_alive_trigger = date("%m/%d/%y %H:%M:%S")
			})
		end
	end
end

--[[ Timers ]]--
local PLAY_TIME_UPDATE_INTERVAL = 1
C_Timer.NewTicker(PLAY_TIME_UPDATE_INTERVAL, function()
	Hardcore_Character.time_tracked = Hardcore_Character.time_tracked + PLAY_TIME_UPDATE_INTERVAL
	Hardcore:RequestTimePlayed()
	if RECEIVED_FIRST_PLAYED_TIME_MSG == true then
		Hardcore_Character.accumulated_time_diff = Hardcore_Character.time_played - Hardcore_Character.time_tracked
	end
end)

--[[ Start Addon ]]--
Hardcore:Startup()

