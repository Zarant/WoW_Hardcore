local deathlog = {}

local _, addon = ...
-- check if we are running in wow
if type(addon) == "table" then
	deathlog = CreateFrame("Frame", "Deathlog", nil, "BackdropTemplate")
	addon.deathlog = deathlog
end

local debug = false

local CTL = _G.ChatThrottleLib
local COMM_NAME = "HCDeathAlerts"
local COMM_COMMANDS = {
	["BROADCAST_DEATH_PING"] = "1",
	["BROADCAST_DEATH_PING_CHECKSUM"] = "2",
	["LAST_WORDS"] = "3",
}
local COMM_COMMAND_DELIM = "$"
local COMM_FIELD_DELIM = "~"
local HC_REQUIRED_ACKS = 3
local HC_DEATH_LOG_MAX_DEFAULT = 1000

local death_alerts_channel = "hcdeathalertschannel"
local death_alerts_channel_pw = "hcdeathalertschannelpw"

local throttle_player = {}
local shadowbanned = {}

-- [checksum -> {name, guild, source, race, class, level, F's, location, last_words, location}]
deathlog.death_ping_lru_cache_tbl = {}
deathlog.last_attack_source = ""
deathlog.last_words = ""
deathlog.broadcast_death_ping_queue = {}
deathlog.last_words_queue = {}
deathlog.death_alert_out_queue = {}

function fletcher16(player_name, player_guild, player_level)
	local data = player_name .. player_guild .. player_level
	local sum1 = 0
	local sum2 = 0
	for index = 1, #data do
		sum1 = (sum1 + string.byte(string.sub(data, index, index))) % 255;
		sum2 = (sum2 + sum1) % 255;
	end
	return player_name .. "-" .. bit.bor(bit.lshift(sum2, 8), sum1)
end

function deathlog.isValidEntry(_player_data)
	if _player_data == nil then return false end
	if _player_data["source_id"] == nil then return false end
	if _player_data["race_id"] == nil or tonumber(_player_data["race_id"]) == nil or C_CreatureInfo.GetRaceInfo(_player_data["race_id"]) == nil then return false end
	if _player_data["class_id"] == nil or tonumber(_player_data["class_id"]) == nil or GetClassInfo(_player_data["class_id"]) == nil then return false end
	if _player_data["level"] == nil or _player_data["level"] < 0 or _player_data["level"] > 80 then return false end
	if _player_data["instance_id"] == nil and _player_data["map_id"] == nil then return false end
	return true
end

function deathlog.shouldCreateEntry(checksum)
	if deathlog.death_ping_lru_cache_tbl[checksum] == nil then return false end
	if deathlog.death_ping_lru_cache_tbl[checksum]["player_data"] == nil then return false end
	if hardcore_settings.death_log_types == nil or hardcore_settings.death_log_types == "faction_wide" and deathlog.isValidEntry(deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]) then
		if hardcore_settings.deathlog_require_verification == false then
			return true
		end
		if deathlog.death_ping_lru_cache_tbl[checksum]["peer_report"] and deathlog.death_ping_lru_cache_tbl[checksum]["peer_report"] > HC_REQUIRED_ACKS then
			return true
		else
			if debug then
				print("not enough peers for " ..
					checksum .. ": " .. (deathlog.death_ping_lru_cache_tbl[checksum]["peer_report"] or "0"))
			end
		end
	end
	if hardcore_settings.death_log_types ~= nil and hardcore_settings.death_log_types == "greenwall_guilds_only" and deathlog.death_ping_lru_cache_tbl[checksum]["player_data"] and deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["guild"] and hc_peer_guilds[deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["guild"]] then return true end
	if deathlog.death_ping_lru_cache_tbl[checksum]["in_guild"] then return true end

	return false
end

function deathlog:ApplySettings(_settings)
	hardcore_settings = _settings

	if hardcore_settings["death_log_show"] == nil or hardcore_settings["death_log_show"] == true then
		deathlog.ui.Show()
	else
		deathlog.ui.Hide()
	end

	deathlog.ui.Refresh()
end

function deathlog:JoinChannel()
	JoinChannelByName(death_alerts_channel, death_alerts_channel_pw)
	local channel_num = GetChannelName(death_alerts_channel)
	if channel_num == 0 then
		print("Failed to join death alerts channel")
	else
		print("Successfully joined deathlog channel.")
	end

	for i = 1, 10 do
		if _G['ChatFrame' .. i] then
			ChatFrame_RemoveChannel(_G['ChatFrame' .. i], death_alerts_channel)
		end
	end
end

function deathlog.PlayerData(name, guild, source_id, race_id, class_id, level, instance_id, map_id, map_pos, date,
							 last_words, guid)
	return {
		["name"] = name,
		["guild"] = guild,
		["source_id"] = source_id,
		["race_id"] = race_id,
		["class_id"] = class_id,
		["level"] = level,
		["instance_id"] = instance_id,
		["map_id"] = map_id,
		["map_pos"] = map_pos,
		["date"] = date,
		["last_words"] = last_words,
		["guid"] = guid
	}
end

local encodeMessageParams = {
	name = "",
	guild = "",
	source_id = "",
	race_id = "",
	class_id = nil,
	level = "",
	instance_id = nil,
	map_id = nil,
	map_pos = {},
	loc_str = "",
	guid = ""
}

function deathlog.encodeMessage(params)
	params = setmetatable(params or {}, { __index = encodeMessageParams })
	if params.name == nil or params.name == "" then return end
	-- if guild == nil then return end -- TODO
	if tonumber(params.source_id) == nil then return end
	if tonumber(params.race_id) == nil then return end
	if tonumber(params.level) == nil then return end


	if params.map_pos then
		params.loc_str = deathlog.mapPosToString(params.map_pos)
	end

	local comm_message =
		params.name ..
		COMM_FIELD_DELIM ..
		(params.guild or "") ..
		COMM_FIELD_DELIM ..
		params.source_id ..
		COMM_FIELD_DELIM ..
		params.race_id ..
		COMM_FIELD_DELIM ..
		params.class_id ..
		COMM_FIELD_DELIM ..
		params.level ..
		COMM_FIELD_DELIM ..
		(params.instance_id or "") ..
		COMM_FIELD_DELIM ..
		(params.map_id or "") ..
		COMM_FIELD_DELIM ..
		params.loc_str ..
		COMM_FIELD_DELIM ..
		params.guid .. -- guid added to the end to maintain backwards compatibility
		COMM_FIELD_DELIM
	return comm_message
end

function deathlog.decodeMessage(msg)
	local values = {}
	for w in msg:gmatch("(.-)" .. COMM_FIELD_DELIM) do table.insert(values, w) end
	local date = nil
	local last_words = nil
	local name = values[1]
	local guild = values[2]
	local source_id = tonumber(values[3])
	local race_id = tonumber(values[4])
	local class_id = tonumber(values[5])
	local level = tonumber(values[6])
	local instance_id = tonumber(values[7])
	local map_id = tonumber(values[8])
	local map_pos = values[9]
	local guid = values[10]
	local player_data = deathlog.PlayerData(name, guild, source_id, race_id, class_id, level, instance_id, map_id,
		map_pos, date, last_words, guid)
	return player_data
end

function deathlog.mapPosToString(map_pos)
	return string.format("%.4f,%.4f", map_pos.x, map_pos.y)
end

function deathlog.createEntry(checksum)
	if deathlog.death_ping_lru_cache_tbl[checksum] == nil then
		return
	end

	deathlog.ui.InsertEntry(deathlog.death_ping_lru_cache_tbl[checksum]["player_data"])
	deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["date"] = date()
	deathlog.death_ping_lru_cache_tbl[checksum]["committed"] = 1

	-- Record to hardcore_settings
	if hardcore_settings["death_log_entries"] == nil then
		hardcore_settings["death_log_entries"] = {}
	end
	table.insert(hardcore_settings["death_log_entries"], deathlog.death_ping_lru_cache_tbl[checksum]["player_data"])

	local entry_limit = hardcore_settings["deathlog_log_size"] or HC_DEATH_LOG_MAX_DEFAULT
	-- Cap list size, otherwise loading time will increase
	if hardcore_settings["death_log_entries"] and #hardcore_settings["death_log_entries"] > entry_limit then
		table.remove(hardcore_settings["death_log_entries"], 1)
	end

	-- Save in-guilds for next part of migration TODO
	if deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["in_guild"] then return end
	if hardcore_settings.alert_subset ~= nil and hardcore_settings.alert_subset == "greenwall_guilds_only" and deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["guild"] and hc_peer_guilds[deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["guild"]] then
		deathlog.alertIfValid(deathlog.death_ping_lru_cache_tbl[checksum]["player_data"])
		return
	end
	if hardcore_settings.alert_subset ~= nil and hardcore_settings.alert_subset == "faction_wide" then
		deathlog.alertIfValid(deathlog.death_ping_lru_cache_tbl[checksum]["player_data"])
		return
	end

	-- Override if players are in greenwall
	if deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["guild"] and hc_peer_guilds[deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["guild"]] then
		deathlog.alertIfValid(deathlog.death_ping_lru_cache_tbl[checksum]["player_data"])
		return
	end
end

function deathlog.receiveChannelMessage(sender, data)
	if data == nil then return end
	local decoded_player_data = deathlog.decodeMessage(data)
	if sender ~= decoded_player_data["name"] then return end
	if deathlog.isValidEntry(decoded_player_data) == false then return end

	local checksum = fletcher16(decoded_player_data["name"], decoded_player_data["guild"], decoded_player_data["level"])

	if deathlog.death_ping_lru_cache_tbl[checksum] == nil then
		deathlog.death_ping_lru_cache_tbl[checksum] = {}
	end

	if deathlog.death_ping_lru_cache_tbl[checksum]["player_data"] == nil then
		deathlog.death_ping_lru_cache_tbl[checksum]["player_data"] = decoded_player_data
	end

	if deathlog.death_ping_lru_cache_tbl[checksum]["committed"] then return end

	local guildName, _, _ = GetGuildInfo("player");
	if decoded_player_data['guild'] == guildName then
		local name_long = sender .. "-" .. GetNormalizedRealmName()
		for i = 1, GetNumGuildMembers() do
			local name, _, _, level, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
			if name_long == name and level == decoded_player_data["level"] then
				deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["in_guild"] = 1
				local delay = math.random(0, 10)
				C_Timer.After(delay, function()
					if deathlog.death_ping_lru_cache_tbl[checksum] and deathlog.death_ping_lru_cache_tbl[checksum]["committed"] then return end
					table.insert(deathlog.broadcast_death_ping_queue, checksum) -- Must be added to queue to be broadcasted to network
				end)
				break
			end
		end
	end

	deathlog.death_ping_lru_cache_tbl[checksum]["self_report"] = 1
	if deathlog.shouldCreateEntry(checksum) then
		deathlog.createEntry(checksum)
	end
end

function deathlog.receiveChannelMessageChecksum(sender, checksum)
	if checksum == nil then return end
	if deathlog.death_ping_lru_cache_tbl[checksum] == nil then
		deathlog.death_ping_lru_cache_tbl[checksum] = {}
	end
	if deathlog.death_ping_lru_cache_tbl[checksum]["committed"] then return end

	if deathlog.death_ping_lru_cache_tbl[checksum]["peers"] == nil then
		deathlog.death_ping_lru_cache_tbl[checksum]["peers"] = {}
	end

	if deathlog.death_ping_lru_cache_tbl[checksum]["peers"][sender] then return end
	deathlog.death_ping_lru_cache_tbl[checksum]["peers"][sender] = 1

	if deathlog.death_ping_lru_cache_tbl[checksum]["peer_report"] == nil then
		deathlog.death_ping_lru_cache_tbl[checksum]["peer_report"] = 0
	end

	deathlog.death_ping_lru_cache_tbl[checksum]["peer_report"] = deathlog.death_ping_lru_cache_tbl[checksum]
		["peer_report"] + 1
	if deathlog.shouldCreateEntry(checksum) then
		deathlog.createEntry(checksum)
	end
end

function deathlog.receiveLastWords(sender, data)
	if data == nil then return end
	local values = {}
	for w in data:gmatch("(.-)~") do table.insert(values, w) end
	local checksum = values[1]
	local msg = values[2]

	if checksum == nil or msg == nil then return end

	if deathlog.death_ping_lru_cache_tbl[checksum] == nil then
		deathlog.death_ping_lru_cache_tbl[checksum] = {}
	end
	if deathlog.death_ping_lru_cache_tbl[checksum]["player_data"] ~= nil then
		deathlog.death_ping_lru_cache_tbl[checksum]["player_data"]["last_words"] = msg
		deathlog.ui.SetLastWords(sender, msg)
	else
		deathlog.death_ping_lru_cache_tbl[checksum]["last_words"] = msg
	end
end

function deathlog:sendNextInQueue(command, queue)
	local channel_num = GetChannelName(death_alerts_channel)
	if channel_num == 0 then
		self:JoinChannel()
		return
	end

	local commMessage = command .. COMM_COMMAND_DELIM .. queue[1]
	CTL:SendChatMessage("BULK", COMM_NAME, commMessage, "CHANNEL", nil, channel_num)
	table.remove(queue, 1)
end

function deathlog:checkQueuesAndSend()
	if #self.broadcast_death_ping_queue > 0 then
		self:sendNextInQueue(COMM_COMMANDS["BROADCAST_DEATH_PING_CHECKSUM"], self.broadcast_death_ping_queue)
		return
	end

	if #self.death_alert_out_queue > 0 then
		self:sendNextInQueue(COMM_COMMANDS["BROADCAST_DEATH_PING"], self.death_alert_out_queue)
		return
	end

	if #self.last_words_queue > 0 then
		self:sendNextInQueue(COMM_COMMANDS["LAST_WORDS"], self.last_words_queue)
		return
	end
end

function deathlog.alertIfValid(_player_data)
	local race_info = C_CreatureInfo.GetRaceInfo(_player_data["race_id"])
	local race_str = race_info.raceName
	local class_str, _, _ = GetClassInfo(_player_data["class_id"])
	if class_str and RAID_CLASS_COLORS[class_str:upper()] then
		class_str = "|c" .. RAID_CLASS_COLORS[class_str:upper()].colorStr .. class_str .. "|r"
	end

	local level_str = tostring(_player_data["level"])
	local level_num = tonumber(_player_data["level"])
	local min_level = tonumber(hardcore_settings.minimum_show_death_alert_lvl) or 0
	if level_num < tonumber(min_level) then
		return
	end

	local map_info = nil
	local map_name = "?"
	if _player_data["map_id"] then
		map_info = C_Map.GetMapInfo(_player_data["map_id"])
	end
	if map_info then
		map_name = map_info.name
	end

	local msg = _player_data["name"] ..
		" the " ..
		(race_str or "") .. " " .. (class_str or "") .. " has died at level " .. level_str .. " in " .. map_name
	Hardcore:TriggerDeathAlert(msg)
end

function deathlog:CHAT_MSG_CHANNEL(...)
	local arg = { ... }
	local _, channel_name = string.split(" ", arg[4])
	if channel_name ~= death_alerts_channel then return end
	local command, msg = string.split(COMM_COMMAND_DELIM, arg[1])
	if command == COMM_COMMANDS["BROADCAST_DEATH_PING_CHECKSUM"] then
		local player_name_short, _ = string.split("-", arg[2])
		if shadowbanned[player_name_short] then return end

		if throttle_player[player_name_short] == nil then throttle_player[player_name_short] = 0 end
		throttle_player[player_name_short] = throttle_player[player_name_short] + 1
		if throttle_player[player_name_short] > 1000 then
			shadowbanned[player_name_short] = 1
		end

		deathlog.receiveChannelMessageChecksum(player_name_short, msg)
		if debug then print("checksum", msg) end
		return
	end

	if command == COMM_COMMANDS["BROADCAST_DEATH_PING"] then
		local player_name_short, _ = string.split("-", arg[2])
		if shadowbanned[player_name_short] then return end

		if throttle_player[player_name_short] == nil then throttle_player[player_name_short] = 0 end
		throttle_player[player_name_short] = throttle_player[player_name_short] + 1
		if throttle_player[player_name_short] > 1000 then
			shadowbanned[player_name_short] = 1
		end

		deathlog.receiveChannelMessage(player_name_short, msg)
		if debug then print("death ping", msg) end
		return
	end

	if command == COMM_COMMANDS["LAST_WORDS"] then
		local player_name_short, _ = string.split("-", arg[2])
		if shadowbanned[player_name_short] then return end

		if throttle_player[player_name_short] == nil then throttle_player[player_name_short] = 0 end
		throttle_player[player_name_short] = throttle_player[player_name_short] + 1
		if throttle_player[player_name_short] > 1000 then
			shadowbanned[player_name_short] = 1
		end

		deathlog.receiveLastWords(player_name_short, msg)
		if debug then print("last words", msg) end
		return
	end
end

function deathlog:COMBAT_LOG_EVENT_UNFILTERED(...)
	-- local time, token, hidding, source_serial, source_name, caster_flags, caster_flags2, target_serial, target_name, target_flags, target_flags2, ability_id, ability_name, ability_type, extraSpellID, extraSpellName, extraSchool = CombatLogGetCurrentEventInfo()
	local _, ev, _, _, source_name, _, _, target_guid, _, _, _, environmental_type, _, _, _, _, _ =
		CombatLogGetCurrentEventInfo()

	if not (source_name == PLAYER_NAME) then
		if not (source_name == nil) then
			if string.find(ev, "DAMAGE") ~= nil then
				self.last_attack_source = source_name
			end
		end
	end
	if ev == "ENVIRONMENTAL_DAMAGE" then
		if target_guid == UnitGUID("player") then
			if environmental_type == "Drowning" then
				self.last_attack_source = -2
			elseif environmental_type == "Falling" then
				self.last_attack_source = -3
			elseif environmental_type == "Fatigue" then
				self.last_attack_source = -4
			elseif environmental_type == "Fire" then
				self.last_attack_source = -5
			elseif environmental_type == "Lava" then
				self.last_attack_source = -6
			elseif environmental_type == "Slime" then
				self.last_attack_source = -7
			end
		end
	end
end

function deathlog:PLAYER_DEAD()
	local map = C_Map.GetBestMapForUnit("player")
	local instance_id = nil
	local position = nil
	if map then
		position = C_Map.GetPlayerMapPosition(map, "player")
	else
		local _, _, _, _, _, _, _, _instance_id, _, _ = GetInstanceInfo()
		instance_id = _instance_id
	end

	local guildName, _, _ = GetGuildInfo("player");
	local _, _, race_id = UnitRace("player")
	local _, _, class_id = UnitClass("player")
	local death_source = "-1"
	if self.last_attack_source then
		death_source = npc_to_id[self.last_attack_source]
	end

	deathMsg = deathlog.encodeMessage({
		name = UnitName("player"),
		guild = guildName,
		source_id = death_source,
		race_id = race_id,
		class_id = class_id,
		level = UnitLevel("player"),
		instance_id = instance_id,
		map_id = map,
		map_pos = position,
		guid = UnitGUID("player")
	})
	if deathMsg == nil then return end

	table.insert(deathlog.death_alert_out_queue, deathMsg)

	if deathlog.last_words == nil then return end
	if guildName == nil then guildName = "" end

	local checksum = fletcher16(UnitName("player"), guildName, UnitLevel("player"))
	local lastWordsMsg = checksum .. COMM_FIELD_DELIM .. deathlog.last_words .. COMM_FIELD_DELIM

	table.insert(deathlog.last_words_queue, lastWordsMsg)
end

function deathlog:setLastWords(...)
	local text, sn, LN, CN, p2, sF, zcI, cI, cB, unu, lI, senderGUID = ...
	if PLAYERGUID == nil then
		PLAYERGUID = UnitGUID("player")
	end

	if senderGUID ~= PLAYERGUID then
		return
	end

	self.last_words = text
end

function deathlog:CHAT_MSG_SAY(...)
	self:setLastWords(...)
end

function deathlog:CHAT_MSG_GUILD(...)
	self:setLastWords(...)
end

function deathlog:CHAT_MSG_PARTY(...)
	self:setLastWords(...)
end

function deathlog:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("CHAT_MSG_CHANNEL")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("CHAT_MSG_PARTY")
	self:RegisterEvent("CHAT_MSG_SAY")
	self:RegisterEvent("CHAT_MSG_GUILD")
end

function deathlog:startup()
	if type(addon) ~= "table" then
		-- only bind event listeners if we are inside wow
		return
	end

	-- event handling helper
	self:SetScript("OnEvent", function(self, event, ...)
		self[event](self, ...)
	end)

	self:RegisterEvent("PLAYER_LOGIN")
end

deathlog:startup()

return deathlog
