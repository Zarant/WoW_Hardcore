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

--[[ Global saved variables ]]--
Hardcore_Settings = {
	version = "0.2.3",
	enabled = true,
	notify = true,
	level_list = {}
}

--[[ Character saved variables ]]--
Hardcore_Character = {
	time_tracked = 0,
	time_played = 0,
	deaths = 0,
	bubble_hearth_incidents = {},
}

--[[ Local variables ]]--
local debug = false

local bubble_hearth_vars = 
{
	spell_id = 8690,
	bubble_name = "Divine Shield",
	light_of_elune_name = "Light of Elune",
}


--addon communication
local CTL = _G.ChatThrottleLib
local COMM_NAME = "HardcoreAddon"
local update_count = 0
local COMM_UPDATE_BREAK = 4
local COMM_DELAY = 5
local COMM_BATCH_SIZE = 4
local COMM_COMMAND_DELIM = "$"
local COMM_FIELD_DELIM = "|"
local COMM_RECORD_DELIM = "^"
local COMM_COMMANDS = {nil, "ADD", nil}

--stuff
local PLAYER_NAME, _ = nil
local PLAYER_GUID = nil
local HARDCORE_REALMS = {"Bloodsail Buccaneers", "Hydraxian Waterlords"}
local GENDER_GREETING = {"guildmate", "brother", "sister"}
local recent_levelup = nil
local Last_Attack_Source = nil
local PICTURE_DELAY = .65
local HIDE_RTP_CHAT_MSG = false
local STARTED_BUBBLE_HEARTH_INFO = nil

--frame display
local display = "Rules"
local displaylist = Hardcore_Settings.level_list
local icon = nil

--the big frame object for our addon
local Hardcore = CreateFrame("Frame", "Hardcore", nil, "BackdropTemplate")

Hardcore_Frame:ApplyBackdrop()

--[[ Command line handler ]]--

local function SlashHandler(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if cmd == "levels" then
		Hardcore:Levels()
	elseif cmd == "alllevels" then
		Hardcore:Levels(true)
	elseif cmd == "enable" then
		Hardcore:Enable(true)
	elseif cmd == "disable" then
		Hardcore:Enable(false)
	elseif cmd == "show" then
		Hardcore_Frame:Show()
	elseif cmd == "hide" then
		--they can click the hide button, dont really need a command for this
		Hardcore_Frame:Hide()
	elseif cmd == "debug" then
		debug = not debug
		Hardcore:Print("Debugging set to "..tostring(debug))
	elseif cmd == "notify" then
		Hardcore_Settings.notify = not Hardcore_Settings.notify
		if true == Hardcore_Settings.notify then
			Hardcore:Print("Notification enabled")
		else
			Hardcore:Print("Notification disabled")
		end
	else
		-- If not handled above, display some sort of help message
		Hardcore:Print("|cff00ff00Syntax:|r/hardcore [command]")
		Hardcore:Print("|cff00ff00Commands:|rshow deaths levels enable disable")
	end
end

SLASH_HARDCORE1, SLASH_HARDCORE2 = '/hardcore', '/hc'
SlashCmdList["HARDCORE"] = SlashHandler

--[[ Startup ]]--

function Hardcore:Startup()
	--the entry point of our addon
	--called inside loading screen before player sees world, some api functions are not available yet.

	--event handling helper
	self:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

	--actually start loading the addon once player ui is loading
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LOGIN")
end

--[[ Events ]]--

function Hardcore:PLAYER_LOGIN()
	--cache player data
	_, class, _ = UnitClass("player")
	PLAYER_NAME, _ = UnitName("player")
	PLAYER_GUID = UnitGUID("player")

	--fires on first loading
	self:RegisterEvent("PLAYER_UNGHOST")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("TIME_PLAYED_MSG")

	-- Register spell cast events for paladin for checking bubble hearth
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	-- Disable addon if not in one of the offical hardcore realms
	Hardcore_Settings.enabled = false
	local realmName = GetRealmName()
	for k, v in pairs(HARDCORE_REALMS) do
		if v == realmName then
			Hardcore:Debug("Player realm, "..v..", is a hardcore server, enabling addon")
			Hardcore_Settings.enabled = true
			break
		end
	end

	if ( Hardcore_Character.time_tracked == nil ) then
		Hardcore_Character.time_tracked = 0
	end

	if Hardcore_Character.deaths == nil then
		Hardcore_Character.deaths = 0
	end

	--cache player name
	PLAYER_NAME, _ = UnitName("player")

	-- Show recording reminder
	Hardcore:RecordReminder()

	--minimap button
	Hardcore:initMinimapButton()
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
				Hardcore:Print("WARNING: Initiated bubble cast. Cancel or run will be invalidated.")

				Hardcore_Warning_Text:SetText("Started bubble hearthing \n Cancel or run will be invalidated.")
				Hardcore_Warning_Frame:Show()
				PlaySound(8959)
				C_Timer.After(8, function()
					Hardcore_Warning_Frame:Hide()
				end)
				return
			end
		end;
	end
end

function Hardcore:UNIT_SPELLCAST_STOP(...)
	local unit, _, spell_id, _, _ = ...
	-- 8690 is hearth spellid
	if STARTED_BUBBLE_HEARTH_INFO ~= nil then
		if unit == "player" and spell_id == bubble_hearth_vars.spell_id then
			Hardcore:Print("Cancelled bubble hearth.")
			STARTED_BUBBLE_HEARTH_INFO = nil
		end
	end
end

function Hardcore:UNIT_SPELLCAST_SUCCEEDED(...)
	local unit, _, spell_id, _, _ = ...
	-- 8690 is hearth spellid
	if STARTED_BUBBLE_HEARTH_INFO ~= nil then
		if unit == "player" and spell_id == bubble_hearth_vars.spell_id then
			Hardcore:Print("Completed bubble cast.")
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
			local message = PLAYER_NAME .. " just received a bubble hearth infraction at " .. bubble_hearth_info.start_cast
			SendChatMessage(message, "GUILD", nil, nil)
			STARTED_BUBBLE_HEARTH_INFO = nil
		end
	end
end

function Hardcore:PLAYER_ENTERING_WORLD()
	--cache player name
	PLAYER_NAME, _ = UnitName("player")
	Hardcore:PrintBubbleHearthInfractions()

	--initialize addon communication
	if( not C_ChatInfo.IsAddonMessagePrefixRegistered(COMM_NAME) ) then
		C_ChatInfo.RegisterAddonMessagePrefix(COMM_NAME)
	end
end

function Hardcore:PLAYER_LEAVING_WORLD()
	Hardcore:CleanData()
end

function Hardcore:PLAYER_DEAD()
	if Hardcore_Settings.enabled == false then return end

	--screenshot
	C_Timer.After(PICTURE_DELAY, Screenshot)

	-- Update death count
	Hardcore_Character.deaths = Hardcore_Character.deaths + 1

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
	local deathData = string.format("%s%s%s%s%s%s%s%s%s%s%s",
									playerId,
									COMM_FIELD_DELIM,
									playerName,
									COMM_FIELD_DELIM,
									localizedClass,
									COMM_FIELD_DELIM,
									playerLevel,
									COMM_FIELD_DELIM,
									mapId,
									COMM_FIELD_DELIM,
									time())

	local commMessage = COMM_COMMANDS[2]..COMM_COMMAND_DELIM..deathData
	if CTL then
		CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
	end
end

function Hardcore:PLAYER_UNGHOST()
	if Hardcore_Settings.enabled == false then return end
	if UnitIsDeadOrGhost("player") == 1 then return end -- prevent message on ghost login or zone

	local playerName, _ = UnitName("player")
	local message = playerName.." has resurrected!"
	SendChatMessage(message, "GUILD", nil, nil)

	-- Screen notification
	Hardcore_Notification_Text:SetText(message)
	Hardcore_Notification_Frame:Show()
	PlaySound(8959)
	C_Timer.After(COMM_DELAY, function()
		Hardcore_Notification_Frame:Hide()
	end)
end

function Hardcore:MAIL_SHOW()
	if Hardcore_Settings.enabled == false then return end

	Hardcore:Print("Hardcore mode is enabled, mailbox access is blocked.")
	CloseMail()
end

function Hardcore:AUCTION_HOUSE_SHOW()
	if Hardcore_Settings.enabled == false then return end

	Hardcore:Print("Hardcore mode is enabled, auction house access is blocked.")
	CloseAuctionHouse()
end

function Hardcore:PLAYER_LEVEL_UP(...)
	if Hardcore_Settings.enabled == false then return end

	--store the recent level up to use in TIME_PLAYED_MSG
	local level, healthDelta, powerDelta, numNewTalents, numNewPvpTalentSlots, strengthDelta, agilityDelta, staminaDelta, intellectDelta = ...
	recent_levelup = level

	--just in case... make sure recent level up gets reset after 3 secs
	C_Timer.After(3, function()
		recent_levelup = nil
	end)

	--get time played, see TIME_PLAYED_MSG
	RequestTimePlayed()

	--take screenshot (got this idea from DingPics addon)
	-- wait a bit so the yellow animation appears
	C_Timer.After(PICTURE_DELAY, Screenshot)
end

function Hardcore:TIME_PLAYED_MSG(...)
	if Hardcore_Settings.enabled == false then return end

	local totalTimePlayed, _ = ...
	Hardcore_Character.time_played = totalTimePlayed

	if recent_levelup ~= nil then
		--cache this to make sure it doesn't disapeer
		local recent = recent_levelup
		--nil this to ensure it's not called twice
		recent_levelup = nil

		--make sure list is initialized
		if Hardcore_Settings.level_list == nil then
			Hardcore_Settings.level_list = {}
		end

		--info for level up record
		local totalTimePlayed, timePlayedThisLevel = ...
		local playerName, _ = UnitName("player")

		--create the record
		local mylevelup = {}
		mylevelup["level"] = recent
		mylevelup["playedtime"] = totalTimePlayed
		mylevelup["realm"] = GetRealmName()
		mylevelup["player"]  = playerName
		mylevelup["localtime"] = date()

		--clear existing records if someone deleted / remade character
		--since this is level 2, this must be a brand new character
		if recent == 2 then
			for i,v in ipairs(Hardcore_Settings.level_list) do
				--find previous records with same name / realm and rename them so we don't misidentify them
				if v["realm"] == mylevelup["realm"] and v["player"] == mylevelup["player"] then
					--copy the record and rename it
					local renamed = v
					renamed["player"] = renamed["player"] .. "-old"
					Hardcore_Settings.level_list[i] = renamed
				end
			end
		end

		--if we found previous level, show the last level time
		for i,v in ipairs(Hardcore_Settings.level_list) do
			--find last level up
			if v["realm"] == mylevelup["realm"] and v["player"] == mylevelup["player"] and v["level"] == recent - 1 then
				--show message to user with calculated time between levels
				Hardcore:Print("Level " .. (recent - 1) .. "-" .. recent .. " time played: " .. SecondsToTime(totalTimePlayed - v["playedtime"]))
			end
		end

		--store level record
		table.insert(Hardcore_Settings.level_list,mylevelup)
	end
end

local Cached_ChatFrame_DisplayTimePlayed = ChatFrame_DisplayTimePlayed
ChatFrame_DisplayTimePlayed = function(...)
if HIDE_RTP_CHAT_MSG then
	HIDE_RTP_CHAT_MSG = false
	return
end
return Cached_ChatFrame_DisplayTimePlayed(...)
end

function Hardcore:RequestTimePlayed()
HIDE_RTP_CHAT_MSG = true
RequestTimePlayed()
end

function Hardcore:CHAT_MSG_ADDON(prefix, datastr, scope, sender)
	if Hardcore_Settings.enabled == false then return end

	-- Ignore messages that are not ours
	if COMM_NAME == prefix then
		-- Get the command
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)

		-- Determine what command was sent
		if command == COMM_COMMANDS[2] then
			Hardcore:Add(data)
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

--[[ Utility Methods ]]--

function Hardcore:Print(msg)
	print("|cffed9121Hardcore|r: "..(msg or ""))
end

function Hardcore:Debug(msg)
	if true == debug then
		print("|cfffd9122HCDebug|r: "..(msg or ""))
	end
end

function Hardcore:Add(data)
	 -- Add the record if needed
	 if true == Hardcore:ValidateEntry(data) then
		Hardcore:Debug("Adding new record "..data)

		-- Display the death locally
		local _, name, class_name, level, map_id, _ = string.split(COMM_FIELD_DELIM, data)
		local class_color = Hardcore:GetClassColorText(class_name)
		local map_name = C_Map.GetMapInfo(tonumber(map_id)).name
		local messageFormat = "%s the %s%s|r has died at level %d in %s"
		local messageString = string.format(messageFormat, name, class_color, class_name, level, map_name)

		Hardcore_Notification_Text:SetText(messageString)
		Hardcore_Notification_Frame:Show()
		PlaySound(8959)
		C_Timer.After(COMM_DELAY, function()
			Hardcore_Notification_Frame:Hide()
		end)
	end
end

-- Should we remove this functionality?
function Hardcore:Enable(setting)
	-- Check if we are attempting to set the existing state
	if Hardcore_Settings.enabled == setting then
		if setting == false then
			Hardcore:Print("Already disabled")
		else
			Hardcore:Print("Already enabled")
		end
		return
	end

	Hardcore_Settings.enabled = setting
	if setting == false then
		Hardcore_EnableToggle:SetText("Enable")
		Hardcore:Print("Disabled")
	else
		Hardcore:RecordReminder()
		Hardcore_EnableToggle:SetText("Disable")
		Hardcore:Print("Enabled")
	end
end

function Hardcore:Levels(all)
	--default parameter value
	if all == nil then
		all = false
	end

	if Hardcore_Settings.level_list ~= nil and #Hardcore_Settings.level_list > 0 then
		local playerName, _ = UnitName("player")
		local playerRealm = GetRealmName()
		local mylevels = {}

		--find relevant records
		for i,v in ipairs(Hardcore_Settings.level_list) do
			--find records from current character
			if v["realm"] == playerRealm and v["player"] == playerName then
				table.insert(mylevels,v)
			end

			--find old records as well
			if all and (v["player"] == (playerName .. "-old")) then
				table.insert(mylevels,v)
			end
		end

		if #mylevels > 0 then
			--for some reason this string concat doesn't work unless stored in variable
			--local headerstr = "==== " .. playerName .. " ==== " .. playerRealm .. " ===="
			--Hardcore:Print(headerstr)
			for i,v in ipairs(mylevels) do
				--for all command show name to distinguish old and new records
				--local nameheader = all and v["player"] .. " = " or ""
				--print the level row
				Hardcore:Print("Levels:")
				Hardcore:Print(Hardcore:FormatRow(v),nil,"Levels")
				--Hardcore:Print(nameheader .. v["level"] .. " = " .. SecondsToTime(v["playedtime"]) .. " = " .. v["localtime"])
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
			row_str = string.format("%-17s%s%-10s|r%-10s%-25s%-s", row["player"], "", row["level"], SecondsToTime(row["playedtime"]), "", row["localtime"])
		elseif formattype == "Deaths" then
			--this is a death row
			if Hardcore:ValidateEntry(row) then
				local _, name, classname, level, mapId, tod = string.split(COMM_FIELD_DELIM, row)
				local mapName = C_Map.GetMapInfo(mapId).name
				local color = Hardcore:GetClassColorText(classname)
				if fullcolor then
					row_str = string.format("%s%-17s%-10s%-10s%-25s%-s|r", color, name, classname, level, mapName, date("%Y-%m-%d %H:%M:%S", tod))
				else
					row_str = string.format("%-17s%s%-10s|r%-10s%-25s%-s", name, color, classname, level, mapName, date("%Y-%m-%d %H:%M:%S", tod))
				end
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

--switch between displays
function Hardcore:SwitchDisplay(displayparam)

	if displayparam ~= nil then
		display = displayparam
	end	

	--refresh the page
	Hardcore_Frame_OnShow()
end

function Hardcore_Frame_OnShow()
	--refresh data source
	if display == "Levels" then		
		displaylist = Hardcore_Settings.level_list
		Hardcore_Name_Sort:Show()
		Hardcore_Class_Sort:Show()
		Hardcore_Level_Sort:Show()
		Hardcore_Zone_Sort:Show()
		Hardcore_TOD_Sort:Show()
		Hardcore_VerificationString:Hide()
	elseif display == "GetVerified" then
		--hide buttons 
		Hardcore_Name_Sort:Hide()
		Hardcore_Class_Sort:Hide()
		Hardcore_Level_Sort:Hide()
		Hardcore_Zone_Sort:Hide()
		Hardcore_TOD_Sort:Hide()
		DeathListEntry3:Hide()

		local verificationstring = Hardcore:GenerateVerificationString()
		local f = {}
		table.insert(f,"To get verified, copy the string below and visit https://classichc.net/get-verified")
		table.insert(f, "")
		table.insert(f, verificationstring)
		displaylist = f
	elseif display == "Rules" then
		--hide buttons 
		Hardcore_Name_Sort:Hide()
		Hardcore_Class_Sort:Hide()
		Hardcore_Level_Sort:Hide()
		Hardcore_Zone_Sort:Hide()
		Hardcore_TOD_Sort:Hide()
		Hardcore_VerificationString:Hide()

		-- hard coded rules table lol
		local f = {}
		table.insert(f,"Official website with info, rules, news, hall of legends, challenges \n")
		table.insert(f,"https://classichc.net")
		table.insert(f,"Help is avaiable on discord (link on website)")
		table.insert(f,"")
		table.insert(f,"11/24/2020 from https://classichc.net/rules/")
		table.insert(f,"")
		table.insert(f,"All professions allowed")
		table.insert(f,"No restriction on talents")
		table.insert(f,"")
		table.insert(f,"You can use gear that you pickup or craft")
		table.insert(f,"No Auction house, No mailbox, No trading")
		table.insert(f,"")
		table.insert(f,"No grouping in open world")
		table.insert(f,"")
		table.insert(f,"Buffs from others are allowed, don't ask for others for buffs")
		table.insert(f,"")
		table.insert(f,"Dungeon Groups are authorized but only ONE run of each Dungeon per character")
		table.insert(f,"Everyone in party must be following hardcore rules")
		table.insert(f,"Everyone must be in level range of the meeting stone.")
		table.insert(f,"Group at the meeting stone to start the dungeon.")		
		table.insert(f,"You can invite people who are on the way.")
		table.insert(f,"")
		table.insert(f,"If you level up inside of the dungeon and exceed the meeting stone requirement you can stay")
		table.insert(f,"Warlocks are allowed to summon players to the meeting stone")
		table.insert(f,"")
		table.insert(f,"Warlocks can’t resurrect via SS")
		table.insert(f,"Shamans can’t resurrect via Ankh")
		table.insert(f,"Paladins can’t Bubble Hearth")
		table.insert(f,"No Light of Elune + Hearthstone")
		table.insert(f,"")
		table.insert(f,"You need a record your journey to be verified")
		table.insert(f,"Stream or record and upload to youtube or twitch")
		table.insert(f,"then submit the playlist of your run on the verification page")
		table.insert(f,"")
		table.insert(f,"At 60 you earn your IMMORTALITY and become a full fledged character with insane bragging rights ")
		table.insert(f,"")
		table.insert(f,"")
		table.insert(f,"=============== DUOS ===============")
		table.insert(f,"")
		table.insert(f,"You must not leave the same zone as each other")
		table.insert(f,"*unless you are a Druid going to Moonglade to complete essential class quests")
		table.insert(f,"You must choose a combo that spawns in the same starting location.")
		table.insert(f,"")
		table.insert(f,"If one of you dies, the other must fall on the sword and the run is over.")
		table.insert(f,"")
		table.insert(f,"You can trade your duo partner found or crafted items, including gold")
		table.insert(f,"")
		table.insert(f,"Multiboxing goes against the spirit of the Hardcore Challenge and is not allowed")
		table.insert(f,"")
		displaylist = f
	end

	--subtitle text
	if display == "Levels" and #displaylist > 0 then
		Hardcore_SubTitle:SetText("You've leveled up "..tostring(#displaylist).." times!")
	else
		Hardcore_SubTitle:SetText("classichc.net")
	end

	--update rows
	Hardcore_Deathlist_ScrollBar_Update()
end

function Hardcore_Deathlist_ScrollBar_Update()
	--max value
	if not (displaylist == nil) then
		FauxScrollFrame_Update(MyModScrollBar, #displaylist, 20, 16)

		--loop through lines adding data
		for line=1, 20 do
			local lineplusoffset = line + FauxScrollFrame_GetOffset(MyModScrollBar)
			local button = getglobal("DeathListEntry"..line)
			if lineplusoffset <= #displaylist then
				--get data
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
	if Hardcore_Settings.enabled == false then return end
	if Hardcore_Settings.notify == false then return end

	Hardcore_Notification_Text:SetText("Hardcore Enabled\n START RECORDING")
	Hardcore_Notification_Frame:Show()
	PlaySound(8959)
	C_Timer.After(10, function()
		Hardcore_Notification_Frame:Hide()
	end)
end

----------------------------------------------------------------------
-- Minimap button (no reload required)
----------------------------------------------------------------------

function Hardcore:initMinimapButton()

	-- Minimap button click function
	local function MiniBtnClickFunc(arg1)

		-- Prevent options panel from showing if Blizzard options panel is showing
		if InterfaceOptionsFrame:IsShown() or VideoOptionsFrame:IsShown() or ChatConfigFrame:IsShown() then return end
		-- Prevent options panel from showing if Blizzard Store is showing
		if StoreFrame and StoreFrame:GetAttribute("isshown") then return end
		-- Left button down
		if arg1 == "LeftButton" then

			-- Control key 
			if IsControlKeyDown() and not IsShiftKeyDown() then
				Hardcore:ToggleMinimapIcon()
				return
			end

			-- Shift key 
			if IsShiftKeyDown() and not IsControlKeyDown() then
				Hardcore:Enable(not Hardcore_Settings.enabled)
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
		icon = "Interface\\AddOns\\Hardcore\\Media\\logo_emblem.blp",
		OnClick = function(self, btn)
			MiniBtnClickFunc(btn)
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine("Hardcore")
			tooltip:AddLine("|cFFCFCFCFclick|r show window")
			tooltip:AddLine("|cFFCFCFCFshift click|r toggle enable")
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

	if(Hardcore_Settings["hide"] == false) then
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
		for i,v in ipairs(Hardcore_Character.bubble_hearth_incidents) do
			if v.guid == PLAYER_GUID then
				message = "\124cffFF0000Player has a " .. v.aura_type .. " hearth infraction at date " .. v.start_cast
				Hardcore:Print(message)
			end
		end
	end
end

local ATTRIBUTE_SEPARATOR = "-"
function Hardcore:GenerateVerificationString()
	_, class, _, race, _, name = GetPlayerInfoByGUID(UnitGUID("player"))
	realm = GetRealmName()
	level = UnitLevel("player")

	local verificationData = {realm, race, class, name, tostring(level), tostring(Hardcore_Character.time_played), tostring(Hardcore_Character.time_tracked), tostring(Hardcore_Character.deaths)}
	local verificationString = Hardcore_join(Hardcore_map(verificationData, Hardcore_stringToUnicode), ATTRIBUTE_SEPARATOR)
	return verificationString
end

--[[ Timers ]]--

local PLAY_TIME_UPDATE_INTERVAL = 1
C_Timer.NewTicker(PLAY_TIME_UPDATE_INTERVAL, function()
	Hardcore_Character.time_tracked = Hardcore_Character.time_tracked + PLAY_TIME_UPDATE_INTERVAL
	Hardcore:RequestTimePlayed()
end)

--[[ Start Addon ]]--
Hardcore:Startup()






