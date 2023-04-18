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
local debug = false

-- Comms unit tests 
-- DO NOT TEST ON VALID CHARACTERS; this test might modify data if it fails
-- To run, uncomment tests.lua in Hardcore_Classic/Wotlk.toc
-- Hardcore_TestRecoveryCode(Hardcore_Character)
-- Hardcore_TestAutomaticBackupUpdate(Hardcore_Character)
-- 
local function testRecoveryCode(hardcore_character, player_name, last_four_guid)
	local code = Hardcore_GenerateRecoveryCode(hardcore_character, player_name, last_four_guid)
	if debug then Hardcore:Print("Testing recovery code: \n" .. code ..  "\nLength: " .. #code) end
	local time_tracked, first_recorded, achievement_list, passive_achievements_list = Hardcore_VerifyRecoveryCode(Hardcore_Character, code)
	assert(time_tracked == hardcore_character.time_tracked)
	if debug then Hardcore:Print("Hardcore_TestRecoverCode::time_tracked_test: |cFF00FF00Pass|r") end
	assert(first_recorded == hardcore_character.first_recorded, "Hardcore_TestRecoverCode::time_tracked_test: Failed " .. first_recorded)
	if debug then Hardcore:Print("Hardcore_TestRecoverCode::first_recorded: Pass") end
	for _,v in ipairs(achievement_list) do
	  local found = false
	  for _,v2 in ipairs(hardcore_character.achievements) do
	    if v == v2 then found = true end
	  end
	  assert(found)
	  if debug then Hardcore:Print("Hardcore_TestRecoverCode::achievements: Pass") end
	end

	for _,v in ipairs(passive_achievements_list) do
	  local found = false
	  for _,v2 in ipairs(hardcore_character.passive_achievements) do
	    if v == v2 then found = true end
	  end
	  assert(found)
	  if debug then Hardcore:Print("Hardcore_TestRecoverCode::passive_achievements: Pass") end
	end
	return true
end

local function testTamperedRecoveryCode(hardcore_character, player_name, last_four_guid)
	local code = Hardcore_GenerateRecoveryCode(hardcore_character, player_name, last_four_guid)
	if debug then Hardcore:Print("Testing recovery code: \n" .. code ..  "\nLength: " .. #code) end
	code = code .. "a"
	local time_tracked, first_recorded, achievement_list, passive_achievements_list = Hardcore_VerifyRecoveryCode(Hardcore_Character, code)
	assert(time_tracked == nil)
	return true
end

local function testAutomaticBackupFull(_hardcore_character, force_send_request)
	local time_tracked = _hardcore_character.time_played
	_hardcore_character.time_tracked = _hardcore_character.time_played
	_hardcore_character.first_recorded = GetServerTime()  
	local first_recorded = GetServerTime() 
	table.insert(_hardcore_character.achievements, "Hammertime")
	table.insert(_hardcore_character.passive_achievements, "Vagash")
	Hardcore:Print("Testing Automatic backup. Test takes 12 seconds ...")
	Hardcore_SendAutomaticBackupUpdate(_hardcore_character)
	_hardcore_character.time_tracked = -1
	_hardcore_character.first_recorded = -1
	_hardcore_character.achievements = {}
	_hardcore_character.passive_achievements = {}
	local last_four_guid = string.sub(UnitGUID("player"), -4)

	if Hardcore_Automatic_Backup_Data == nil then Hardcore_Automatic_Backup_Data = {} end
	Hardcore_Automatic_Backup_Data[UnitName("player") .. last_four_guid] = nil
	if force_send_request then
	  C_Timer.After(5.0, function()
	    assert(Hardcore_Automatic_Backup_Data[UnitName("player") .. last_four_guid])
	    Hardcore_SendAutomaticBackupDataRequest(_hardcore_character)
	  end)
	end

	C_Timer.After(12.0, function()
	  assert(abs(_hardcore_character.time_tracked - time_tracked) < 50, "Test time tracked recovery failed. " .. _hardcore_character.time_tracked .. " " .. time_tracked)
	  if debug then Hardcore:Print("Test time tracked recovery: Passed") end

	  assert(abs(first_recorded - _hardcore_character.first_recorded) < 5)
	  if debug then Hardcore:Print("Test first recorded recovery: Passed") end

	  local found = false
	  for _,v in ipairs(_hardcore_character.achievements) do
	    if v == "Hammertime" then found = true end
	  end
	  assert(found)
	  if debug then Hardcore:Print("Test achievement recovery: Passed") end

	  for _,v in ipairs(_hardcore_character.passive_achievements) do
	    if v == "Vagash" then found = true end
	  end
	  assert(found)
	  if debug then Hardcore:Print("Test passive achievement recovery: Passed") end
	  Hardcore:Print("Test automatic backup test: |cFF00FF00Passed|r")
	end)
	return true
end

local function testRecoveryCodeSuite()
  -- Self
  local player_name = UnitGUID("player")
  local last_four_guid = string.sub(UnitGUID("player"), -4)
  if Hardcore_Character.time_tracked == nil then Hardcore_Character.time_tracked = Hardcore_Character.time_played end
  if Hardcore_Character.first_recorded == nil or Hardcore_Character.first_recorded == -1 then Hardcore_Character.first_recorded = GetServerTime() end
  assert(testRecoveryCode(Hardcore_Character, player_name, last_four_guid), "Failed self recovery code test.")
  Hardcore:Print("Test self recovery code test: |cFF00FF00Passed|r")

  -- Some fake
  hardcore_character = {
    ["time_tracked"] = 12345, 
    ["achievements"] = {"Hammertime", "ElementalBalance", "Arcanist"}, 
    ["passive_achievements"] = {"Vagash"}, 
    ["first_recorded"] = 12321, 
  }

  assert(testRecoveryCode(hardcore_character, "some_name", "9988"), "Failed fake recovery code test.")
  Hardcore:Print("Test fake recovery code test: |cFF00FF00Passed|r")
  assert(testTamperedRecoveryCode(hardcore_character, "some_name", "9988"), "Failed tampered recovery code test.")
  Hardcore:Print("Test tampered recovery code test: |cFF00FF00Passed|r")

  testAutomaticBackupFull(Hardcore_Character, true)
end


local hardcore_test_event_handler = CreateFrame("frame")
hardcore_test_event_handler:RegisterEvent("PLAYER_LOGIN")

hardcore_test_event_handler:SetScript("OnEvent", function()
  Hardcore_Automatic_Backup_Data = nil
  testRecoveryCodeSuite()
end)
