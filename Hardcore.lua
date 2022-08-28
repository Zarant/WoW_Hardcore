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

--[[ Const variables ]]
--
local GRIEF_WARNING_OFF = 0
local GRIEF_WARNING_SAME_FACTION = 1
local GRIEF_WARNING_ENEMY_FACTION = 2
local GRIEF_WARNING_BOTH_FACTIONS = 3
local CLASSES = {
	-- Classic:
	[1] = "Warrior",
	[2] = "Paladin",
	[3] = "Hunter",
	[4] = "Rogue",
	[5] = "Priest",
	[6] = "Death Knight", -- new Death Knight ID
	[7] = "Shaman",
	[8] = "Mage",
	[9] = "Warlock",
	[11] = "Druid",
}

--[[ Global saved variables ]]
--
Hardcore_Settings = {
	level_list = {},
	notify = true,
	debug_log = {},
	monitor = false,
	filter_f_in_chat = false,
	show_version_in_chat = false,
	alert_frame_x_offset = 0,
	alert_frame_y_offset = -150,
	alert_frame_scale = 0.7,
	show_minimap_mailbox_icon = false,
	sacrifice = {},
	hardcore_player_name = "",
}

--[[ Character saved variables ]]
--
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
	achievements = {},
	party_mode = "Solo",
	team = {},
	first_recorded = -1,
	sacrificed_at = "",
	converted_successfully = false,
	converted_time = "",
	game_version = "",
	hardcore_player_name = "",
}

--[[ Local variables ]]
--
local debug = false
local loaded_inspect_frame = false
local pulses = {}
local alert_msg_time = {
	PULSE = {},
	ADD = {},
	DEAD = {},
}
local monitor_msg_throttle = {
	PULSE = {},
	ADD = {},
	DEAD = {},
}
local online_pulsing = {}
local guild_versions = {}
local guild_versions_status = {}
local guild_online = {}
local guild_highest_version = "0.0.0"
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
local COMM_SUBFIELD_DELIM = "~"
local COMM_RECORD_DELIM = "^"
local COMM_COMMANDS = {
	"PULSE",
	"ADD", -- depreciated, we can only handle receiving
	"DEAD", -- new death command
	"CHARACTER_INFO", -- new death command
	"REQUEST_CHARACTER_INFO", -- new death command
	"SACRIFICE", -- new sacrifice command
	"REQUEST_PCT", -- request a party change token
	"APPLY_PCT", -- request a party change
}
local COMM_SPAM_THRESHOLD = { -- msgs received within durations (s) are flagged as spam
	PULSE = 3,
	ADD = 180,
	DEAD = 180,
}
local DEPRECATED_COMMANDS = {
	UPDATE = 1,
	SYNC = 1,
}

-- stuff
local PLAYER_NAME, _ = nil
local PLAYER_GUID = nil
local PLAYER_FACTION = nil
local GENDER_GREETING = { "guildmate", "brother", "sister" }
local GENDER_POSSESSIVE_PRONOUN = { "Their", "His", "Her" }
local recent_levelup = nil
local recent_msg = {}
local Last_Attack_Source = nil
local PICTURE_DELAY = 0.65
local HIDE_RTP_CHAT_MSG_BUFFER = 0 -- number of messages in queue
local HIDE_RTP_CHAT_MSG_BUFFER_MAX = 2 -- number of maximum messages to wait for
local STARTED_BUBBLE_HEARTH_INFO = nil
local RECEIVED_FIRST_PLAYED_TIME_MSG = false
local PLAYED_TIME_GAP_THRESH = 600 -- seconds
local PLAYED_TIME_PERC_THRESH = 98 -- [0, 100] (2 minutes every 2 hours)
local PLAYED_TIME_MIN_PLAYED_THRESH = 7200 -- seconds (2 hours)
local TIME_TRACK_PULSE = 1
local TIME_PLAYED_PULSE = 60
local COLOR_RED = "|c00ff0000"
local COLOR_GREEN = "|c0000ff00"
local COLOR_YELLOW = "|c00ffff00"
local STRING_ADDON_STATUS_SUBTITLE = "Guild Addon Status"
local STRING_ADDON_STATUS_SUBTITLE_LOADING = "Guild Addon Status (Loading)"
local THROTTLE_DURATION = 5
local SACRIFICE_LEVEL_MIN = 55
local SACRIFICE_LEVEL_MAX = 58

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
		alertSound = 8959,
	},
	death = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-death.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	hc_green = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-green.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	hc_red = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	spirithealer = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-spirithealer.blp",
		delay = COMM_DELAY,
		alertSound = 8959,
	},
	bubble = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 8,
		alertSound = 8959,
	},
	hc_enabled = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 10,
		alertSound = nil,
	},
	hc_pvp_warning = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "hc-pvp-alert.blp",
		delay = 10,
		alertSound = 8192,
	},
	videre_warning = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 10,
		alertSound = 8959,
	},
	hc_sample = {
		frame = Hardcore_Alert_Frame,
		text = Hardcore_Alert_Text,
		icon = Hardcore_Alert_Icon,
		file = "alert-hc-red.blp",
		delay = 30,
		alertSound = 8959,
	},
}
Hardcore_Alert_Frame:SetScale(0.7)

-- the big frame object for our addon
local Hardcore = CreateFrame("Frame", "Hardcore", nil, "BackdropTemplate")
Hardcore.ALERT_STYLES = ALERT_STYLES

Hardcore_Frame:ApplyBackdrop()

function FailureFunction(achievement_name)
	for i, v in ipairs(Hardcore_Character.achievements) do
		if v == achievement_name then
			table.remove(Hardcore_Character.achievements, i)
			_G.achievements[achievement_name]:Unregister()
			Hardcore:Print("Failed " .. achievement_name)
			PlaySoundFile("Interface\\Addons\\Hardcore\\Media\\achievement_failure.ogg")
		end
	end
end

local failure_function_executor = { Fail = FailureFunction }

--[[ Command line handler ]]
--

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
	elseif cmd == "alerts" then
		Hardcore_Toggle_Alerts()
		if Hardcore_Settings.notify then
			Hardcore:Print("Alerts enabled.")
		else
			Hardcore:Print("Alerts disabled.")
		end
	elseif cmd == "monitor" then
		Hardcore_Settings.monitor = not Hardcore_Settings.monitor
		if Hardcore_Settings.monitor then
			Hardcore:Monitor("Monitoring malicious users enabled.")
		else
			Hardcore:Print("Monitoring malicious users disabled.")
		end
	elseif cmd == "quitachievement" then
		local achievement_to_quit = ""
		for substring in args:gmatch("%S+") do
			achievement_to_quit = substring
		end
		if _G.achievements ~= nil and _G.achievements[achievement_to_quit] ~= nil then
			for i, achievement in ipairs(Hardcore_Character.achievements) do
				if achievement == achievement_to_quit then
					Hardcore:Print("Successfuly quit " .. achievement .. ".")
					failure_function_executor.Fail(achievement)
				end
			end
		end
	elseif cmd == "dk" then
		-- sacrifice your current lvl 55 char to allow for making DK
		local dk_convert_option = ""
		for substring in args:gmatch("%S+") do
			dk_convert_option = substring
		end
		Hardcore:DKConvert(dk_convert_option)
	elseif cmd == "griefalert" then
		local grief_alert_option = ""
		for substring in args:gmatch("%S+") do
			grief_alert_option = substring
		end
		Hardcore:SetGriefAlertCondition(grief_alert_option)
	-- Alert debug code
	elseif cmd == "alert" and debug == true then
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
		Hardcore:Print("|cff00ff00Commands:|r show hide levels alllevels alerts monitor griefalert dk")
	end
end

SLASH_HARDCORE1, SLASH_HARDCORE2 = "/hardcore", "/hc"
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
	{ key = "grief_warning_conditions", initial_data = GRIEF_WARNING_BOTH_FACTIONS },
	{ key = "achievements", initial_data = {} },
	{ key = "party_mode", initial_data = "Solo" },
	{ key = "team", initial_data = {} },
	{ key = "first_recorded", initial_data = -1 },
	{ key = "grief_warning_conditions", initial_data = GRIEF_WARNING_BOTH_FACTIONS },
	{ key = "sacrificed_at", initial_data = "" },
	{ key = "converted_successfully", initial_data = false },
	{ key = "converted_time", initial_data = "" },
	{ key = "game_version", initial_data = "" },
	{ key = "hardcore_player_name", initial_data = "" },
}

--[[ Post-utility functions]]
--

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

--[[ Override default WoW UI ]]
--

TradeFrameTradeButton:SetScript("OnClick", function()
	table.insert(Hardcore_Character.trade_partners, TradeFrameRecipientNameText:GetText())
	Hardcore_Character.trade_partners = Hardcore_FilterUnique(Hardcore_Character.trade_partners)
	AcceptTrade()
end)

--[[ Startup ]]
--

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

--[[ Events ]]
--

function Hardcore:PLAYER_LOGIN()
	Hardcore:HandleLegacyDeaths()
	Hardcore_Character.hardcore_player_name = Hardcore_Settings.hardcore_player_name or ""

	-- Show the first menu screen.  Requires short delay
	if UnitLevel("player") < 2 then
		C_Timer.After(1.0, function()
			ShowFirstMenu(Hardcore_Character, Hardcore_Settings, failure_function_executor)
			Hardcore_Character.first_recorded = GetServerTime()
		end)
	end

	-- cache player data
	_, class, _ = UnitClass("player")
	PLAYER_NAME, _ = UnitName("player")
	PLAYER_GUID = UnitGUID("player")
	PLAYER_FACTION, _ = UnitFactionGroup("player")
	local PLAYER_LEVEL = UnitLevel("player")
	Hardcore:ApplyAlertFrameSettings()

	-- Register achievements
	if Hardcore_Character.achievements == nil then
		Hardcore_Character.achievements = {}
	end
	_G["HardcoreCharacterTab"]:SetScript("OnClick", function(self, arg1)
		PanelTemplates_SetTab(CharacterFrame, 6)
		if _G["HonorFrame"] ~= nil then
			_G["HonorFrame"]:Hide()
		end
		if _G["PaperDollFrame"] ~= nil then
			_G["PaperDollFrame"]:Hide()
		end
		if _G["PetPaperDollFrame"] ~= nil then
			_G["PetPaperDollFrame"]:Hide()
		end
		if _G["HonorFrame"] ~= nil then
			_G["HonorFrame"]:Hide()
		end
		if _G["SkillFrame"] ~= nil then
			_G["SkillFrame"]:Hide()
		end
		if _G["ReputationFrame"] ~= nil then
			_G["ReputationFrame"]:Hide()
		end
		ShowCharacterHC(Hardcore_Character)
	end)

	-- Adds HC character tab functionality
	hooksecurefunc("CharacterFrameTab_OnClick", function(self, button)
		local name = self:GetName()
		if name == "CharacterFrameTab6" then
			if _G["HonorFrame"] ~= nil then
				_G["HonorFrame"]:Hide()
			end
			if _G["PaperDollFrame"] ~= nil then
				_G["PaperDollFrame"]:Hide()
			end
			if _G["PetPaperDollFrame"] ~= nil then
				_G["PetPaperDollFrame"]:Hide()
			end
			if _G["HonorFrame"] ~= nil then
				_G["HonorFrame"]:Hide()
			end
			if _G["SkillFrame"] ~= nil then
				_G["SkillFrame"]:Hide()
			end
			if _G["ReputationFrame"] ~= nil then
				_G["ReputationFrame"]:Hide()
			end
			ShowCharacterHC(Hardcore_Character)
		elseif
			(name == "InspectFrameTab3" and _G["HardcoreBuildLabel"] ~= "WotLK")
			or (name == "InspectFrameTab4" and _G["HardcoreBuildLabel"] == "WotLK")
		then -- 3: era, 4:wotlk
			return
		else
			HideCharacterHC()
		end
	end)

	hooksecurefunc("CharacterFrame_ShowSubFrame", function(self, frameName)
		if name ~= "CharacterFrameTab6" then
			HideCharacterHC()
		end
	end)

	-- fires on first loading
	self:RegisterEvent("PLAYER_UNGHOST")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("TIME_PLAYED_MSG")
	self:RegisterEvent("QUEST_ACCEPTED") -- For Videre Elixir quest.
	self:RegisterEvent("QUEST_TURNED_IN") -- For Videre Elixir quest.
	self:RegisterEvent("CHAT_MSG_PARTY")
	self:RegisterEvent("CHAT_MSG_SAY")
	self:RegisterEvent("CHAT_MSG_GUILD")

	-- Register spell cast events for paladin for checking bubble hearth
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	-- For inspecting other player's status
	self:RegisterEvent("INSPECT_READY")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

	Hardcore:InitializeSavedVariables()

	-- different guid means new character with the same name
	if Hardcore_Character.guid ~= PLAYER_GUID then
		Hardcore:ForceResetSavedVariables()
	end

	local any_acheivement_registered = false
	for i, v in ipairs(Hardcore_Character.achievements) do
		if _G.achievements[v] ~= nil then
			_G.achievements[v]:Register(failure_function_executor, Hardcore_Character)
			any_acheivement_registered = true
		end
	end
	if any_acheivement_registered then
		Hardcore:Print(
			'You currently have active Hardcore achievements!  You may quit an achievement at any time using the quitachievement command using Pascal case format (e.g. "/hardcore quitachievement TunnelVision")'
		)
	end

	if Hardcore_Character.party_mode ~= nil then
		if _G.extra_rules[Hardcore_Character.party_mode] ~= nil then
			_G.extra_rules[Hardcore_Character.party_mode]:Register(failure_function_executor, Hardcore_Character, Hardcore_Settings)
		end
	end

	-- cache player name
	PLAYER_NAME, _ = UnitName("player")
	PLAYERGUID = UnitGUID("player")

	-- Show recording reminder
	Hardcore:RecordReminder()

	-- minimap button
	Hardcore:initMinimapButton()

	-- initiate pulse heartbeat
	Hardcore:InitiatePulse()

	-- initiate pulse heartbeat check
	Hardcore:InitiatePulseCheck()

	-- initiate pulse played time
	Hardcore:InitiatePulsePlayed()

	-- check players version against highest version
	local FULL_PLAYER_NAME = Hardcore_GetPlayerPlusRealmName()
	Hardcore:CheckVersionsAndUpdate(FULL_PLAYER_NAME, GetAddOnMetadata("Hardcore", "Version"))

	-- reset debug log; To view debug log, log out and see saved variables before logging back in
	Hardcore_Settings.debug_log = {}

	local function inSOM()
		for i = 1, 40 do
			local buff_name, _, _, _, _, _, _, _, _, _, _ = UnitBuff("player", i)
			if buff_name == nil then
				return false
			end
			if buff_name == "Adventure Awaits" or buff_name == "Soul of Iron" then
				return true
			end
		end
		return true
	end

	CheckForExpiredDKToken(Hardcore_Settings)
	CheckForExpiredPartyChangeToken(Hardcore_Settings)

	if Hardcore_Character.game_version == "" or Hardcore_Character.game_version == "Era" then
		if _G["HardcoreBuildLabel"] == nil then
		-- pass
		elseif _G["HardcoreBuildLabel"] == "Classic" then
			C_Timer.After(5.0, function()
				if inSOM() then
					Hardcore_Character.game_version = "SoM"
				else
					Hardcore_Character.game_version = "Era"
				end
			end)
		else
			Hardcore_Character.game_version = _G["HardcoreBuildLabel"]
		end
	end
end

local function GiveVidereWarning()
	Hardcore:Print("|cFFFF0000WARNING:|r drinking the Videre Elixir will kill you. You cannot appeal this death.")
	Hardcore:ShowAlertFrame(
		ALERT_STYLES.videre_warning,
		"WARNING: drinking the Videre Elixir will kill you. You cannot appeal this death."
	)
end

function Hardcore:QUEST_ACCEPTED(_, questID)
	if questID == 3912 then
		GiveVidereWarning()
	end
end

local function RequestHCDataIfValid(unit_id)
	if UnitIsPlayer(unit_id) then
		if UnitIsFriend("player", unit_id) then
			if
				other_hardcore_character_cache[UnitName(unit_id)] == nil
				or time() - other_hardcore_character_cache[UnitName(unit_id)].last_received > 30
			then
				if UnitAffectingCombat("player") == false and UnitAffectingCombat(unit_id) == false then
					Hardcore:RequestCharacterData(UnitName(unit_id))
				end
			end
		end
	end
end

function Hardcore:UPDATE_MOUSEOVER_UNIT()
	RequestHCDataIfValid("mouseover")
end

function Hardcore:UNIT_TARGET()
	RequestHCDataIfValid("target")
end

function Hardcore:QUEST_TURNED_IN(questID)
	if questID == 4041 then
		GiveVidereWarning()
	end
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

function Hardcore:INSPECT_READY(...)
	if loaded_inspect_frame == false then
		loaded_inspect_frame = true
		local ITabName = "HC"
		local ITabID = InspectFrame.numTabs + 1
		local ITab =
			CreateFrame("Button", "$parentTab" .. ITabID, InspectFrame, "CharacterFrameTabButtonTemplate", ITabName)
		PanelTemplates_SetNumTabs(InspectFrame, ITabID)
		PanelTemplates_SetTab(InspectFrame, 1)

		ITab:SetPoint("LEFT", "$parentTab" .. (ITabID - 1), "RIGHT", -16, 0)
		ITab:SetText(ITabName)
	end

	if _G["InspectHonorFrame"] ~= nil then
		hooksecurefunc(_G["InspectHonorFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	if _G["InspectPaperDollFrame"] ~= nil then
		hooksecurefunc(_G["InspectPaperDollFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	if _G["InspectPVPFrame"] ~= nil then
		hooksecurefunc(_G["InspectPVPFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	if _G["InspectTalentFrame"] ~= nil then
		hooksecurefunc(_G["InspectTalentFrame"], "Show", function(self)
			HideInspectHC()
		end)
	end

	hooksecurefunc("CharacterFrameTab_OnClick", function(self)
		local name = self:GetName()
		if
			(name ~= "InspectFrameTab3" and _G["HardcoreBuildLabel"] ~= "WotLK")
			or (name ~= "InspectFrameTab4" and _G["HardcoreBuildLabel"] == "WotLK")
		then -- 3:era, 4:wotlk
			return
		end
		if _G["HardcoreBuildLabel"] == "WotLK" then
			PanelTemplates_SetTab(InspectFrame, 4)
		else
			PanelTemplates_SetTab(InspectFrame, 3)
		end
		if _G["InspectPaperDollFrame"] ~= nil then
			_G["InspectPaperDollFrame"]:Hide()
		end
		if _G["InspectHonorFrame"] ~= nil then
			_G["InspectHonorFrame"]:Hide()
		end
		if _G["InspectPVPFrame"] ~= nil then
			_G["InspectPVPFrame"]:Hide()
		end
		if _G["InspectTalentFrame"] ~= nil then
			_G["InspectTalentFrame"]:Hide()
		end

		target_name = UnitName("target")
		if other_hardcore_character_cache[target_name] ~= nil then
			ShowInspectHC(
				other_hardcore_character_cache[target_name],
				target_name,
				other_hardcore_character_cache[target_name].version
			)
		else
			local _default_hardcore_character = {
				achievements = {},
				party_mode = "Solo",
				team = {},
				first_recorded = -1,
				version = "?",
			}
			ShowInspectHC(_default_hardcore_character, target_name, _default_hardcore_character.version)
		end
	end)

	hooksecurefunc(InspectFrame, "Hide", function(self, button)
		HideInspectHC()
	end)
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
			local message = PLAYER_NAME
				.. " just received a Bubble-hearth infraction at "
				.. bubble_hearth_info.start_cast
			SendChatMessage(message, "GUILD", nil, nil)
			Hardcore:ShowAlertFrame(ALERT_STYLES.hc_red, "Bubble-hearth Infraction\nContact a Mod immediately.")

			STARTED_BUBBLE_HEARTH_INFO = nil
		end
	end
end

function Hardcore:PLAYER_ENTERING_WORLD()
	Hardcore_Frame:RegisterForDrag("LeftButton")
	Hardcore_Alerts_Button:SetText(Hardcore_Settings.notify and "Disable alerts" or "Enable alerts")

	-- cache player name
	PLAYER_NAME, _ = UnitName("player")
	Hardcore:PrintBubbleHearthInfractions()
	Hardcore:Monitor("Monitoring malicious users enabled.")

	if Hardcore_Settings.show_minimap_mailbox_icon == false then
		MiniMapMailIcon:Hide()
		MiniMapMailBorder:Hide()
	end

	-- initialize addon communication
	if not C_ChatInfo.IsAddonMessagePrefixRegistered(COMM_NAME) then
		C_ChatInfo.RegisterAddonMessagePrefix(COMM_NAME)
	end
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
	-- Screenshot
	C_Timer.After(PICTURE_DELAY, Screenshot)

	-- Update deaths
	if
		#Hardcore_Character.deaths == 0
		or (
			#Hardcore_Character.deaths > 0
			and Hardcore_Character.deaths[#Hardcore_Character.deaths].player_alive_trigger ~= nil
		)
	then
		table.insert(Hardcore_Character.deaths, {
			player_dead_trigger = date("%m/%d/%y %H:%M:%S"),
			player_alive_trigger = nil,
		})
	end

	-- Send message to guild
	local playerGreet = GENDER_GREETING[UnitSex("player")]
	local name = UnitName("player")
	local _, _, classID = UnitClass("player")
	local class = CLASSES[classID]
	local level = UnitLevel("player")
	local zone, mapID
	if IsInInstance() then
		zone = GetInstanceInfo()
	else
		mapID = C_Map.GetBestMapForUnit("player")
		zone = C_Map.GetMapInfo(mapID).name
	end
	local messageFormat = "Our brave %s, %s the %s, has died at level %d in %s"

	-- here we check if that was sacrifice
	local isSacrifice = false
	if Hardcore_Settings.sacrifice ~= nil and #Hardcore_Settings.sacrifice == 1 then
		-- sacrifice is active now we get timestamp
		local sacrifice = Hardcore_Settings.sacrifice[1]
		local timestamp = time(date("*t"))
		if (timestamp - sacrifice.timestamp) <= 300 then
			GenerateDKToken(Hardcore_Settings, Hardcore_Character, party_change_token_handler.generated_secret)
			messageFormat =
				"Our brave %s, %s the %s, is choosing to follow the Path of the Ebon Blade at level %d in %s"
			Hardcore_Settings.sacrifice[1].complete = true
			Hardcore_Character.sacrificed_at = date("%m/%d/%y %H:%M:%S")
			isSacrifice = true
		else
			Hardcore:Print("Sacrifice time expired. R.I.P.")
		end
	end

	local messageString = messageFormat:format(playerGreet, name, class, level, zone)
	if not (Last_Attack_Source == nil) then
		messageString = string.format("%s to a %s", messageString, Last_Attack_Source)
		Last_Attack_Source = nil
	end

	if not (recent_msg["text"] == nil) then
		local playerPronoun = GENDER_POSSESSIVE_PRONOUN[UnitSex("player")]
		messageString = string.format('%s. %s last words were "%s"', messageString, playerPronoun, recent_msg["text"])
	end

	SendChatMessage(messageString, "GUILD")

	Hardcore:Print(messageString)

	-- Send addon message
	local deathData = string.format("%s%s%s", level, COMM_FIELD_DELIM, mapID and mapID or "")
	local commMessage = COMM_COMMANDS[3] .. COMM_COMMAND_DELIM .. deathData
	if isSacrifice then
		commMessage = COMM_COMMANDS[6] .. COMM_COMMAND_DELIM .. deathData
	end
	if CTL then
		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
	end
end

function Hardcore:PLAYER_TARGET_CHANGED()
	if UnitGUID("target") ~= PLAYER_GUID and UnitIsPVP("target") then
		if Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_BOTH_FACTIONS then
			local faction, _ = UnitFactionGroup("target")
			if
				faction ~= nil
				and (faction ~= PLAYER_FACTION or (faction == PLAYER_FACTION and UnitPlayerControlled("target")))
			then
				local target_name, _ = UnitName("target")
				Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
			end
		elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_ENEMY_FACTION then
			local faction, _ = UnitFactionGroup("target")
			if faction ~= nil and faction ~= PLAYER_FACTION then
				local target_name, _ = UnitName("target")
				Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
			end
		elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_SAME_FACTION then
			local faction, _ = UnitFactionGroup("target")
			if faction ~= nil and faction == PLAYER_FACTION and UnitPlayerControlled("target") then
				local target_name, _ = UnitName("target")
				Hardcore:ShowAlertFrame(ALERT_STYLES.hc_pvp_warning, "Target " .. target_name .. " is PvP enabled!")
			end
		end
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
	local level, healthDelta, powerDelta, numNewTalents, numNewPvpTalentSlots, strengthDelta, agilityDelta, staminaDelta, intellectDelta =
		...
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

	-- send a message to the guild if the player's level is divisible by 10
	local landmarkLevel = (level % 10) == 0
	if landmarkLevel then
		local playerName = UnitName("player")
		local localizedClass = UnitClass("player")

		local messageFormat = "%s the %s has reached level %s!"
		local messageString = string.format(messageFormat, playerName, localizedClass, level)
		SendChatMessage(messageString, "GUILD", nil, nil)
	end
end

function Hardcore:TIME_PLAYED_MSG(...)
	local totalTimePlayed, _ = ...
	Hardcore_Character.time_played = totalTimePlayed or 1
	-- Check playtime gap percentage
	if Hardcore_Character.time_played > 60 * 5 then -- at least 5 minutes
		Hardcore_Character.tracked_played_percentage = Hardcore_Character.time_tracked
			/ Hardcore_Character.time_played
			* 100.0
	else
		Hardcore_Character.tracked_played_percentage = 100.0
	end

	Hardcore:Debug(Hardcore_Character.tracked_played_percentage)

	-- Check to see if the gap since the last recording is too long.  When receiving played time for the first time.
	if RECEIVED_FIRST_PLAYED_TIME_MSG == false and Hardcore_Character.accumulated_time_diff ~= nil then
		local debug_message = "Playtime gap percentage: " .. Hardcore_Character.tracked_played_percentage .. "%."
		Hardcore:Debug(debug_message)

		-- Only warn user about playtime percentage if percentage is low enough and enough playtime is logged.
		local level = UnitLevel("player")
		local percentage = Hardcore_Character.tracked_played_percentage
		if Hardcore:ShouldShowPlaytimeWarning(level, percentage) then
			Hardcore:DisplayPlaytimeWarning(level)
		end

		-- Check playtime gap since last session
		local duration_since_last_recording = Hardcore_Character.time_played
			- Hardcore_Character.time_tracked
			- Hardcore_Character.accumulated_time_diff
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
			local message = "\124cffFF0000Addon/Playtime gap detected at date"
				.. Hardcore_Character.played_time_gap_warnings[#Hardcore_Character.played_time_gap_warnings].date
				.. " with a duration: "
				.. Hardcore_Character.played_time_gap_warnings[#Hardcore_Character.played_time_gap_warnings].duration_since_last_recording
				.. " seconds."
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
				Hardcore:Print(
					"Level "
						.. (recent - 1)
						.. "-"
						.. recent
						.. " time played: "
						.. SecondsToTime(totalTimePlayed - v["playedtime"])
				)
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

function Hardcore:ShouldShowPlaytimeWarning(level, percentage)
	if level <= 5 then
		return false
	elseif level <= 15 then
		return percentage <= 40
	elseif level <= 20 then
		return percentage <= 70
	elseif level <= 25 then
		return percentage <= 80
	elseif level <= 30 then
		return percentage <= 90
	elseif level <= 35 then
		return percentage <= 93
	else
		return percentage <= 95
	end
end

function Hardcore:DisplayPlaytimeWarning(level)
	local messageprefix = "\124cffFF0000"

	if level <= 20 then
		Hardcore:Print(
			messageprefix
				.. "Detected that the player's addon active time is much lower than played time. If you have just installed the addon, start a new character."
		)
	else
		Hardcore:Print(
			messageprefix
				.. "Detected that the player's addon active time is much lower than played time. If you have just installed the addon: consider starting a new character. Continuing on means you risk your HC Verified Status."
		)
		Hardcore:Print(
			messageprefix
				.. "If you have had Hardcore 0.5.0 or greater installed since level 1, contact a mod and record the rest of your run."
		)
	end
end

function Hardcore:CHAT_MSG_ADDON(prefix, datastr, scope, sender)
	-- Ignore messages that are not ours
	if COMM_NAME == prefix then
		-- Get the command
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)
		if command == COMM_COMMANDS[7] then -- Received request for party change
			local name, _ = string.split("-", sender)
			local party_change_token_secret = string.split(COMM_FIELD_DELIM, data)
			party_change_token_handler:ReceiveRequestPartyChangeToken(
				Hardcore_Settings,
				Hardcore_Character,
				party_change_token_secret,
				name
			)
			return
		end
		if command == COMM_COMMANDS[8] then -- Received request for party change
			local name, _ = string.split("-", sender)
			local party_change_token_secret = string.split(COMM_FIELD_DELIM, data)
			party_change_token_handler:ReceiveApplyPartyChangeToken(
				Hardcore_Settings,
				Hardcore_Character,
				party_change_token_secret,
				name
			)
			return
		end
		if command == COMM_COMMANDS[5] then -- Received request for hc character data
			local name, _ = string.split("-", sender)
			Hardcore:SendCharacterData(name)
			return
		end
		if command == COMM_COMMANDS[4] then -- Received hc character data
			local name, _ = string.split("-", sender)
			local version_str, creation_time, achievements_str, _, party_mode_str, _, _, team_str, hc_tag =
				string.split(COMM_FIELD_DELIM, data)
			local achievements_l = { string.split(COMM_SUBFIELD_DELIM, achievements_str) }
			other_achievements_ds = {}
			for i, id in ipairs(achievements_l) do
				if _G.id_a[id] ~= nil then
					table.insert(other_achievements_ds, _G.id_a[id])
				end
			end
			local team_l = { string.split(COMM_SUBFIELD_DELIM, team_str) }
			other_hardcore_character_cache[name] = {
				first_recorded = creation_time,
				achievements = other_achievements_ds,
				party_mode = party_mode_str,
				version = version_str,
				team = team_l,
				last_received = time(),
				hardcore_player_name = hc_tag,
			}
			return
		end
		if DEPRECATED_COMMANDS[command] or alert_msg_time[command] == nil then
			return
		end
		if
			alert_msg_time[command][sender]
			and (time() - alert_msg_time[command][sender] < COMM_SPAM_THRESHOLD[command])
		then
			local debug_info = { command, data, sender }
			table.insert(Hardcore_Settings.debug_log, debug_info)
			alert_msg_time[command][sender] = time()
			-- Display that someone is trying to send spam messages; notifies mods to look at saved_vars and remove player from guild
			if
				monitor_msg_throttle[command][sender] == nil
				or (time() - monitor_msg_throttle[command][sender] > THROTTLE_DURATION)
			then
				Hardcore:Monitor("|cffFF0000Received spam from " .. sender .. ", using the " .. command .. " command.")
				monitor_msg_throttle[command][sender] = time()
			end
			return
		end
		alert_msg_time[command][sender] = time()

		-- Determine what command was sent
		-- COMM_COMMANDS[2] is deprecated, but its backwards compatible so we still can handle
		if command == COMM_COMMANDS[2] or command == COMM_COMMANDS[3] or command == COMM_COMMANDS[6] then
			Hardcore:Add(data, sender, command)
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

function Hardcore:CHAT_MSG_SAY(...)
	if self:SetRecentMsg(...) then
		recent_msg["type"] = 0
	end
end

function Hardcore:CHAT_MSG_GUILD(...)
	if self:SetRecentMsg(...) then
		recent_msg["type"] = 2
	end
end

function Hardcore:CHAT_MSG_PARTY(...)
	if self:SetRecentMsg(...) then
		recent_msg["type"] = 1
	end
end

function Hardcore:SetRecentMsg(...)
	local text, sn, LN, CN, p2, sF, zcI, cI, cB, unu, lI, senderGUID = ...
	if PLAYERGUID == nil then
		PLAYERGUID = UnitGUID("player")
	end

	if senderGUID == PLAYERGUID then
		recent_msg["text"] = text
		return true
	end
	return false
end

function Hardcore:GUILD_ROSTER_UPDATE(...)
	guild_roster_loading = false

	-- Create a new dictionary of just online people every time roster is updated
	guild_online = {}

	-- Hardcore:Debug('guild roster update')
	local numTotal, numOnline, numOnlineAndMobile = GetNumGuildMembers()
	for i = 1, numOnline, 1 do
		local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID =
			GetGuildRosterInfo(i)

		-- name is nil after a gquit, so nil check here
		if name then
			guild_online[name] = {
				name = name,
				level = level,
				classDisplayName = classDisplayName,
			}
		end
	end

	Hardcore:UpdateGuildRosterRows()
	if display == "AddonStatus" then
		Hardcore_SubTitle:SetText(STRING_ADDON_STATUS_SUBTITLE)
	end
end

--[[ Utility Methods ]]
--

function Hardcore:Print(msg)
	print("|cffed9121Hardcore|r: " .. (msg or ""))
end

function Hardcore:Debug(msg)
	if true == debug then
		print("|cfffd9122HCDebug|r: " .. (msg or ""))
	end
end

function Hardcore:Monitor(msg)
	if true == Hardcore_Settings.monitor then
		print("|cff00ffffHCMonitor|r: " .. (msg or ""))
	end
end

function Hardcore:ApplyAlertFrameSettings()
	Hardcore_Alert_Frame:SetScale(Hardcore_Settings.alert_frame_scale)
	Hardcore_Alert_Frame:SetPoint(
		"TOP",
		"UIParent",
		"TOP",
		Hardcore_Settings.alert_frame_x_offset / Hardcore_Settings.alert_frame_scale,
		Hardcore_Settings.alert_frame_y_offset / Hardcore_Settings.alert_frame_scale
	)
end

-- Alert UI
function Hardcore:ShowAlertFrame(styleConfig, message)
	-- message is any text accepted by FontString:SetText(message)

	message = message or ""

	local data = styleConfig or ALERT_STYLES["hc_red"]
	local frame, text, icon, file, delay, alertSound =
		data.frame, data.text, data.icon, data.file, data.delay, data.alertSound

	filename = MEDIA_DIR .. file
	icon:SetTexture(filename)
	text:SetText(message)

	frame:Show()

	if alertSound then
		PlaySound(alertSound)
	end

	-- HACK:
	-- There's a bug here where a sequence of overlapping notifications share one 'hide' timer
	-- There should be a step here that unbinds all-but-the-last notification's Hide() callback
	C_Timer.After(delay, function()
		frame:Hide()
	end)
end

function Hardcore:Add(data, sender, command)
	-- Display the death locally if alerts are not toggled off.
	if Hardcore_Settings.notify then
		local level = 0
		local mapID
		if data then
			level, mapID = string.split(COMM_FIELD_DELIM, data)
			level = tonumber(level)
			mapID = tonumber(mapID)
		end
		if type(level) == "number" then
			for i = 1, GetNumGuildMembers() do
				local name, _, _, guildLevel, _, zone, _, _, _, _, class = GetGuildRosterInfo(i)
				if name == sender then
					if mapID then
						local mapData = C_Map.GetMapInfo(mapID) -- In case some idiot sends an invalid map ID, it won't cause mass lua errors.
						zone = mapData and mapData.name or zone -- If player is in an instance, will have to get zone from guild roster.
					end
					level = level > 0 and level < 61 and level or guildLevel -- If player is using an older version of the addon, will have to get level from guild roster.
					local messageFormat = "%s the %s%s|r has died at level %d in %s"
					if command == COMM_COMMANDS[6] then
						messageFormat =
							"%s the %s%s|r is choosing to follow the Path of the Ebon Blade at level %d in %s"
					end
					local messageString = messageFormat:format(
						name:gsub("%-.*", ""),
						"|c" .. RAID_CLASS_COLORS[class].colorStr,
						class,
						level,
						zone
					)

					-- If player is in a raid, then only show alerts for other players in the same raid
					if UnitInRaid("player") == nil or UnitInRaid(name:gsub("%-.*", "")) then
						Hardcore:ShowAlertFrame(ALERT_STYLES.death, messageString)
					end
				end
			end
		end
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
			row_str = string.format(
				"%-17s%s%-10s|r%-10s%-25s%-s",
				row["player"],
				"",
				row["level"],
				SecondsToTime(row["playedtime"]),
				"",
				row["localtime"]
			)
		elseif formattype == "Deaths" then
			-- this is a death row
			if Hardcore:ValidateEntry(row) then
				local _, name, classname, level, mapId, tod = string.split(COMM_FIELD_DELIM, row)
				local mapName = C_Map.GetMapInfo(mapId).name
				local color = Hardcore:GetClassColorText(classname)
				if fullcolor then
					row_str = string.format(
						"%s%-17s%-10s%-10s%-25s%-s|r",
						color,
						name,
						classname,
						level,
						mapName,
						date("%Y-%m-%d %H:%M:%S", tod)
					)
				else
					row_str = string.format(
						"%-17s%s%-10s|r%-10s%-25s%-s",
						name,
						color,
						classname,
						level,
						mapName,
						date("%Y-%m-%d %H:%M:%S", tod)
					)
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
						version = GetAddOnMetadata("Hardcore", "Version")
					else
						version = guild_versions[row.name]
					end

					if guild_versions_status[row.name] == "updated" then
						color = COLOR_GREEN
					else
						color = COLOR_YELLOW
					end

					statusText = "HC Addon: Detected (" .. version .. ")"
				else
					statusText = "HC Addon: Not Detected"
					color = COLOR_RED
				end

				row_str = string.format("%sLv: %s %s (%s)", color, row.level, row.name, statusText)
			end
		elseif formattype == "Rules" then
			row_str = row
		elseif formattype == "DeathKnight" then
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
	elseif "Death Knight" == classname then
		return "|c00C41E3A"
	end

	Hardcore:Debug("ERROR: classname not found")
	return "|c00c41f3b" -- Red
end

--[[ UI Methods ]]
--

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
	Hardcore:Debug("display: " .. display)
	-- refresh data source
	if display == "Levels" then
		displaylist = Hardcore_Settings.level_list
		Hardcore_Name_Sort:Show()
		Hardcore_Class_Sort:Show()
		Hardcore_Level_Sort:Show()
		Hardcore_Zone_Sort:Show()
		Hardcore_TOD_Sort:Show()
		Hardcore_DK_Sacrifice:Hide()
		Hardcore_DK_Activate:Hide()
	elseif display == "GetVerified" then
		-- hide buttons
		Hardcore_Name_Sort:Hide()
		Hardcore_Class_Sort:Hide()
		Hardcore_Level_Sort:Hide()
		Hardcore_Zone_Sort:Hide()
		Hardcore_TOD_Sort:Hide()
		Hardcore_DK_Sacrifice:Hide()
		Hardcore_DK_Activate:Hide()
		DeathListEntry3:Hide()

		local verificationstring = Hardcore:GenerateVerificationString()
		local f = {}
		table.insert(f, "To get verified, copy the string below and visit the classichc website.")
		table.insert(f, "")
		table.insert(f, verificationstring)
		displaylist = f
	elseif display == "AddonStatus" then
		Hardcore_DK_Sacrifice:Hide()
		Hardcore_DK_Activate:Hide()
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
		Hardcore_DK_Sacrifice:Hide()
		Hardcore_DK_Activate:Hide()

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
		table.insert(f, "No battlegrounds allowed")
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
		table.insert(f, "You can verify your run using this addon (Get verified tab). Recording or streaming is also")
		table.insert(f, "recommended to provide evidence for special circumstances such as disconnection deaths.")
		table.insert(f, "")
		table.insert(
			f,
			"At 60 you earn your IMMORTALITY and become a full fledged character with insane bragging rights "
		)
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
	elseif display == "DeathKnight" then
		Hardcore_Name_Sort:Hide()
		Hardcore_Class_Sort:Hide()
		Hardcore_Level_Sort:Hide()
		Hardcore_Zone_Sort:Hide()
		Hardcore_TOD_Sort:Hide()
		DeathListEntry3:Hide()
		Hardcore_DK_Sacrifice:Show()
		Hardcore_DK_Activate:Show()

		local f = {}
		table.insert(f, "Death Knights are authorized for solo HC runs only. However, to follow along in the spirit")
		table.insert(f, "of Hardcore, you must level another character of the same faction and “sacrifice it”.")
		table.insert(f, "Due to certain limitations currently, Death Knights are not allowed to be played in Duos,")
		table.insert(f, "Trios, or on achievement runs. This may change in the future.")
		table.insert(f, "If you should fall as a Death Knight, you must start the process over from level one and")
		table.insert(f, "sacrifice another character. ")
		table.insert(f, "Level 55 is the only level you may sacrifice a character at.")
		table.insert(f, "")
		table.insert(f, "Listed below is the step by step process in order to create a valid Death Knight.")
		table.insert(f, "")
		table.insert(f, "Step 1: Level a solo character of the “SAME FACTION” to level 55, following the HC rules.")
		table.insert(f, "(same faction isnt tech true, but it seems odd to let someone level ally to make a horde DK)")
		table.insert(
			f,
			"Step 2: While out of combat, click on the “SACRIFICE” button below. This starts a 5 minute timer."
		)
		table.insert(
			f,
			"Step 3: During these 5 minutes, you must die on your current character. After dying, you DO NOT"
		)
		table.insert(f, " need to delete, but this toon will no longer be valid for HC.")
		table.insert(f, "Step 4: Create your Death Knight and log onto them.")
		table.insert(f, "Step 5: Click on “ACTIVATE” below. You are now good to go. Survive well out there!")
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
	elseif display == "DeathKnight" then
		Hardcore_SubTitle:SetText("DEATH KNIGHT rules")
	else
		Hardcore_SubTitle:SetText("DEATH = DELETE")
	end

	Hardcore_Deathlist_ScrollBar_Update()
end

-- Toggles death alerts on or off.
function Hardcore_Toggle_Alerts()
	Hardcore_Settings.notify = not Hardcore_Settings.notify
	Hardcore_Alerts_Button:SetText(Hardcore_Settings.notify and "Disable alerts" or "Enable alerts")
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
			tooltip:AddLine("Hardcore (" .. GetAddOnMetadata("Hardcore", "Version") .. ")")
			tooltip:AddLine("|cFFCFCFCFclick|r show window")
			tooltip:AddLine("|cFFCFCFCFctrl click|r toggle minimap button")
		end,
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

	if Hardcore_Settings["hide"] == false then
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
	local converted_successfully = "FALSE"
	if Hardcore_Character.converted_successfully then
		converted_successfully = "TRUE"
	end
	local game_version_checker = Hardcore_Character.game_version or { _G["HardcoreBuildLabel"] }

	local baseVerificationData = {
		Hardcore_Character.guid,
		realm,
		race,
		class,
		name,
		level,
		Hardcore_Character.time_played,
		Hardcore_Character.time_tracked,
		#Hardcore_Character.deaths,
		tradePartners,
		Hardcore_Character.sacrificed_at,
		converted_successfully,
		game_version_checker,
	}
	local baseVerificationString =
		Hardcore_join(Hardcore_map(baseVerificationData, Hardcore_stringOrNumberToUnicode), ATTRIBUTE_SEPARATOR)
	local bubbleHearthIncidentsVerificationString = Hardcore_tableToUnicode(Hardcore_Character.bubble_hearth_incidents)
	local playedtimeGapsVerificationString = Hardcore_tableToUnicode(Hardcore_Character.played_time_gap_warnings)
	return Hardcore_join({
		baseVerificationString,
		bubbleHearthIncidentsVerificationString,
		playedtimeGapsVerificationString,
	}, ATTRIBUTE_SEPARATOR)
end

--[[ Timers ]]
--
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

function Hardcore:RequestCharacterData(dest)
	if CTL then
		local commMessage = COMM_COMMANDS[5] .. COMM_COMMAND_DELIM .. ""
		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "WHISPER", dest)
	end
end

function Hardcore:SendCharacterData(dest)
	if CTL then
		local commMessage = COMM_COMMANDS[4] .. COMM_COMMAND_DELIM
		commMessage = commMessage .. GetAddOnMetadata("Hardcore", "Version") .. COMM_FIELD_DELIM -- Add Version
		if Hardcore_Character.first_recorded ~= nil and Hardcore_Character.first_recorded ~= -1 then
			commMessage = commMessage .. Hardcore_Character.first_recorded .. COMM_FIELD_DELIM -- Add creation time
		else
			commMessage = commMessage .. "-1" .. COMM_FIELD_DELIM -- Add unknown creation time
		end

		for i, v in ipairs(Hardcore_Character.achievements) do
			commMessage = commMessage .. _G.a_id[v] .. COMM_SUBFIELD_DELIM -- Add unknown creation time
		end

		commMessage = commMessage .. COMM_FIELD_DELIM .. COMM_FIELD_DELIM

		if Hardcore_Character.party_mode ~= nil then
			commMessage = commMessage .. Hardcore_Character.party_mode .. COMM_FIELD_DELIM -- Add unknown creation time
		else
			commMessage = commMessage .. "?" .. COMM_SUBFIELD_DELIM -- Add unknown creation time
		end

		commMessage = commMessage .. COMM_FIELD_DELIM
		commMessage = commMessage .. COMM_FIELD_DELIM

		for i, v in ipairs(Hardcore_Character.team) do
			commMessage = commMessage .. v .. COMM_SUBFIELD_DELIM -- Add unknown creation time
		end

		commMessage = commMessage .. COMM_FIELD_DELIM

		commMessage = commMessage .. (Hardcore_Character.hardcore_player_name or "") .. COMM_FIELD_DELIM -- Add Version

		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "WHISPER", dest)
	end
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

function Hardcore:InitiatePulsePlayed()
	--init time played
	Hardcore:RequestTimePlayed()

	--time accumulator
	C_Timer.NewTicker(TIME_TRACK_PULSE, function()
		Hardcore_Character.time_tracked = Hardcore_Character.time_tracked + TIME_TRACK_PULSE
		if RECEIVED_FIRST_PLAYED_TIME_MSG == true then
			Hardcore_Character.accumulated_time_diff = Hardcore_Character.time_played - Hardcore_Character.time_tracked
		end
	end)

	--played time tracking
	C_Timer.NewTicker(TIME_PLAYED_PULSE, function()
		Hardcore:RequestTimePlayed()
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
		guild_versions_status[FULL_PLAYER_NAME] = "outdated"
	end

	pulses[sender] = time()
end

function Hardcore:CheckVersionsAndUpdate(playername, versionstring)
	if guild_highest_version == nil then
		guild_highest_version = GetAddOnMetadata("Hardcore", "Version")
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
			guild_versions_status[playername] = "updated"
		else -- if received pulse is older version, set sender to outdated
			-- Hardcore:Debug('setting sender to: outdated')
			guild_versions_status[playername] = "outdated"
		end
	else -- if received pulse has same version, set to updated
		guild_versions_status[playername] = "updated"
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
				player_alive_trigger = date("%m/%d/%y %H:%M:%S"),
			})
		end
	end
end

function Hardcore:ApplyAlertFrameSettings()
	local scale = Hardcore_Settings.alert_frame_scale or 0.7
	local x_offset = Hardcore_Settings.alert_frame_x_offset or 0
	local y_offset = Hardcore_Settings.alert_frame_y_offset or 0
	Hardcore_Alert_Frame:SetScale(scale)
	Hardcore_Alert_Frame:SetPoint(
		"TOP",
		"UIParent",
		"TOP",
		x_offset / scale,
		y_offset / scale	
	)
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(frame, event, message, sender, ...)
	if Hardcore_Settings.filter_f_in_chat then
		if message == "f" or message == "F" then
			return true, message, sender, ...
		end
	end
	if Hardcore_Settings.show_version_in_chat then
		if guild_versions[sender] then
			message = "|cfffd9122[" .. guild_versions[sender] .. "]|r " .. message
		end
	end
	return false, message, sender, ... -- don't hide this message
	-- note that you must return *all* of the values that were passed to your filter, even ones you didn't change
end)

function Hardcore:SetGriefAlertCondition(grief_alert_option)
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
		Hardcore:Print("|cff00ff00Grief alert options:|r off horde alliance both")
	end
end

function Hardcore:DKConvert(dk_convert_option)
	local _, _, classID = UnitClass("player")
	local level = UnitLevel("player")
	local inCombat = UnitAffectingCombat("player")
	local stealthed = IsStealthed()
	local isFeign = UnitIsFeignDeath("player")
	if dk_convert_option == "sacrifice" then
		if inCombat == true then
			Hardcore:Print("Can't use sacrifice in combat")
			return
		end
		if stealthed == true then
			Hardcore:Print("Can't use sacrifice while stealthed")
			return
		end
		if isFeign == true then
			Hardcore:Print("Can't use sacrifice while Feigning Death")
			return
		end
		-- check if eligible
		if classID == 6 then
			Hardcore:Print("You can't sacrifice Death Knight character")
			return
		end
		if level < SACRIFICE_LEVEL_MIN or level > SACRIFICE_LEVEL_MAX then
			Hardcore:Print(string.format("You must be level %s - %s to sacrifice", SACRIFICE_LEVEL_MIN, SACRIFICE_LEVEL_MAX))
			return
		end
		-- need to warn before sacrifice if something is wrong
		local debug_message = "Playtime gap percentage: " .. Hardcore_Character.tracked_played_percentage .. "%."
		Hardcore:Debug(debug_message)
		local percentage = Hardcore_Character.tracked_played_percentage

		if Hardcore:ShouldShowPlaytimeWarning(level, percentage) then
			Hardcore:DisplayPlaytimeWarning(level)
			return
		end
		-- we deaths, bh, played_time_gaps and trade partners
		if
			#Hardcore_Character.deaths > 0
			or #Hardcore_Character.bubble_hearth_incidents > 0
			or #Hardcore_Character.trade_partners > 0
		then
			Hardcore:Print(
				"Before proceeding with sacrifice, please contact admins and verify your character as there are some warnings!"
			)
			return
		end
		local sacrifice = {}
		sacrifice["guid"] = Hardcore_Character.guid
		sacrifice["localtime"] = date("%m/%d/%y %H:%M:%S")
		sacrifice["timestamp"] = time(date("*t"))
		sacrifice["override"] = false
		sacrifice["complete"] = false
		if Hardcore_Settings.sacrifice == nil then
			Hardcore_Settings.sacrifice = {}
		end
		for k, v in pairs(Hardcore_Settings.sacrifice) do
			Hardcore_Settings.sacrifice[k] = nil
		end
		table.insert(Hardcore_Settings.sacrifice, sacrifice)
		--Hardcore_Character.sacrificed_at = sacrifice["localtime"]
		Hardcore:Print("Character marked for sacrifice. Die within 5 minutes and then activate it on Death Knight.")
		party_change_token_handler:SendRequestPartyChangeToken(
			CTL,
			COMM_COMMANDS[7],
			COMM_COMMAND_DELIM,
			COMM_NAME,
			Hardcore_Character.team
		)
	elseif dk_convert_option == "activate" then
		if inCombat == true then
			Hardcore:Print("Can't use activate in combat")
			return
		end
		if classID ~= 6 then
			Hardcore:Print("You can activate only Death Knight character")
			return
		end
		if Hardcore_Settings.sacrifice == nil or #Hardcore_Settings.sacrifice == 0 then
			Hardcore:Print("There are no sacrificed characters")
			return
		end
		--Hardcore:Print(Hardcore_Settings.sacrifice[1].guid)
		--Hardcore:Print(Hardcore_Settings.sacrifice[1].localtime)
		if Hardcore_Settings.sacrifice[1].complete then
			Hardcore_Character.converted_successfully = true
			Hardcore_Character.converted_time = date("%m/%d/%y %H:%M:%S")
			for k, v in pairs(Hardcore_Settings.sacrifice) do
				Hardcore_Settings.sacrifice[k] = nil
			end
			Hardcore:Print("Death Knight activated. Happy hunting.")
			local party_change_token_secret = ApplyDKToken(Hardcore_Settings, Hardcore_Character)
			party_change_token_handler:SendApplyPartyChangeToken(
				CTL,
				COMM_COMMANDS[8],
				COMM_COMMAND_DELIM,
				COMM_NAME,
				Hardcore_Character.team,
				party_change_token_secret
			)
		else
			Hardcore:Print("There are no sacrificed characters")
		end
	elseif dk_convert_option == "override" then
		if inCombat == true then
			Hardcore:Print("Can't use sacrifice in combat")
			return
		end
		if stealthed == true then
			Hardcore:Print("Can't use sacrifice while stealthed")
			return
		end
		if isFeign == true then
			Hardcore:Print("Can't use sacrifice while Feigning Death")
			return
		end
		-- check if eligible
		if classID == 6 then
			Hardcore:Print("You can't sacrifice Death Knight character")
			return
		end
		if level < SACRIFICE_LEVEL_MIN or level > SACRIFICE_LEVEL_MAX then
			Hardcore:Print(string.format("You must be level %s - %s to sacrifice", SACRIFICE_LEVEL_MIN, SACRIFICE_LEVEL_MAX))
			return
		end
		local sacrifice = {}
		sacrifice["guid"] = Hardcore_Character.guid
		sacrifice["localtime"] = date("%m/%d/%y %H:%M:%S")
		sacrifice["timestamp"] = time(date("*t"))
		sacrifice["override"] = true
		sacrifice["complete"] = false
		if Hardcore_Settings.sacrifice == nil then
			Hardcore_Settings.sacrifice = {}
		end
		for k, v in pairs(Hardcore_Settings.sacrifice) do
			Hardcore_Settings.sacrifice[k] = nil
		end
		table.insert(Hardcore_Settings.sacrifice, sacrifice)
		Hardcore:Print("Character marked for sacrifice. Die within 5 minutes and then activate it on Death Knight.")
		party_change_token_handler:SendRequestPartyChangeToken(
			CTL,
			COMM_COMMANDS[7],
			COMM_COMMAND_DELIM,
			COMM_NAME,
			Hardcore_Character.team
		)
	else
		Hardcore:Print("|cff00ff00Death Knight options:|r sacrifice activate")
	end
end

local options = {
	name = "Hardcore",
	handler = Hardcore,
	type = "group",
	args = {
		alert_options_header = {
			type = "group",
			name = "Alerts",
			order = 1,
			inline = true,
			args = {
				death_alerts = {
					type = "select",
					name = "Death alerts",
					desc = "Type of death alerts.",
					values = {
						off = "off",
						on = "on",
					},
					get = function()
						if Hardcore_Settings.notify then
							return "on"
						end
						return "off"
					end,
					set = function(info, value)
						Hardcore_Settings.notify = (value == "on")
					end,
					order = 2,
				},
				grief_alerts = {
					type = "select",
					name = "Grief alerts",
					desc = "Type of grief alerts.",
					values = {
						off = "off",
						alliance = "alliance",
						horde = "horde",
						both = "both",
					},
					get = function(info)
						if Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_OFF then
							return "off"
						elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_SAME_FACTION then
							if PLAYER_FACTION == "Alliance" then
								return "alliance"
							else
								return "horde"
							end
						elseif Hardcore_Character.grief_warning_conditions == GRIEF_WARNING_ENEMY_FACTION then
							if PLAYER_FACTION == "Horde" then
								return "alliance"
							else
								return "horde"
							end
						else
							return "both"
						end
					end,
					set = function(info, value)
						Hardcore:SetGriefAlertCondition(value)
					end,
					order = 3,
				},
			},
		},
		alert_pos_group = {
			type = "group",
			name = "Alert position and scale",
			inline = true,
			order = 4,
			args = {
				alerts_x_pos = {
					type = "range",
					name = "X-offset",
					desc = "Modify alert frame's x-offset.",
					min = -100,
					max = 100,
					get = function()
						return Hardcore_Settings.alert_frame_x_offset / 10
					end,
					set = function(info, value)
						Hardcore_Settings.alert_frame_x_offset = value * 10
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 4,
				},
				alerts_y_pos = {
					type = "range",
					name = "Y-offset",
					desc = "Modify alert frame's y-offset.",
					min = -100,
					max = 100,
					get = function()
						return Hardcore_Settings.alert_frame_y_offset / 10
					end,
					set = function(info, value)
						Hardcore_Settings.alert_frame_y_offset = value * 10
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 4,
				},
				alerts_scale = {
					type = "range",
					name = "Scale",
					desc = "Modify alert frame's scale.",
					min = 0,
					max = 2,
					get = function()
						return Hardcore_Settings.alert_frame_scale
					end,
					set = function(info, value)
						Hardcore_Settings.alert_frame_scale = value
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 4,
				},
				alert_sample = {
					type = "execute",
					name = "show",
					desc = "Show sample alert.",
					func = function(info, value)
						Hardcore:ShowAlertFrame(Hardcore.ALERT_STYLES.hc_sample, "Sample alert frame text.")
						Hardcore:ApplyAlertFrameSettings()
					end,
					order = 5,
				},
			},
		},
		chat_filter_header = {
			type = "group",
			name = "Chat filters",
			order = 6,
			inline = true,
			args = {
				f_in_chat_filter = {
					type = "toggle",
					name = "Filter F in chat",
					desc = "Remove Fs in chat.",
					get = function()
						return Hardcore_Settings.filter_f_in_chat
					end,
					set = function()
						Hardcore_Settings.filter_f_in_chat = not Hardcore_Settings.filter_f_in_chat
					end,
					order = 7,
				},
				version_in_chat_filter = {
					type = "toggle",
					name = "HC versions in chat",
					desc = "Show player versions in chat.",
					get = function()
						return Hardcore_Settings.show_version_in_chat
					end,
					set = function()
						Hardcore_Settings.show_version_in_chat = not Hardcore_Settings.show_version_in_chat
					end,
					order = 8,
				},
			},
		},
		miscellaneous_header = {
			type = "group",
			name = "Miscellaneous",
			order = 9,
			inline = true,
			args = {
				show_minimap_icon = {
					type = "toggle",
					name = "Show minimap mail icon",
					desc = "Show minimap mail icon",
					get = function()
						return Hardcore_Settings.show_minimap_mailbox_icon
					end,
					set = function()
						Hardcore_Settings.show_minimap_mailbox_icon = not Hardcore_Settings.show_minimap_mailbox_icon
						if Hardcore_Settings.show_minimap_mailbox_icon == true then
							MiniMapMailIcon:Show()
							MiniMapMailBorder:Show()
						else
							MiniMapMailIcon:Hide()
							MiniMapMailBorder:Hide()
						end
					end,
					order = 10,
				},
				hc_player_name = {
					type = "input",
					name = "Hardcore player tag",
					desc = "Hardcore player tag",
					get = function()
						return Hardcore_Settings.hardcore_player_name or ""
					end,
					set = function(info, val)
						Hardcore_Settings.hardcore_player_name = val
						Hardcore_Character.hardcore_player_name = val
					end,
					order = 11,
				},
			},
		},
		apply_defaults = {
			type = "execute",
			name = "Defaults",
			desc = "Change back to default configuration.",
			func = function()
				Hardcore_Settings.show_version_in_chat = false
				Hardcore_Settings.filter_f_in_chat = false
				Hardcore_Settings.notify = true
				Hardcore_Character.grief_warning_conditions = GRIEF_WARNING_BOTH_FACTIONS
				Hardcore_Settings.alert_frame_x_offset = 0
				Hardcore_Settings.alert_frame_y_offset = -150
				Hardcore_Settings.alert_frame_scale = 0.7
				Hardcore_Settings.show_minimap_mailbox_icon = false
				Hardcore:ApplyAlertFrameSettings()
			end,
			order = 11,
		},
	},
}

LibStub("AceConfig-3.0"):RegisterOptionsTable("Hardcore", options)
optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Hardcore", "Hardcore")

--[[ Start Addon ]]
--
Hardcore:Startup()
