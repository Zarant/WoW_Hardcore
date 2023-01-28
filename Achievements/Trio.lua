local _G = _G
local trio_rules = CreateFrame("Frame")
_G.extra_rules.Trio = trio_rules

local max_warn_time = 10 * 60 -- Fails after 10 minutes
local check_rate = 15 -- Checks every 15 seconds
-- General info
trio_rules.name = "Trio"
trio_rules.title = "Trio"
trio_rules.class = "All"
trio_rules.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_default.blp"
trio_rules.description = ""
trio_rules.minimap_button_info = {}
trio_rules.minimap_button = nil
trio_rules.warn_reason = ""

local minimap_button = LibStub("LibDataBroker-1.1"):NewDataObject("Trio", {
	type = "data source",
	text = "Hardcore",
	icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap.blp",
	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end
		tooltip:AddLine("Trio status:")
		tooltip:AddLine("|c0000FF00Good|r ")
	end,
})

local function initMinimapButton()
	trio_rules.minimap_button = LibStub("LibDBIcon-1.0", true)
	trio_rules.minimap_button:Register("Trio", minimap_button, trio_rules.minimap_button_info)
end

local function checkHardcoreStatus()
	-- Unit tests
	------------------------
	-- Initialized and passes
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Trio"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[trio_rules.teammate_1] = {}
	-- other_hardcore_character_cache[trio_rules.teammate_1].party_mode = "Trio"
	-- other_hardcore_character_cache[trio_rules.teammate_1].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[trio_rules.teammate_1].team = { UnitName("player") }
	-- other_hardcore_character_cache[trio_rules.teammate_2] = {}
	-- other_hardcore_character_cache[trio_rules.teammate_2].party_mode = "Trio"
	-- other_hardcore_character_cache[trio_rules.teammate_2].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[trio_rules.teammate_2].team = { UnitName("player") ,   trio_rules.teammate_1 }
	------------------------
	-- Initialized and failes; different party member
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Trio"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[trio_rules.teammate_1] = {}
	-- other_hardcore_character_cache[trio_rules.teammate_1].party_mode = "Trio"
	-- other_hardcore_character_cache[trio_rules.teammate_1].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[trio_rules.teammate_1].team = { UnitName("player")}
	-- other_hardcore_character_cache[trio_rules.teammate_2] = {}
	-- other_hardcore_character_cache[trio_rules.teammate_2].party_mode = "Trio"
	-- other_hardcore_character_cache[trio_rules.teammate_2].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[trio_rules.teammate_2].team = {"somewrongplayer"}
	------------------------
	-- Initialized and failes; achievement mismatch
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Trio"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[trio_rules.teammate_2] = {}
	-- other_hardcore_character_cache[trio_rules.teammate_2].party_mode = "Trio"
	-- other_hardcore_character_cache[trio_rules.teammate_2].achievements = {"Power From Within"}
	-- other_hardcore_character_cache[trio_rules.teammate_2].team = {UnitName("player")}
	-- other_hardcore_character_cache[trio_rules.teammate_1] = {}
	-- other_hardcore_character_cache[trio_rules.teammate_1].party_mode = "Trio"
	-- other_hardcore_character_cache[trio_rules.teammate_1].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[trio_rules.teammate_1].team = {UnitName("player")}
	------------------------
	-- Uninitialized
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Trio"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[trio_rules.teammate_1] = nil

	if trio_rules._hardcore_settings_ref.party_change_token ~= nil then -- Ignore others dying from sacrifice
		return
	end

	local player_name = UnitName("player")
	if other_hardcore_character_cache[player_name] ~= nil then
		if other_hardcore_character_cache[trio_rules.teammate_1] ~= nil then
			if other_hardcore_character_cache[trio_rules.teammate_2] ~= nil then
				-- Check their trio status
				if other_hardcore_character_cache[trio_rules.teammate_1].party_mode ~= "Trio" then
					Hardcore:Print("Trio check: Partner is not in a trio.")
					trio_rules.warning_reason = "Warning - Partner is not in a trio."
					trio_rules:Warn()
					return false
				end

				if other_hardcore_character_cache[trio_rules.teammate_2].party_mode ~= "Trio" then
					Hardcore:Print("Trio check: Partner is not in a trio.")
					trio_rules.warning_reason = "Warning - Partner is not in a trio."
					trio_rules:Warn()
					return false
				end

				-- Check that other player thinks this player is part of their trio
				local found_self = false
				for i, other_players_partner in ipairs(other_hardcore_character_cache[trio_rules.teammate_1].team) do
					if other_players_partner == player_name then
						found_self = true
						break
					end
				end
				if found_self == false then
					Hardcore:Print("Trio check: Not found in partner's trio list")
					trio_rules.warning_reason = "Warning - Not found in partner's trio list."
					trio_rules:Warn()
					return false
				end

				found_self = false
				for i, other_players_partner in ipairs(other_hardcore_character_cache[trio_rules.teammate_2].team) do
					if other_players_partner == player_name then
						found_self = true
						break
					end
				end
				if found_self == false then
					Hardcore:Print("Trio check: Not found in partner's trio list")
					trio_rules.warning_reason = "Warning - Not found in partner's trio list."
					trio_rules:Warn()
					return false
				end
			end
		end
	end

	return true
end

-- Registers
function trio_rules:Register(fail_function_executor, _hardcore_character, _hardcore_settings)
	if trio_rules.minimap_button == nil then
		initMinimapButton()
	end

	trio_rules.accumulated_warn_time = 0
	trio_rules._hardcore_character_ref = _hardcore_character
	trio_rules._hardcore_settings_ref = _hardcore_settings
	if _hardcore_character.team ~= nil and _hardcore_character.team[1] then
		trio_rules.teammate_1 = _hardcore_character.team[1]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == trio_rules.teammate_1 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up trio registration; character team data nil. Did you enter teammate name?")
	end

	if _hardcore_character.team ~= nil and _hardcore_character.team[2] then
		trio_rules.teammate_2 = _hardcore_character.team[2]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == trio_rules.teammate_2 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up trio registration; character team data nil. Did you enter teammate name?")
	end

	trio_rules.timer_handle = C_Timer.NewTicker(check_rate, function()
		trio_rules:Check()
	end)
	trio_rules:RegisterEvent("PLAYER_DEAD")
	trio_rules.fail_function_executor = fail_function_executor
end

function trio_rules:Unregister()
	if trio_rules.minimap_button ~= nil then
		trio_rules.minimap_button:Hide("Trio")
	end
	if trio_rules.timer_handle ~= nil then
		trio_rules.timer_handle:Cancel()
	end
	trio_rules:UnregisterEvent("PLAYER_DEAD")
	trio_rules.accumulated_warn_time = 0
end

function trio_rules:Warn()
	if UnitLevel("player") == 1 then return end
	trio_rules.accumulated_warn_time = trio_rules.accumulated_warn_time + check_rate
	if max_warn_time - trio_rules.accumulated_warn_time > 0 then
		minimap_button.icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap_warning.blp"
		minimap_button.OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Trio status:")
			tooltip:AddLine("|c00FFFF00" .. trio_rules.warning_reason .. "|r ")
		end
		Hardcore:Print(
			"Warning - HC Trio: Get back to your trio partner. "
				.. max_warn_time - trio_rules.accumulated_warn_time
				.. " seconds remaining before failing the challenge."
		)
	else
		trio_rules._hardcore_character_ref.party_mode = "Failed Trio"
		Hardcore:Print("Failed Trio")
	end
end

function trio_rules:ResetWarn()
	if trio_rules.accumulated_warn_time > 1 then
		Hardcore:Print("Trio - All conditions met.")

		minimap_button.icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap.blp"
		minimap_button.OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Trio status:")
			tooltip:AddLine("|c0000FF00Good|r ")
		end
	end
	trio_rules.accumulated_warn_time = 0
end

function trio_rules:Check()
	-- this code causes the rules checker to ignore all duo/trio rules at max level
	if Hardcore_Character.game_version ~= nil then
		local max_level
		if Hardcore_Character.game_version == "Era" or Hardcore_Character.game_version == "SoM" then
			max_level = 60
		else -- if Hardcore_Character.game_version == "WotLK" or anything else
			max_level = 80
		end
		if UnitLevel( "player" ) >= max_level then
			return
		end
	end

	local num_members = GetNumGroupMembers()
	if num_members < 3 then
		Hardcore:Print("Trio check: not in big enough group")
		trio_rules.warning_reason = "Warning - Not in big enough group."
		trio_rules:Warn()
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

	for i, id in ipairs(identifiers) do
		local member_name = UnitName(id)
		if member_name ~= nil then
			if member_name == trio_rules.teammate_1 then
				found_member_1 = true
				member_str_1 = id
			end
			if member_name == trio_rules.teammate_2 then
				found_member_2 = true
				member_str_2 = id
			end
		end
	end

	if found_member_1 == false or found_member_2 == false then
		Hardcore:Print("Trio check: did not find partner(s) in group")
		trio_rules.warning_reason = "Warning - did not find your partner(s) in party."
		trio_rules:Warn()
		return
	end

	local in_follow_range_1 = CheckInteractDistance(member_str_1, 4)
    	local in_follow_range_2 = CheckInteractDistance(member_str_2, 4)
    	if in_follow_range_1 == true and in_follow_range_2 == true then
        	trio_rules:ResetWarn()
        	return
    	end

	-- updated Trio - All conditions met.

	local my_subzone = C_Map.GetBestMapForUnit("player") -- subzone
	local teammate_subzone_1 = C_Map.GetBestMapForUnit(member_str_1) -- subzone
	local teammate_subzone_2 = C_Map.GetBestMapForUnit(member_str_2) -- subzone
    
    local my_zone = C_Map.GetMapInfo(my_subzone).parentMapID -- parent zone
    local teammate_zone_1 = C_Map.GetMapInfo(teammate_subzone_1).parentMapID -- parent zone
    local teammate_zone_2 = C_Map.GetMapInfo(teammate_subzone_2).parentMapID -- parent zone

	local MOONGLADE_SUBZONE = 1450
	local SCARLET_ENCLAVE_SUBZONE = 124

    if (my_subzone == MOONGLADE_SUBZONE or teammate_subzone_1 == MOONGLADE_SUBZONE or teammate_subzone_2 == MOONGLADE_SUBZONE) 
	or (my_subzone == SCARLET_ENCLAVE_SUBZONE or teammate_subzone_1 == SCARLET_ENCLAVE_SUBZONE or teammate_subzone_2 == SCARLET_ENCLAVE_SUBZONE) then
		-- Moonglade/Scarlet enclave subzones are exempt
        duo_rules:ResetWarn()
    elseif (my_zone ~= teammate_zone_1) or (my_zone ~= teammate_zone_2) or (teammate_zone_1 ~= teammate_zone_2) then
		-- important that this check is on zone not subzone
        Hardcore:Print("Trio check: Partner(s) in another zone!")
        trio_rules.warning_reason = "Warning - Partner(s() another zone."
        trio_rules:Warn()
        return
    end
    if checkHardcoreStatus == true then
        duo_rules:ResetWarn()
    end

	if checkHardcoreStatus() == true then
		trio_rules:ResetWarn()
	end
end

-- Register Definitions
trio_rules:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_DEAD" then
		trio_rules._hardcore_character_ref.party_mode = "Failed Trio"
		Hardcore:Print("Failed Trio")
	end
end)
