local debug = false
local CTL = _G.ChatThrottleLib
local COMM_NAME = "HCAB"

-- CHECKSUM: GUID .. DATA
local COMM_COMMANDS = {
  ["UPDATE"] = "1", -- 1$<Last4GUID>~<DATA>
  ["REQUEST"] = "2", -- 2$<Last4GUID>
  ["REQUEST_ACK"] = "3", -- 3$<VALID>~<DATA>
  ["POST_HC_FAILURE"] = "4", -- 4$<Last4GUID>
}
local COMM_COMMAND_DELIM = "{"
local COMM_FIELD_DELIM = "}"

local found_invalid = false
local received_acks = {}

local function recoverData(_hardcore_character)
  for _,v in ipairs(received_acks) do
    local tracked_time, first_recorded, achievements_list, passive_achievements_list = Hardcore_VerifyRecoveryCode(Hardcore_Character, v)
    if tracked_time and _hardcore_character.time_tracked and tracked_time > _hardcore_character.time_tracked and tracked_time <= _hardcore_character.time_played then
      _hardcore_character.time_tracked = tonumber(tracked_time)
      _hardcore_character.tracked_played_percentage = _hardcore_character.time_tracked / _hardcore_character.time_played * 100.0
       Hardcore:Print("Recovered tracked time: " .. string.format("%.1f", _hardcore_character.tracked_played_percentage) .. "%")
    end

    if first_recorded and _hardcore_character.first_recorded == -1 then
      _hardcore_character.first_recorded = first_recorded
       Hardcore:Print("Recovered start date.")
    end

    if achievements_list then
      for _,v in ipairs(achievements_list) do
	local found = false
	for _,v2 in ipairs(_hardcore_character.achievements) do
	  if v == v2 then found = true end
	end
	if found == false then 
	  table.insert(_hardcore_character.achievements, v)
	  Hardcore:Print("Recovered achievement: " .. v)
	end
      end
    end

    if passive_achievements_list then
      for _,v in ipairs(passive_achievements_list) do
	local found = false
	for _,v2 in ipairs(_hardcore_character.passive_achievements) do
	  if v == v2 then found = true end
	end
	if found == false then 
	  table.insert(_hardcore_character.passive_achievements, v)
	  Hardcore:Print("Recovered achievement: " .. v)
	end
      end
    end
  end
end

function Hardcore_SendAutomaticBackupUpdate(_hardcore_character)
  local recovery_code = Hardcore_GenerateRecoveryCode(_hardcore_character)
  local last_four_guid = string.sub(UnitGUID("player"), -4)
  local commMessage = COMM_COMMANDS["UPDATE"] .. COMM_COMMAND_DELIM .. last_four_guid .. COMM_FIELD_DELIM .. recovery_code 
  CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")
end

function Hardcore_SendAutomaticBackupDataRequest(_hardcore_character)
  found_invalid = false
  local last_four_guid = string.sub(UnitGUID("player"), -4)
  local commMessage = COMM_COMMANDS["REQUEST"] .. COMM_COMMAND_DELIM .. last_four_guid
  CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")

  C_Timer.After(5, function()
    if found_invalid == false then recoverData(_hardcore_character) end
  end)
end

function Hardcore_SendRequestAck(_hardcore_automatic_backup_data, request_name, request_last_four_guid)
  if _hardcore_automatic_backup_data[request_name .. request_last_four_guid] == nil then return end
  if _hardcore_automatic_backup_data[request_name .. request_last_four_guid]["valid"] == nil then return end 
  local commMessage = COMM_COMMANDS["REQUEST_ACK"] .. COMM_COMMAND_DELIM .. tostring(_hardcore_automatic_backup_data[request_name .. request_last_four_guid]["valid"]) .. COMM_FIELD_DELIM .. _hardcore_automatic_backup_data[request_name .. request_last_four_guid]["data"]
  CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")
end

function Hardcore_SendPostFailure()
  local last_four_guid = string.sub(UnitGUID("player"), -4)
  local commMessage = COMM_COMMANDS["POST_HC_FAILURE"] .. COMM_COMMAND_DELIM .. last_four_guid
  CTL:SendAddonMessage("BULK", COMM_NAME, commMessage, "GUILD")
end

local automatic_backup_event_handler = CreateFrame("Frame")
automatic_backup_event_handler:RegisterEvent("CHAT_MSG_ADDON")

local function handleAutomaticBackupEvent(self, event, prefix, datastr, scope, sender)
	if COMM_NAME == prefix then
		local command, comm_postfix = string.split(COMM_COMMAND_DELIM, datastr)
		local sender_short, _ = string.split("-", sender)
		if debug then print("Debug:", command, data_str, comm_postfix, sender_short) end
		if command == COMM_COMMANDS["UPDATE"] then
		  if comm_postfix == nil then return end
		  local last_four_guid, data = strsplit(COMM_FIELD_DELIM, comm_postfix, 2)
		  if last_four_guid == nil then return end
		  if data == nil then return end
		  if Hardcore_Automatic_Backup_Data == nil then Hardcore_Automatic_Backup_Data = {} end
		  if Hardcore_Automatic_Backup_Data[sender_short .. last_four_guid] == nil then
		    Hardcore_Automatic_Backup_Data[sender_short .. last_four_guid] = {
		      ["valid"] = true,
		    }
		  end
		  Hardcore_Automatic_Backup_Data[sender_short .. last_four_guid]["data"] = data
		elseif command == COMM_COMMANDS["REQUEST"] then
		  local last_four_guid = strsplit(COMM_FIELD_DELIM, comm_postfix, 1)
		  Hardcore_SendRequestAck(Hardcore_Automatic_Backup_Data, sender_short, comm_postfix) 
		elseif command == COMM_COMMANDS["REQUEST_ACK"] then
		  if comm_postfix == nil then return end
		  local valid, data = strsplit(COMM_FIELD_DELIM, comm_postfix, 2)
		  if valid == nil then return end
		  if data == nil then return end
		  if valid == false then
		    found_invalid = true
		    return
		  end
		  table.insert(received_acks, data)
		elseif command == COMM_COMMANDS["POST_HC_FAILURE"] then
		  local last_four_guid = strsplit(COMM_FIELD_DELIM, comm_postfix, 1)
		  if last_four_guid == nil then return end
		  if Hardcore_Automatic_Backup_Data == nil then Hardcore_Automatic_Backup_Data = {} end
		  if Hardcore_Automatic_Backup_Data[sender_short .. last_four_guid] == nil then Hardcore_Automatic_Backup_Data[sender_short .. last_four_guid] = {} end
		  Hardcore_Automatic_Backup_Data[sender_short .. last_four_guid]["valid"] = false
		end
	end
end
automatic_backup_event_handler:SetScript("OnEvent", handleAutomaticBackupEvent)
