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

--[[ Global variables ]]--
Hardcore_Settings = {
	version = "0.2.3",
	enabled = true,
	notify = true,
	death_list = {},
	level_list = {}
}

--[[ Local variables ]]--
local debug = false

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
local COMM_COMMANDS = {"SYNC", "ADD", "UPDATE"}

--stuff
local PLAYER_NAME, _ = nil
local HARDCORE_REALMS = {"Bloodsail Buccaneers", "Hydraxian Waterlords"}
local GENDER_GREETING = {"guildmate", "brother", "sister"}
local recent_levelup = nil
local Last_Attack_Source = nil
local PICTURE_DELAY = .65

--frame display
local display = "Deaths"
local displaylist = Hardcore_Settings.death_list
local icon = nil

--the big frame object for our addon
local Hardcore = CreateFrame("Frame", "Hardcore")


--[[ Command line handler ]]--

local function SlashHandler(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if cmd == "list" or cmd == "deaths" then
		Hardcore:List()
	elseif cmd == "levels" then
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
	elseif cmd == "sync" then
		if CTL then
			CTL:SendAddonMessage("NORMAL", COMM_NAME, COMM_COMMANDS[1]..COMM_COMMAND_DELIM, "GUILD")
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

	--cache player name
	PLAYER_NAME, _ = UnitName("player")

	-- Show recording reminder
	Hardcore:RecordReminder()

	--minimap button
	Hardcore:initMinimapButton()
end

function Hardcore:PLAYER_ENTERING_WORLD()
	--cache player name
	PLAYER_NAME, _ = UnitName("player")

	--initialize addon communication
	if( not C_ChatInfo.IsAddonMessagePrefixRegistered(COMM_NAME) ) then
		C_ChatInfo.RegisterAddonMessagePrefix(COMM_NAME)
	end

	-- Send sync command to addon	
	if CTL then
		CTL:SendAddonMessage("NORMAL", COMM_NAME, COMM_COMMANDS[1]..COMM_COMMAND_DELIM, "GUILD")
	end
end

-- Removing seeming-redundant code, left as a framework in case we use this event again
-- function Hardcore:PLAYER_LEAVING_WORLD()
--   Hardcore:CleanData()
-- end

function Hardcore:PLAYER_DEAD()
	if Hardcore_Settings.enabled == false then return end

	--screenshot
	C_Timer.After(PICTURE_DELAY, Screenshot)

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

function Hardcore:CHAT_MSG_ADDON(prefix, datastr, scope, sender)
	if Hardcore_Settings.enabled == false then return end

	-- Ignore messages that are not ours
	if COMM_NAME == prefix then
		-- Get the command
		local command, data = string.split(COMM_COMMAND_DELIM, datastr)

		-- Determine what command was sent
		if command == COMM_COMMANDS[1] then
			Hardcore:Sync()
		elseif command == COMM_COMMANDS[2] then
			Hardcore:Add(data)
		elseif command == COMM_COMMANDS[3] then
			Hardcore:Update(data)
		else
			Hardcore:Debug("Unknown command :"..command)
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

function Hardcore:Sync()
	-- Don't send empty lists
	if 0 == #Hardcore_Settings.death_list then
		Hardcore:Debug("No records to sync")
		return
	end

	-- IMPORTANT NOTE: There is a max of 250 characters per message, so break into chunks.
	Hardcore:Debug("Syncing "..tostring(#Hardcore_Settings.death_list).." records")

	-- Build list of all deaths we have seen and broadcast chunks
	local sent = 0
	local data = ""
	for index = 1, #Hardcore_Settings.death_list do
		if 0 == index % COMM_BATCH_SIZE then
			Hardcore:Debug("Sending batch of "..COMM_BATCH_SIZE.." records")
			if CTL then
				CTL:SendAddonMessage("BULK", COMM_NAME, COMM_COMMANDS[3]..COMM_COMMAND_DELIM..data, "GUILD")
			end
			data = ""
			sent = sent + COMM_BATCH_SIZE
		else
			data = data..Hardcore_Settings.death_list[index]..COMM_RECORD_DELIM
		end
	end

	-- Broadcast the remaining records
	data = ""
	for index = sent + 1, #Hardcore_Settings.death_list do
		data = data..Hardcore_Settings.death_list[index]..COMM_RECORD_DELIM
	end
	Hardcore:Debug("Sending remaining "..tostring(#Hardcore_Settings.death_list - sent).." records")
	if CTL then
		CTL:SendAddonMessage("BULK", COMM_NAME, COMM_COMMANDS[3]..COMM_COMMAND_DELIM..data, "GUILD")
	end
end

function Hardcore:Add(data)
	for i=1, #Hardcore_Settings.death_list do
		if Hardcore_Settings.death_list[i] == data then
			Hardcore:Debug("Not adding duplicate record "..data)
			return
		end
	 end

	 -- Add the record if needed
	 if true == Hardcore:ValidateEntry(data) then
		Hardcore:Debug("Adding new record "..data)
		table.insert(Hardcore_Settings.death_list, data)

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

function Hardcore:Update(data)
	-- Check if we want this update
	update_count = update_count + 1
	if not (0 == update_count % COMM_UPDATE_BREAK) then
		return
	end

	-- Parse out the death rows
	local rows = {}
	for entry in string.gmatch(data, "[^"..COMM_RECORD_DELIM.."]+") do
		table.insert(rows, entry)
	end
	if 0 == #rows then
		return
	else
		-- Hardcore:Debug("Update received "..tostring(#rows).." rows of data")
	end

	-- Update local table with missing data
	for index = 1, #rows do
		local rowNeeded = true
		for i=1, #Hardcore_Settings.death_list do
			if Hardcore_Settings.death_list[i] == rows[index] then
				rowNeeded = false
				-- Hardcore:Debug("Row exists, not adding "..string.split(COMM_FIELD_DELIM, rows[index]))
			end
			end

			if rowNeeded == true then
			Hardcore:Debug("Adding new row for "..string.split(COMM_FIELD_DELIM, rows[index]))
			-- Throttle inserts to help with lag
			C_Timer.After(COMM_DELAY, function()
				table.insert(Hardcore_Settings.death_list, rows[index])
			end)
			end
	end
end

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

function Hardcore:List()
	if 0 == #Hardcore_Settings.death_list then
		Hardcore:Print("No deaths recorded")
		return
	end

	Hardcore:Print("List of deaths:")
	Hardcore:Print("\n")
	Hardcore:Print("|cff00ff00Name            Class     Level Location            Time")
	for index = 1, #Hardcore_Settings.death_list do
		local row = Hardcore:FormatRow(Hardcore_Settings.death_list[index],nil,"Deaths")
		if row then
			Hardcore:Print(row)
		end
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

function Hardcore:CleanData()
	local new_list = {}

	for index = 1, #Hardcore_Settings.death_list do
		local valid = Hardcore:ValidateEntry(Hardcore_Settings.death_list[index])
		if true == valid then table.insert(new_list, Hardcore_Settings.death_list[index]) end
	end

	Hardcore_Settings.death_list = new_list
end

function Hardcore:DeDupe()
	local list, dup, c, NaN = {}, {}, 1, {}
	for i=1, #Hardcore_Settings.death_list do
	  local e = Hardcore_Settings.death_list[i]
	  local k = e~=e and NaN or e
	  if k~=nil and not dup[k] then
		c, list[c], dup[k]= c+1, e, true
	  end
	end

	Hardcore_Settings.death_list = list
end

function Hardcore:Sort(column)
	Hardcore:CleanData()
	Hardcore:DeDupe()
	table.sort(Hardcore_Settings.death_list, function(a, b)
		local first = Hardcore:GetValue(a, column)
		local second = Hardcore:GetValue(b, column)

		if "playerid" == column then
			return string.lower(first) < string.lower(second)
		elseif "name" == column then
			return string.lower(first) < string.lower(second)
		elseif "class" == column then
			return string.lower(first) < string.lower(second)
		elseif "level" == column then
			return tonumber(first) < tonumber(second)
		elseif "zone" == column then
			return tonumber(first) < tonumber(second)
		elseif "tod" == column then
			return tonumber(first) < tonumber(second)
		end
	end)
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
	if display == "Deaths" then
		displaylist = Hardcore_Settings.death_list
		Hardcore_Name_Sort:Show()
		Hardcore_Class_Sort:Show()
		Hardcore_Level_Sort:Show()
		Hardcore_Zone_Sort:Show()
		Hardcore_TOD_Sort:Show()
	elseif display == "Levels" then		
		displaylist = Hardcore_Settings.level_list
		Hardcore_Name_Sort:Show()
		Hardcore_Class_Sort:Show()
		Hardcore_Level_Sort:Show()
		Hardcore_Zone_Sort:Show()
		Hardcore_TOD_Sort:Show()
	elseif display == "Rules" then
		--hide buttons 
		Hardcore_Name_Sort:Hide()
		Hardcore_Class_Sort:Hide()
		Hardcore_Level_Sort:Hide()
		Hardcore_Zone_Sort:Hide()
		Hardcore_TOD_Sort:Hide()

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
	if display == "Deaths" and #displaylist > 0 then
		Hardcore_SubTitle:SetText("We honor the "..tostring(#displaylist).." who have fallen")
	elseif display == "Levels" and #displaylist > 0 then
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
					button:SetText(row)
					button:Show()
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



--[[ Start Addon ]]--
Hardcore:Startup()






