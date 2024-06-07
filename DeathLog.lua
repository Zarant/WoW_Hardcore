local AceGUI = LibStub("AceGUI-3.0")
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
local HC_DEATH_LOG_MAX = 1000

local death_alerts_channel = "hcdeathalertschannel"
local death_alerts_channel_pw = "hcdeathalertschannelpw"

local throttle_player = {}
local shadowbanned = {}
local shared_checksum_tbl = {}
local sent_shared_dl_idx = 1
local receive_shared_dl = false


local death_log_icon_frame = CreateFrame("frame")
death_log_icon_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
death_log_icon_frame:SetSize(40,40)
death_log_icon_frame:SetMovable(true)
death_log_icon_frame:EnableMouse(true)
death_log_icon_frame:Show()

local black_round_tex = death_log_icon_frame:CreateTexture(nil, "OVERLAY")
black_round_tex:SetPoint("CENTER", death_log_icon_frame, "CENTER", -5,4)
black_round_tex:SetDrawLayer("OVERLAY",2)
black_round_tex:SetHeight(40)
black_round_tex:SetWidth(40)
black_round_tex:SetTexture("Interface\\PVPFrame\\PVP-Separation-Circle-Cooldown-overlay")

local hc_fire_tex = death_log_icon_frame:CreateTexture(nil, "OVERLAY")
hc_fire_tex:SetPoint("CENTER", death_log_icon_frame, "CENTER", -6, 4)
hc_fire_tex:SetDrawLayer("OVERLAY",3)
hc_fire_tex:SetHeight(25)
hc_fire_tex:SetWidth(25)
hc_fire_tex:SetTexture("Interface\\AddOns\\Hardcore\\Media\\wowhc-emblem-white-red.blp")

local gold_ring_tex = death_log_icon_frame:CreateTexture(nil, "OVERLAY")
gold_ring_tex:SetPoint("CENTER", death_log_icon_frame, "CENTER", 0,0)
gold_ring_tex:SetDrawLayer("OVERLAY",2)
gold_ring_tex:SetHeight(50)
gold_ring_tex:SetWidth(50)
gold_ring_tex:SetTexture("Interface\\COMMON\\BlueMenuRing")

local environment_damage = {
  [-2] = "Drowning",
  [-3] = "Falling",
  [-4] = "Fatigue",
  [-5] = "Fire",
  [-6] = "Lava",
  [-7] = "Slime",
}

local function PlayerData(name, guild, source_id, race_id, class_id, level, instance_id, map_id, map_pos, date, last_words)
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
  }
end

local function isValidEntry(_player_data)
  if _player_data == nil then return false end
  if _player_data["source_id"] == nil then return false end
  if _player_data["race_id"] == nil or tonumber(_player_data["race_id"]) == nil or C_CreatureInfo.GetRaceInfo(_player_data["race_id"]) == nil then return false end
  if _player_data["class_id"] == nil or tonumber(_player_data["class_id"]) == nil or GetClassInfo(_player_data["class_id"]) == nil then return false end
  if _player_data["level"] == nil or _player_data["level"] < 0 or _player_data["level"] > 80 then return false end
  if _player_data["instance_id"] == nil and _player_data["map_id"] == nil then return false end
  return true
end

local WorldMapButton = WorldMapFrame:GetCanvas()
local death_tomb_frame = CreateFrame('frame', nil, WorldMapButton)
death_tomb_frame:SetAllPoints()
death_tomb_frame:SetFrameLevel(15000)

local death_tomb_frame_tex = death_tomb_frame:CreateTexture(nil, 'OVERLAY')
death_tomb_frame_tex:SetTexture("Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull")
death_tomb_frame_tex:SetDrawLayer("OVERLAY", 4)
death_tomb_frame_tex:SetHeight(25)
death_tomb_frame_tex:SetWidth(25)
death_tomb_frame_tex:Hide()

local death_tomb_frame_tex_glow = death_tomb_frame:CreateTexture(nil, 'OVERLAY')
death_tomb_frame_tex_glow:SetTexture("Interface\\Glues/Models/UI_HUMAN/GenericGlow64")
death_tomb_frame_tex_glow:SetDrawLayer("OVERLAY", 3)
death_tomb_frame_tex_glow:SetHeight(55)
death_tomb_frame_tex_glow:SetWidth(55)
death_tomb_frame_tex_glow:Hide()

local death_log_frame_font = "Fonts\\FRIZQT__.TTF"
local locale = GetLocale()
local non_english_locales = {
  koKR=1,
  zhCN=1,
  zhTW=1
}

if non_english_locales[locale] == 1 then
  death_log_frame_font = "Fonts\\2002.TTF"
end


local function encodeMessage(name, guild, source_id, race_id, class_id, level, instance_id, map_id, map_pos)
  if name == nil then return end
  -- if guild == nil then return end -- TODO 
  if tonumber(source_id) == nil then return end
  if tonumber(race_id) == nil then return end
  if tonumber(level) == nil then return end

  local loc_str = ""
  if map_pos then
    loc_str = string.format("%.4f,%.4f", map_pos.x, map_pos.y)
  end
  local comm_message = name .. COMM_FIELD_DELIM .. (guild or "") .. COMM_FIELD_DELIM .. source_id .. COMM_FIELD_DELIM .. race_id .. COMM_FIELD_DELIM .. class_id .. COMM_FIELD_DELIM .. level .. COMM_FIELD_DELIM .. (instance_id or "")  .. COMM_FIELD_DELIM .. (map_id or "") .. COMM_FIELD_DELIM .. loc_str .. COMM_FIELD_DELIM
  return comm_message
end

local function decodeMessage(msg)
  local values = {}
  for w in msg:gmatch("(.-)~") do table.insert(values, w) end
  if #values < 9 then
	-- Return something that causes the calling function to return on the isValidEntry check
	--print("Malformed deathlog message with " .. #values .. " data values")
	local malformed_player_data = PlayerData( "MalformedData", nil, nil, nil,nil,nil,nil,nil,nil,nil,nil )
	return malformed_player_data
  end
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
  local player_data = PlayerData(name, guild, source_id, race_id, class_id, level, instance_id, map_id, map_pos, date, last_words)
  return player_data
end

-- [checksum -> {name, guild, source, race, class, level, F's, location, last_words, location}]
local death_ping_lru_cache_tbl = {}
local death_ping_lru_cache_ll = {}
local broadcast_death_ping_queue = {}
local death_alert_out_queue = {}
local last_words_queue = {}
local f_log = {}

local function fletcher16(_player_data)
	local data = _player_data["name"] .. _player_data["guild"] .. _player_data["level"]
	local sum1 = 0
	local sum2 = 0
        for index=1,#data do
		sum1 = (sum1 + string.byte(string.sub(data,index,index))) % 255;
		sum2 = (sum2 + sum1) % 255;
        end
        return _player_data["name"] .. "-" .. bit.bor(bit.lshift(sum2,8), sum1)
end

function HardcoreDeathlog_beginReceiveSharedMsg()
  Hardcore:Print("Allowing incoming shared deathlog entries for 1 Hr. Reload to cancel")
  for _,v in ipairs(hardcore_settings["death_log_entries"]) do
    shared_checksum_tbl[fletcher16(v)] = 1
  end

  receive_shared_dl = true
  C_Timer.After(60*60, function()
    receive_shared_dl = false
  end)
end

function HardcoreDeathlog_beginSendSharedMsg(publish_func)
  C_Timer.NewTicker(.25, function(self)
    if sent_shared_dl_idx > #hardcore_settings["death_log_entries"] then
      self:Cancel()
    end
    v = hardcore_settings["death_log_entries"][sent_shared_dl_idx]
    local map_pos = {} 
    map_pos.x, map_pos.y = strsplit(",", v['map_pos'], 2)
    if map_pos.x == nil or map_pos.y == nil then
      map_pos = nil
    end
    msg = encodeMessage(v['name'], v['guild'], v['source_id'], v['race_id'], v['class_id'], v['level'], v['instance_id'], v['map_id'], map_pos)
    publish_func(msg)
    sent_shared_dl_idx = sent_shared_dl_idx + 1
  end)
end

function HardcoreDeathlog_receiveSharedMsg(msg)
  if receive_shared_dl == false then return end
  local player_data = decodeMessage(msg)
  local checksum = fletcher16(player_data)
  if shared_checksum_tbl[checksum] == nil then
    table.insert(hardcore_settings["death_log_entries"], player_data)
    shared_checksum_tbl[checksum]= 1
    if debug then
      print("Received " .. player_data['name'])
    end
  else
    if debug then
      print("Ignored " .. player_data['name'])
    end
  end
end


local death_log_cache = {}

local death_log_frame = AceGUI:Create("Deathlog")
death_log_frame.frame:SetMovable(false)
death_log_frame.frame:EnableMouse(false)
death_log_frame:SetTitle("Hardcore Death Log")
local subtitle_data = {
  {"Name", 70, function(_entry) return _entry.player_data["name"] or "" end},
  {"Class", 60, function(_entry)
    local class_str, class_file, _ = GetClassInfo(_entry.player_data["class_id"])
    if RAID_CLASS_COLORS[class_file] then
	return "|c" .. RAID_CLASS_COLORS[class_file].colorStr .. class_str .. "|r"
    end
    return class_str or ""
  end},
  {"Race", 60, function(_entry)
    local race_info = C_CreatureInfo.GetRaceInfo(_entry.player_data["race_id"]) 
    return race_info.raceName or ""
  end},
  {"Lvl", 30, function(_entry) return _entry.player_data["level"] or "" end},
}
death_log_frame:SetSubTitle(subtitle_data)
death_log_frame:SetLayout("Fill")
death_log_frame.frame:SetSize(255,125)
death_log_frame:Show()

local scroll_frame = AceGUI:Create("ScrollFrame")
scroll_frame:SetLayout("List")
death_log_frame:AddChild(scroll_frame)

hardcore_settings = {}
function deathlogApplySettings(_settings)
    hardcore_settings = _settings

    if hardcore_settings["death_log_show"] == nil or hardcore_settings["death_log_show"] == true then
      death_log_frame.frame:Show()
      death_log_icon_frame:Show()
    else
      death_log_frame.frame:Hide()
      death_log_icon_frame:Hide()
    end

    death_log_icon_frame:ClearAllPoints()
    death_log_frame.frame:ClearAllPoints()
    if death_log_frame.frame and hardcore_settings["death_log_pos"] then
      death_log_icon_frame:SetPoint("CENTER", UIParent, "CENTER", hardcore_settings["death_log_pos"]['x'], hardcore_settings["death_log_pos"]['y'])
    else
      death_log_icon_frame:SetPoint("CENTER", UIParent, "CENTER", 470, -100)
    end
    death_log_frame.frame:SetPoint("TOPLEFT", death_log_icon_frame, "TOPLEFT", 10, -10)
    death_log_frame.frame:SetFrameStrata("BACKGROUND")
    death_log_frame.frame:Lower()
end


local selected = nil
local row_entry = {}
 function WPDropDownDemo_Menu(frame, level, menuList)
  local info = UIDropDownMenu_CreateInfo()

   if death_tomb_frame.map_id and death_tomb_frame.coordinates then
   end

  local function openWorldMap()
   if not (death_tomb_frame.map_id and death_tomb_frame.coordinates) then return end
   if C_Map.GetMapInfo(death_tomb_frame["map_id"]) == nil then return end
   if tonumber(death_tomb_frame.coordinates[1]) == nil or tonumber(death_tomb_frame.coordinates[2]) == nil then return end

   WorldMapFrame:SetShown(not WorldMapFrame:IsShown())
   WorldMapFrame:SetMapID(death_tomb_frame.map_id)
   WorldMapFrame:GetCanvas()
   local mWidth, mHeight = WorldMapFrame:GetCanvas():GetSize()
   death_tomb_frame_tex:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', mWidth*death_tomb_frame.coordinates[1], -mHeight*death_tomb_frame.coordinates[2])
   death_tomb_frame_tex:Show()

   death_tomb_frame_tex_glow:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', mWidth*death_tomb_frame.coordinates[1], -mHeight*death_tomb_frame.coordinates[2])
   death_tomb_frame_tex_glow:Show()
   death_tomb_frame:Show()
  end
  
 
  if level == 1 then
   info.text, info.hasArrow, info.func, info.disabled = "Show death location (WIP)", false, openWorldMap, false
   UIDropDownMenu_AddButton(info)
   info.text, info.hasArrow, info.func, info.disabled = "Block user", false, openWorldMap, true
   UIDropDownMenu_AddButton(info)
   info.text, info.hasArrow, info.func, info.disabled = "Block user's guild", false, openWorldMap, true
   UIDropDownMenu_AddButton(info)
  end
 end

for i=1,20 do
	local idx = 21 - i
	row_entry[idx] = AceGUI:Create("InteractiveLabel")
	local _entry = row_entry[idx]
	_entry:SetHighlight("Interface\\Glues\\CharacterSelect\\Glues-CharacterSelect-Highlight")
	_entry.font_strings = {}
	local next_x = 0
	local current_column_offset = 15
	for idx,v in ipairs(subtitle_data) do 
	  _entry.font_strings[v[1]] = _entry.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	  _entry.font_strings[v[1]]:SetPoint("LEFT", _entry.frame, "LEFT", current_column_offset, 0)
	  current_column_offset = current_column_offset + v[2]
	  _entry.font_strings[v[1]]:SetJustifyH("LEFT")

	  if idx + 1 <= #subtitle_data then
	    _entry.font_strings[v[1]]:SetWidth(v[2])
	  end
	  _entry.font_strings[v[1]]:SetTextColor(1,1,1)
	  _entry.font_strings[v[1]]:SetFont(death_log_frame_font, 11, "")
	end

	_entry.background = _entry.frame:CreateTexture(nil, "OVERLAY")
	_entry.background:SetPoint("CENTER", _entry.frame, "CENTER", 0,0)
	_entry.background:SetDrawLayer("OVERLAY",2)
	_entry.background:SetVertexColor(.5, .5, .5, (i%2)/10)
	_entry.background:SetHeight(16)
	_entry.background:SetWidth(500)
	_entry.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

	_entry:SetHeight(40)
	_entry:SetFont(death_log_frame_font, 16, "")
	_entry:SetColor(1,1,1)
	_entry:SetText(" ")

	function _entry:deselect()
	    for _,v in pairs(_entry.font_strings) do
	      v:SetTextColor(1,1,1)
	    end
	end

	function _entry:select()
	    selected = idx 
	    for _,v in pairs(_entry.font_strings) do
	      v:SetTextColor(1,1,0)
	    end
	end

	_entry:SetCallback("OnLeave", function(widget)
		if _entry.player_data == nil then return end
		GameTooltip:Hide()
	end)

	_entry:SetCallback("OnClick", function()
		if _entry.player_data == nil then return end
		local click_type = GetMouseButtonClicked()

		if click_type == "LeftButton" then
		  if selected then row_entry[selected]:deselect() end
		  _entry:select()
		elseif click_type == "RightButton" then
		   local dropDown = CreateFrame("Frame", "WPDemoContextMenu", UIParent, "UIDropDownMenuTemplate")
		   -- Bind an initializer function to the dropdown; see previous sections for initializer function examples.
		   UIDropDownMenu_Initialize(dropDown, WPDropDownDemo_Menu, "MENU")
		   ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
		   if _entry["player_data"]["map_id"] and _entry["player_data"]["map_pos"] then
		     death_tomb_frame.map_id = _entry["player_data"]["map_id"] 
		     local x, y = strsplit(",", _entry["player_data"]["map_pos"],2)
		     death_tomb_frame.coordinates = {x,y}
		   end
		end
	end)

	_entry:SetCallback("OnEnter", function(widget)
		if _entry.player_data == nil then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, WorldFrame)

		if string.sub(_entry.player_data["name"], #_entry.player_data["name"]) == "s" then
		  GameTooltip:AddDoubleLine(_entry.player_data["name"] .. "' Death", "Lvl. " .. _entry.player_data["level"], 1, 1, 1, .5 ,.5, .5);

		else
		  GameTooltip:AddDoubleLine(_entry.player_data["name"] .. "'s Death", "Lvl. " .. _entry.player_data["level"], 1, 1, 1, .5 ,.5, .5);
		end
		GameTooltip:AddLine("Name: " .. _entry.player_data["name"],1,1,1)
		GameTooltip:AddLine("Guild: " .. _entry.player_data["guild"],1,1,1)

		local race_info = C_CreatureInfo.GetRaceInfo(_entry.player_data["race_id"]) 
		if race_info then GameTooltip:AddLine("Race: " .. race_info.raceName,1,1,1) end

		if _entry.player_data["class_id"] then
		  local class_str, _, _ = GetClassInfo(_entry.player_data["class_id"])
		  if class_str then GameTooltip:AddLine("Class: " .. class_str,1,1,1) end
		end

		if _entry.player_data["source_id"] then
		  local source_id = id_to_npc[_entry.player_data["source_id"]]
		  if source_id then 
		    GameTooltip:AddLine("Killed by: " .. source_id, 1, 1, 1, true) 
		  elseif environment_damage[_entry.player_data["source_id"]] then
		    GameTooltip:AddLine("Died from: " .. environment_damage[_entry.player_data["source_id"]], 1, 1, 1, true) 
		  end
		end

		if race_name then GameTooltip:AddLine("Race: " .. race_name,1,1,1) end

		if _entry.player_data["map_id"] then
		  local map_info = C_Map.GetMapInfo(_entry.player_data["map_id"])
		  if map_info then GameTooltip:AddLine("Zone: " .. map_info.name, 1, 1, 1, true) end
		end

		if _entry.player_data["map_pos"] then
		  GameTooltip:AddLine("Loc: " .. _entry.player_data["map_pos"], 1, 1, 1, true)
		end

		if _entry.player_data["date"] then
		  GameTooltip:AddLine("Date: " .. _entry.player_data["date"], 1, 1, 1, true)
		end

		if _entry.player_data["last_words"] then
		  GameTooltip:AddLine("Last words: " .. _entry.player_data["last_words"],1,1,0,true)
		end
		GameTooltip:Show()
	end)

	scroll_frame:SetScroll(0)
	scroll_frame.scrollbar:Hide()
	scroll_frame:AddChild(_entry)
end

local function setEntry(player_data, _entry)
	_entry.player_data = player_data
	for _,v in ipairs(subtitle_data) do 
	  _entry.font_strings[v[1]]:SetText(v[3](_entry))
	end
end

local function shiftEntry(_entry_from, _entry_to)
  setEntry(_entry_from.player_data, _entry_to)
end

local function alertIfValid(_player_data)
  local race_info = C_CreatureInfo.GetRaceInfo(_player_data["race_id"])
  local race_str = race_info.raceName
  local class_str, class_file, _ = GetClassInfo(_player_data["class_id"])
  if class_str and RAID_CLASS_COLORS[class_file] then
      class_str = "|c" .. RAID_CLASS_COLORS[class_file].colorStr .. class_str .. "|r"
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

  local msg = _player_data["name"] .. " the " .. (race_str or "") .. " "  .. (class_str or "") .. " has died at level " .. level_str .. " in " .. map_name
  Hardcore:TriggerDeathAlert(msg)
end

local function createEntry(checksum)
  for i=1,19 do 
    if row_entry[i+1].player_data ~= nil then
      shiftEntry(row_entry[i+1], row_entry[i])
      if selected and selected == i+1 then
	row_entry[i+1]:deselect()
	row_entry[i]:select()
      end
    end
  end
  death_ping_lru_cache_tbl[checksum]["player_data"]["date"] = date()
  setEntry(death_ping_lru_cache_tbl[checksum]["player_data"], row_entry[20])
  death_ping_lru_cache_tbl[checksum]["committed"] = 1

  -- Record to hardcore_settings
  if hardcore_settings["death_log_entries"] == nil then
    hardcore_settings["death_log_entries"] = {}
  end
  table.insert(hardcore_settings["death_log_entries"], death_ping_lru_cache_tbl[checksum]["player_data"])

  -- Cap list size, otherwise loading time will increase
  if hardcore_settings["death_log_entries"] and #hardcore_settings["death_log_entries"] > HC_DEATH_LOG_MAX then -- TODO parameterize
    table.remove(hardcore_settings["death_log_entries"],1)
  end

  -- Save in-guilds for next part of migration TODO
  if death_ping_lru_cache_tbl[checksum]["player_data"]["in_guild"] then return end
  if hardcore_settings.alert_subset ~= nil and hardcore_settings.alert_subset == "greenwall_guilds_only" and death_ping_lru_cache_tbl[checksum]["player_data"]["guild"] and hc_peer_guilds[death_ping_lru_cache_tbl[checksum]["player_data"]["guild"]] then
    alertIfValid(death_ping_lru_cache_tbl[checksum]["player_data"])
    return
  end
  if hardcore_settings.alert_subset ~= nil and hardcore_settings.alert_subset == "faction_wide" then
    alertIfValid(death_ping_lru_cache_tbl[checksum]["player_data"])
    return
  end

  -- Override if players are in greenwall
  if death_ping_lru_cache_tbl[checksum]["player_data"]["guild"] and hc_peer_guilds[death_ping_lru_cache_tbl[checksum]["player_data"]["guild"]] then
    alertIfValid(death_ping_lru_cache_tbl[checksum]["player_data"])
    return
  end
end

local function shouldCreateEntry(checksum)
  if death_ping_lru_cache_tbl[checksum] == nil then return false end
  if death_ping_lru_cache_tbl[checksum]["player_data"] == nil then return false end
  if hardcore_settings.death_log_types == nil or hardcore_settings.death_log_types == "faction_wide" and isValidEntry(death_ping_lru_cache_tbl[checksum]["player_data"]) then
    if death_ping_lru_cache_tbl[checksum]["peer_report"] and death_ping_lru_cache_tbl[checksum]["peer_report"] > HC_REQUIRED_ACKS then
      return true
    else
      if debug then
	print("not enough peers for " .. checksum .. ": " .. (death_ping_lru_cache_tbl[checksum]["peer_report"] or "0"))
      end
    end
  end
  if hardcore_settings.death_log_types ~= nil and hardcore_settings.death_log_types == "greenwall_guilds_only" and death_ping_lru_cache_tbl[checksum]["player_data"] and death_ping_lru_cache_tbl[checksum]["player_data"]["guild"] and hc_peer_guilds[death_ping_lru_cache_tbl[checksum]["player_data"]["guild"]] then return true end
  if death_ping_lru_cache_tbl[checksum]["in_guild"] then return true end

  return false
end

function selfDeathAlertLastWords(last_words)
	if last_words == nil then return end
	local _, _, race_id = UnitRace("player")
	local _, _, class_id = UnitClass("player")
	local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
	if guildName == nil then guildName = "" end
	local death_source = "-1"
	if DeathLog_Last_Attack_Source then
	  death_source = npc_to_id[death_source_str]
	end

	local player_data = PlayerData(UnitName("player"), guildName, nil, nil, nil, UnitLevel("player"), nil, nil, nil, nil, nil)
	local checksum = fletcher16(player_data)
	local msg = checksum .. COMM_FIELD_DELIM .. last_words .. COMM_FIELD_DELIM

	table.insert(last_words_queue, msg)
end

function selfDeathAlert(death_source_str)
	local map = C_Map.GetBestMapForUnit("player")
	local instance_id = nil
	local position = nil
	if map then 
		position = C_Map.GetPlayerMapPosition(map, "player")
		--local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(map, position)   -- BREAKS IN DUNGEONS
	else
	  local _, _, _, _, _, _, _, _instance_id, _, _ = GetInstanceInfo()
	  instance_id = _instance_id
	end

	local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
	local _, _, race_id = UnitRace("player")
	local _, _, class_id = UnitClass("player")
	local death_source = "-1"
	if DeathLog_Last_Attack_Source then
	  death_source = npc_to_id[death_source_str]
	end

	if DeathLog_Last_Attack_Source and environment_damage[death_source_str] then
		death_source = death_source_str
	end

	msg = encodeMessage(UnitName("player"), guildName, death_source, race_id, class_id, UnitLevel("player"), instance_id, map, position)
	if msg == nil then return end
	local channel_num = GetChannelName(death_alerts_channel)

	table.insert(death_alert_out_queue, msg)
end

-- Receive a guild message. Need to send ack
function deathlogReceiveLastWords(sender, data)
  if data == nil then return end
  local values = {}
  for w in data:gmatch("(.-)~") do table.insert(values, w) end
  local checksum = values[1]
  local msg = values[2]

  if checksum == nil or msg == nil then return end

  if death_ping_lru_cache_tbl[checksum] == nil then
    death_ping_lru_cache_tbl[checksum] = {}
  end
  if death_ping_lru_cache_tbl[checksum]["player_data"] ~= nil then
    death_ping_lru_cache_tbl[checksum]["player_data"]["last_words"] = msg
    for i=1,20 do 
      if row_entry[i].player_data ~= nil then
	if row_entry[i].player_data["name"] == sender then
	  row_entry[i].player_data["last_words"] = msg
	end
      end
    end
  else
    death_ping_lru_cache_tbl[checksum]["last_words"] = msg
  end
end

-- Receive a guild message. Need to send ack
function deathlogReceiveGuildMessage(sender, data)
  if data == nil then return end
  local decoded_player_data = decodeMessage(data)
  if sender ~= decoded_player_data["name"] then return end
  if isValidEntry(decoded_player_data) == false then return end

  local valid = false
  for i = 1, GetNumGuildMembers() do
	  local name, _, _, level, class_str, _, _, _, _, _, class = GetGuildRosterInfo(i)
	  if name == sender and level == decoded_player_data["level"] then
	    valid = true
	  end
  end
  if valid == false then return end

  local checksum = fletcher16(decoded_player_data)

  if death_ping_lru_cache_tbl[checksum] == nil then
    death_ping_lru_cache_tbl[checksum] = {
      ["player_data"] = player_data,
    }
  end

  if death_ping_lru_cache_tbl[checksum]["last_words"] ~= nil then
    death_ping_lru_cache_tbl[checksum]["player_data"]["last_words"] = death_ping_lru_cache_tbl[checksum]["last_words"]
  end

  if death_ping_lru_cache_tbl[checksum]["committed"] then return end

  death_ping_lru_cache_tbl[checksum]["self_report"] = 1
  death_ping_lru_cache_tbl[checksum]["in_guild"] = 1
  table.insert(broadcast_death_ping_queue, checksum) -- Must be added to queue to be broadcasted to network
  if shouldCreateEntry(checksum) then
    createEntry(checksum)
  end
end

local function deathlogReceiveChannelMessageChecksum(sender, checksum)
  if checksum == nil then return end
  if death_ping_lru_cache_tbl[checksum] == nil then
    death_ping_lru_cache_tbl[checksum] = {}
  end
  if death_ping_lru_cache_tbl[checksum]["committed"] then return end

  if death_ping_lru_cache_tbl[checksum]["peers"] == nil then
    death_ping_lru_cache_tbl[checksum]["peers"] = {}
  end

  if death_ping_lru_cache_tbl[checksum]["peers"][sender] then return end
  death_ping_lru_cache_tbl[checksum]["peers"][sender] = 1

  if death_ping_lru_cache_tbl[checksum]["peer_report"] == nil then
    death_ping_lru_cache_tbl[checksum]["peer_report"] = 0
  end

  death_ping_lru_cache_tbl[checksum]["peer_report"] = death_ping_lru_cache_tbl[checksum]["peer_report"] + 1
  if shouldCreateEntry(checksum) then
    createEntry(checksum)
  end
end

local function deathlogReceiveChannelMessage(sender, data)
  if data == nil then return end
  local decoded_player_data = decodeMessage(data)
  if sender ~= decoded_player_data["name"] then return end
  if isValidEntry(decoded_player_data) == false then return end

  local checksum = fletcher16(decoded_player_data)

  if death_ping_lru_cache_tbl[checksum] == nil then
    death_ping_lru_cache_tbl[checksum] = {}
  end

  if death_ping_lru_cache_tbl[checksum]["player_data"] == nil then
      death_ping_lru_cache_tbl[checksum]["player_data"] = decoded_player_data
  end

  if death_ping_lru_cache_tbl[checksum]["committed"] then return end

  local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
  if decoded_player_data['guild'] == guildName then
    local name_long = sender .. "-" .. GetNormalizedRealmName()
    for i = 1, GetNumGuildMembers() do
	    local name, _, _, level, class_str, _, _, _, _, _, class = GetGuildRosterInfo(i)
	    if name_long == name and level == decoded_player_data["level"] then
	      death_ping_lru_cache_tbl[checksum]["player_data"]["in_guild"] = 1
	      local delay = math.random(0,10)
	      C_Timer.After(delay, function()
		if death_ping_lru_cache_tbl[checksum] and death_ping_lru_cache_tbl[checksum]["committed"] then return end
		table.insert(broadcast_death_ping_queue, checksum) -- Must be added to queue to be broadcasted to network
	      end)
	      break
	    end
    end
  end

  death_ping_lru_cache_tbl[checksum]["self_report"] = 1
  if shouldCreateEntry(checksum) then
    createEntry(checksum)
  end
end

function deathlogReceiveF(sender, data)
  local checksum = decodeF()
  if f_log[checksum] == nil then
    f_log[checksum] = {
      ["num"] = 0,
    }
  end

  if f_log[checksum][sender] == nil then
    f_log[checksum][sender] = 1
    f_log[checksum]["num"] = f_log[checksum]["num"] + 1
  end
end

function deathlogJoinChannel()
        JoinChannelByName(death_alerts_channel, death_alerts_channel_pw)
	local channel_num = GetChannelName(death_alerts_channel)
        if channel_num == 0 then
	  print("Failed to join death alerts channel")
	else
	  print("Successfully joined deathlog channel.")
	end

	for i = 1, 10 do
	  if _G['ChatFrame'..i] then
	    ChatFrame_RemoveChannel(_G['ChatFrame'..i], death_alerts_channel)
	  end
	end
end

local function sendNextInQueue()
	if #broadcast_death_ping_queue > 0 then 
		local channel_num = GetChannelName(death_alerts_channel)
		if channel_num == 0 then
		  deathlogJoinChannel()
		  return
		end

		local commMessage = COMM_COMMANDS["BROADCAST_DEATH_PING_CHECKSUM"] .. COMM_COMMAND_DELIM .. broadcast_death_ping_queue[1]
		CTL:SendChatMessage("BULK", COMM_NAME, commMessage, "CHANNEL", nil, channel_num)
		table.remove(broadcast_death_ping_queue, 1)
		return
	end

	if #death_alert_out_queue > 0 then 
		local channel_num = GetChannelName(death_alerts_channel)
		if channel_num == 0 then
		  deathlogJoinChannel()
		  return
		end
		local commMessage = COMM_COMMANDS["BROADCAST_DEATH_PING"] .. COMM_COMMAND_DELIM .. death_alert_out_queue[1]
		CTL:SendChatMessage("BULK", COMM_NAME, commMessage, "CHANNEL", nil, channel_num)
		table.remove(death_alert_out_queue, 1)
		return
	end

	if #last_words_queue > 0 then 
		local channel_num = GetChannelName(death_alerts_channel)
		if channel_num == 0 then
		  deathlogJoinChannel()
		  return
		end
		local commMessage = COMM_COMMANDS["LAST_WORDS"] .. COMM_COMMAND_DELIM .. last_words_queue[1]
		CTL:SendChatMessage("BULK", COMM_NAME, commMessage, "CHANNEL", nil, channel_num)
		table.remove(last_words_queue, 1)
		return
	end
end

-- Note: We can only send at most 1 message per click, otherwise we get a taint
WorldFrame:HookScript("OnMouseDown", function(self, button)
  sendNextInQueue()
end)

-- This binds any key press to send, including hitting enter to type or esc to exit game
local f  = Test or CreateFrame("Frame", "Test", UIParent)
f:SetScript("OnKeyDown", sendNextInQueue)
f:SetPropagateKeyboardInput(true)

death_log_icon_frame:RegisterForDrag("LeftButton")
death_log_icon_frame:SetScript("OnDragStart", function(self, button)
	self:StartMoving()
end)
death_log_icon_frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local x,y = self:GetCenter()
	local px = (GetScreenWidth() * UIParent:GetEffectiveScale())/2
	local py = (GetScreenHeight() * UIParent:GetEffectiveScale())/2
	if hardcore_settings['death_log_pos'] == nil then
	  hardcore_settings['death_log_pos'] = {}
	end
	hardcore_settings['death_log_pos']['x'] = x - px
	hardcore_settings['death_log_pos']['y'] = y - py
end)

 function DeathFrameDropdown(frame, level, menuList)
  local info = UIDropDownMenu_CreateInfo()

  local function minimize()
   death_log_frame:Minimize()
  end

  local function maximize()
   death_log_frame:Maximize()
  end

  local function hide()
   death_log_frame.frame:Hide()
   death_log_icon_frame:Hide()
   hardcore_settings["death_log_show"] = false
  end

  local function openSettings()
    InterfaceOptionsFrame_Show()
    InterfaceOptionsFrame_OpenToCategory("Hardcore")
  end

  if level == 1 then
   if death_log_frame:IsMinimized() then
     info.text, info.hasArrow, info.func = "Maximize", false, maximize 
     UIDropDownMenu_AddButton(info)
   else
     info.text, info.hasArrow, info.func = "Minimize", false, minimize 
     UIDropDownMenu_AddButton(info)
   end

   info.text, info.hasArrow, info.func = "Settings", false, openSettings 
   UIDropDownMenu_AddButton(info)

   info.text, info.hasArrow, info.func = "Hide", false, hide
   UIDropDownMenu_AddButton(info)
  end
 end

death_log_icon_frame:SetScript("OnMouseDown", function (self, button)
    if button=='RightButton' then 
	   local dropDown = CreateFrame("Frame", "death_frame_dropdown_menu", UIParent, "UIDropDownMenuTemplate")
	   UIDropDownMenu_Initialize(dropDown, DeathFrameDropdown, "MENU")
	   ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
    end
end)

local death_log_handler = CreateFrame("Frame")
death_log_handler:RegisterEvent("CHAT_MSG_CHANNEL")

local function handleEvent(self, event, ...)
  local arg = { ... }
  if event == "CHAT_MSG_CHANNEL" then
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

      deathlogReceiveChannelMessageChecksum(player_name_short, msg)
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

      deathlogReceiveChannelMessage(player_name_short, msg)
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

      deathlogReceiveLastWords(player_name_short, msg)
      if debug then print("last words" ,msg) end
      return
    end
  end
end

death_log_handler:SetScript("OnEvent", handleEvent)

-- This function is for testing; only sends to self
function fakeDeathAlert(event, msg, sender)
	handleEvent(death_log_handler, event, msg, sender)
end

hooksecurefunc(WorldMapFrame, 'OnMapChanged', function()
  death_tomb_frame:Hide()
end)
