local _G = _G
local penta_rules = CreateFrame("Frame")
_G.extra_rules.Penta = penta_rules

local max_warn_time = 10 * 60 -- Fails after 10 minutes
local check_rate = 15 -- Checks every 15 seconds
-- General info
penta_rules.name = "Penta"
penta_rules.title = "Penta"
penta_rules.class = "All"
penta_rules.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_default.blp"
penta_rules.description = ""
penta_rules.minimap_button_info = {}
penta_rules.minimap_button = nil
penta_rules.warn_reason = ""

local minimap_button = LibStub("LibDataBroker-1.1"):NewDataObject("Penta", {
	type = "data source",
	text = "Hardcore",
	icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap.blp",
	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end
		tooltip:AddLine("Penta status:")
		tooltip:AddLine("|c0000FF00Good|r ")
	end,
})

local function initMinimapButton()
	penta_rules.minimap_button = LibStub("LibDBIcon-1.0", true)
	penta_rules.minimap_button:Register("Penta", minimap_button, penta_rules.minimap_button_info)
end

local function checkHardcoreStatus()
	-- Unit tests
	------------------------
	-- Initialized and passes
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Penta"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[penta_rules.teammate_1] = {}
	-- other_hardcore_character_cache[penta_rules.teammate_1].party_mode = "Penta"
	-- other_hardcore_character_cache[penta_rules.teammate_1].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[penta_rules.teammate_1].team = { UnitName("player") }
	-- other_hardcore_character_cache[penta_rules.teammate_2] = {}
	-- other_hardcore_character_cache[penta_rules.teammate_2].party_mode = "Penta"
	-- other_hardcore_character_cache[penta_rules.teammate_2].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[penta_rules.teammate_2].team = { UnitName("player") ,   penta_rules.teammate_1 }
	------------------------
	-- Initialized and failes; different party member
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Penta"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[penta_rules.teammate_1] = {}
	-- other_hardcore_character_cache[penta_rules.teammate_1].party_mode = "Penta"
	-- other_hardcore_character_cache[penta_rules.teammate_1].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[penta_rules.teammate_1].team = { UnitName("player")}
	-- other_hardcore_character_cache[penta_rules.teammate_2] = {}
	-- other_hardcore_character_cache[penta_rules.teammate_2].party_mode = "Penta"
	-- other_hardcore_character_cache[penta_rules.teammate_2].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[penta_rules.teammate_2].team = {"somewrongplayer"}
	------------------------
	-- Initialized and failes; achievement mismatch
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Penta"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[penta_rules.teammate_2] = {}
	-- other_hardcore_character_cache[penta_rules.teammate_2].party_mode = "Penta"
	-- other_hardcore_character_cache[penta_rules.teammate_2].achievements = {"Power From Within"}
	-- other_hardcore_character_cache[penta_rules.teammate_2].team = {UnitName("player")}
	-- other_hardcore_character_cache[penta_rules.teammate_1] = {}
	-- other_hardcore_character_cache[penta_rules.teammate_1].party_mode = "Penta"
	-- other_hardcore_character_cache[penta_rules.teammate_1].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[penta_rules.teammate_1].team = {UnitName("player")}
	------------------------
	-- Uninitialized
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Penta"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[penta_rules.teammate_1] = nil

	if penta_rules._hardcore_settings_ref.party_change_token ~= nil then -- Ignore others dying from sacrifice
		return
	end

	local player_name = UnitName("player")
	if other_hardcore_character_cache[player_name] ~= nil then
		if other_hardcore_character_cache[penta_rules.teammate_1] ~= nil then
			if other_hardcore_character_cache[penta_rules.teammate_2] ~= nil then
				if other_hardcore_character_cache[penta_rules.teammate_3] ~= nil then
					if other_hardcore_character_cache[penta_rules.teammate_4] ~= nil then
						-- Check their penta status
						if other_hardcore_character_cache[penta_rules.teammate_1].party_mode ~= "Penta" then
							Hardcore:Print("Penta check: Partner is not in a penta.")
							penta_rules.warning_reason = "Warning - Partner is not in a penta."
							penta_rules:Warn()
							return false
						end

						if other_hardcore_character_cache[penta_rules.teammate_2].party_mode ~= "Penta" then
							Hardcore:Print("Penta check: Partner is not in a penta.")
							penta_rules.warning_reason = "Warning - Partner is not in a penta."
							penta_rules:Warn()
							return false
						end

						if other_hardcore_character_cache[penta_rules.teammate_3].party_mode ~= "Penta" then
							Hardcore:Print("Penta check: Partner is not in a penta.")
							penta_rules.warning_reason = "Warning - Partner is not in a penta."
							penta_rules:Warn()
							return false
						end

						if other_hardcore_character_cache[penta_rules.teammate_4].party_mode ~= "Penta" then
							Hardcore:Print("Penta check: Partner is not in a penta.")
							penta_rules.warning_reason = "Warning - Partner is not in a penta."
							penta_rules:Warn()
							return false
						end

						-- Check that other player thinks this player is part of their penta
						local found_self = false
						for i, other_players_partner in ipairs(other_hardcore_character_cache[penta_rules.teammate_1].team) do
							if other_players_partner == player_name then
								found_self = true
								break
							end
						end
						if found_self == false then
							Hardcore:Print("Penta check: Not found in partner's penta list")
							penta_rules.warning_reason = "Warning - Not found in partner's penta list."
							penta_rules:Warn()
							return false
						end

						found_self = false
						for i, other_players_partner in ipairs(other_hardcore_character_cache[penta_rules.teammate_2].team) do
							if other_players_partner == player_name then
								found_self = true
								break
							end
						end
						if found_self == false then
							Hardcore:Print("Penta check: Not found in partner's penta list")
							penta_rules.warning_reason = "Warning - Not found in partner's penta list."
							penta_rules:Warn()
							return false
						end

						found_self = false
						for i, other_players_partner in ipairs(other_hardcore_character_cache[penta_rules.teammate_3].team) do
							if other_players_partner == player_name then
								found_self = true
								break
							end
						end
						if found_self == false then
							Hardcore:Print("Penta check: Not found in partner's penta list")
							penta_rules.warning_reason = "Warning - Not found in partner's penta list."
							penta_rules:Warn()
							return false
						end

						found_self = false
						for i, other_players_partner in ipairs(other_hardcore_character_cache[penta_rules.teammate_4].team) do
							if other_players_partner == player_name then
								found_self = true
								break
							end
						end
						if found_self == false then
							Hardcore:Print("Penta check: Not found in partner's penta list")
							penta_rules.warning_reason = "Warning - Not found in partner's penta list."
							penta_rules:Warn()
							return false
						end
					end
				end
			end
		end
	end

	return true
end

-- Registers
function penta_rules:Register(fail_function_executor, _hardcore_character, _hardcore_settings)
	if penta_rules.minimap_button == nil then
		initMinimapButton()
	end

	penta_rules.accumulated_warn_time = 0
	penta_rules._hardcore_character_ref = _hardcore_character
	penta_rules._hardcore_settings_ref = _hardcore_settings
	if _hardcore_character.team ~= nil and _hardcore_character.team[1] then
		penta_rules.teammate_1 = _hardcore_character.team[1]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == penta_rules.teammate_1 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up penta registration; character team data nil. Did you enter teammate name?")
	end

	if _hardcore_character.team ~= nil and _hardcore_character.team[2] then
		penta_rules.teammate_2 = _hardcore_character.team[2]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == penta_rules.teammate_2 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up penta registration; character team data nil. Did you enter teammate name?")
	end

	if _hardcore_character.team ~= nil and _hardcore_character.team[3] then
		penta_rules.teammate_3 = _hardcore_character.team[3]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == penta_rules.teammate_3 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up penta registration; character team data nil. Did you enter teammate name?")
	end

	if _hardcore_character.team ~= nil and _hardcore_character.team[4] then
		penta_rules.teammate_4 = _hardcore_character.team[4]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == penta_rules.teammate_4 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up penta registration; character team data nil. Did you enter teammate name?")
	end

	penta_rules.timer_handle = C_Timer.NewTicker(check_rate, function()
		penta_rules:Check()
	end)
	penta_rules:RegisterEvent("PLAYER_DEAD")
	penta_rules.fail_function_executor = fail_function_executor
end

function penta_rules:Unregister()
	if penta_rules.minimap_button ~= nil then
		penta_rules.minimap_button:Hide("Penta")
	end
	if penta_rules.timer_handle ~= nil then
		penta_rules.timer_handle:Cancel()
	end
	penta_rules:UnregisterEvent("PLAYER_DEAD")
	penta_rules.accumulated_warn_time = 0
end

function penta_rules:Warn()
	if UnitLevel("player") == 1 then
		return
	end
	penta_rules.accumulated_warn_time = penta_rules.accumulated_warn_time + check_rate
	if max_warn_time - penta_rules.accumulated_warn_time > 0 then
		minimap_button.icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap_warning.blp"
		minimap_button.OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Penta status:")
			tooltip:AddLine("|c00FFFF00" .. penta_rules.warning_reason .. "|r ")
		end
		Hardcore:Print(
			"Warning - HC Penta: Get back to your penta partner. "
				.. max_warn_time - penta_rules.accumulated_warn_time
				.. " seconds remaining before failing the challenge."
		)
	else
		penta_rules._hardcore_character_ref.party_mode = "Failed Penta"
		Hardcore:Print("Failed Penta")
	end
end

function penta_rules:ResetWarn()
	if penta_rules.accumulated_warn_time > 1 then
		Hardcore:Print("Penta - All conditions met.")

		minimap_button.icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap.blp"
		minimap_button.OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Penta status:")
			tooltip:AddLine("|c0000FF00Good|r ")
		end
	end
	penta_rules.accumulated_warn_time = 0
end

function penta_rules:Check()
	-- this code causes the rules checker to ignore all duo/penta rules at max level
	if Hardcore_Character.game_version ~= nil then
		local max_level
		if Hardcore_Character.game_version == "Era" or Hardcore_Character.game_version == "SoM" then
			max_level = 60
		elseif Hardcore_Character.game_version == "WotLK" then
			max_level = 80
		else -- Cataclysm or otherwise
			max_level = 85
		end
		if UnitLevel("player") >= max_level then
			return
		end
	end

	local num_members = GetNumGroupMembers()
	if num_members < 5 then
		Hardcore:Print("Penta check: not in big enough group")
		penta_rules.warning_reason = "Warning - Not in big enough group."
		penta_rules:Warn()
		return
	end
	local identifiers = {
		"party1",
		"party2",
		"party3",
		"party4",
	}
	local found_member_1 = false
	local member_str_1 = ""

	local found_member_2 = false
	local member_str_2 = ""

	local found_member_3 = false
	local member_str_3 = ""

	local found_member_4 = false
	local member_str_4 = ""

	for i, id in ipairs(identifiers) do
		local member_name = UnitName(id)
		if member_name ~= nil then
			if member_name == penta_rules.teammate_1 then
				found_member_1 = true
				member_str_1 = id
			end
			if member_name == penta_rules.teammate_2 then
				found_member_2 = true
				member_str_2 = id
			end
			if member_name == penta_rules.teammate_3 then
				found_member_3 = true
				member_str_3 = id
			end
			if member_name == penta_rules.teammate_4 then
				found_member_4 = true
				member_str_4 = id
			end
		end
	end

	if found_member_1 == false or found_member_2 == false or found_member_3 == false or found_member_4 == false then
		Hardcore:Print("Penta check: did not find partner(s) in group")
		penta_rules.warning_reason = "Warning - did not find your partner(s) in party."
		penta_rules:Warn()
		return
	end

	local in_follow_range_1 = CheckInteractDistance(member_str_1, 4)
	local in_follow_range_2 = CheckInteractDistance(member_str_2, 4)
	local in_follow_range_3 = CheckInteractDistance(member_str_3, 4)
	local in_follow_range_4 = CheckInteractDistance(member_str_4, 4)
	if in_follow_range_1 == true and in_follow_range_2 == true and in_follow_range_3 == true and in_follow_range_4 == true then
		penta_rules:ResetWarn()
		return
	end

	if checkHardcoreStatus() == true then
		penta_rules:ResetWarn()
	end
end

-- Register Definitions
penta_rules:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_DEAD" then
		penta_rules._hardcore_character_ref.party_mode = "Failed Penta"
		Hardcore:Print("Failed Penta")
	end
end)
