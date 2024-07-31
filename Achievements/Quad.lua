local _G = _G
local quad_rules = CreateFrame("Frame")
_G.extra_rules.Quad = quad_rules

local max_warn_time = 10 * 60 -- Fails after 10 minutes
local check_rate = 15 -- Checks every 15 seconds
-- General info
quad_rules.name = "Quad"
quad_rules.title = "Quad"
quad_rules.class = "All"
quad_rules.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_default.blp"
quad_rules.description = ""
quad_rules.minimap_button_info = {}
quad_rules.minimap_button = nil
quad_rules.warn_reason = ""

local minimap_button = LibStub("LibDataBroker-1.1"):NewDataObject("Quad", {
	type = "data source",
	text = "Hardcore",
	icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap.blp",
	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end
		tooltip:AddLine("Quad status:")
		tooltip:AddLine("|c0000FF00Good|r ")
	end,
})

local function initMinimapButton()
	quad_rules.minimap_button = LibStub("LibDBIcon-1.0", true)
	quad_rules.minimap_button:Register("Quad", minimap_button, quad_rules.minimap_button_info)
end

local function checkHardcoreStatus()
	-- Unit tests
	------------------------
	-- Initialized and passes
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Quad"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[quad_rules.teammate_1] = {}
	-- other_hardcore_character_cache[quad_rules.teammate_1].party_mode = "Quad"
	-- other_hardcore_character_cache[quad_rules.teammate_1].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[quad_rules.teammate_1].team = { UnitName("player") }
	-- other_hardcore_character_cache[quad_rules.teammate_2] = {}
	-- other_hardcore_character_cache[quad_rules.teammate_2].party_mode = "Quad"
	-- other_hardcore_character_cache[quad_rules.teammate_2].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[quad_rules.teammate_2].team = { UnitName("player") ,   quad_rules.teammate_1 }
	------------------------
	-- Initialized and failes; different party member
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Quad"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[quad_rules.teammate_1] = {}
	-- other_hardcore_character_cache[quad_rules.teammate_1].party_mode = "Quad"
	-- other_hardcore_character_cache[quad_rules.teammate_1].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[quad_rules.teammate_1].team = { UnitName("player")}
	-- other_hardcore_character_cache[quad_rules.teammate_2] = {}
	-- other_hardcore_character_cache[quad_rules.teammate_2].party_mode = "Quad"
	-- other_hardcore_character_cache[quad_rules.teammate_2].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[quad_rules.teammate_2].team = {"somewrongplayer"}
	------------------------
	-- Initialized and failes; achievement mismatch
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Quad"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[quad_rules.teammate_2] = {}
	-- other_hardcore_character_cache[quad_rules.teammate_2].party_mode = "Quad"
	-- other_hardcore_character_cache[quad_rules.teammate_2].achievements = {"Power From Within"}
	-- other_hardcore_character_cache[quad_rules.teammate_2].team = {UnitName("player")}
	-- other_hardcore_character_cache[quad_rules.teammate_1] = {}
	-- other_hardcore_character_cache[quad_rules.teammate_1].party_mode = "Quad"
	-- other_hardcore_character_cache[quad_rules.teammate_1].achievements = {"Nudist", "Power From Within"}
	-- other_hardcore_character_cache[quad_rules.teammate_1].team = {UnitName("player")}
	------------------------
	-- Uninitialized
	-- other_hardcore_character_cache[UnitName("player")] = {}
	-- other_hardcore_character_cache[UnitName("player")].achievements = { "Nudist", "Power From Within" }
	-- other_hardcore_character_cache[UnitName("player")].party_mode = "Quad"
	-- other_hardcore_character_cache[UnitName("player")].team = {}
	-- other_hardcore_character_cache[quad_rules.teammate_1] = nil

	if quad_rules._hardcore_settings_ref.party_change_token ~= nil then -- Ignore others dying from sacrifice
		return
	end

	local player_name = UnitName("player")
	if other_hardcore_character_cache[player_name] ~= nil then
		if other_hardcore_character_cache[quad_rules.teammate_1] ~= nil then
			if other_hardcore_character_cache[quad_rules.teammate_2] ~= nil then
				if other_hardcore_character_cache[quad_rules.teammate_3] ~= nil then
					-- Check their quad status
					if other_hardcore_character_cache[quad_rules.teammate_1].party_mode ~= "Quad" then
						Hardcore:Print("Quad check: Partner is not in a quad.")
						quad_rules.warning_reason = "Warning - Partner is not in a quad."
						quad_rules:Warn()
						return false
					end

					if other_hardcore_character_cache[quad_rules.teammate_2].party_mode ~= "Quad" then
						Hardcore:Print("Quad check: Partner is not in a quad.")
						quad_rules.warning_reason = "Warning - Partner is not in a quad."
						quad_rules:Warn()
						return false
					end

					if other_hardcore_character_cache[quad_rules.teammate_3].party_mode ~= "Quad" then
						Hardcore:Print("Quad check: Partner is not in a quad.")
						quad_rules.warning_reason = "Warning - Partner is not in a quad."
						quad_rules:Warn()
						return false
					end

					-- Check that other player thinks this player is part of their quad
					local found_self = false
					for i, other_players_partner in ipairs(other_hardcore_character_cache[quad_rules.teammate_1].team) do
						if other_players_partner == player_name then
							found_self = true
							break
						end
					end
					if found_self == false then
						Hardcore:Print("Quad check: Not found in partner's quad list")
						quad_rules.warning_reason = "Warning - Not found in partner's quad list."
						quad_rules:Warn()
						return false
					end

					found_self = false
					for i, other_players_partner in ipairs(other_hardcore_character_cache[quad_rules.teammate_2].team) do
						if other_players_partner == player_name then
							found_self = true
							break
						end
					end
					if found_self == false then
						Hardcore:Print("Quad check: Not found in partner's quad list")
						quad_rules.warning_reason = "Warning - Not found in partner's quad list."
						quad_rules:Warn()
						return false
					end

					found_self = false
					for i, other_players_partner in ipairs(other_hardcore_character_cache[quad_rules.teammate_3].team) do
						if other_players_partner == player_name then
							found_self = true
							break
						end
					end
					if found_self == false then
						Hardcore:Print("Quad check: Not found in partner's quad list")
						quad_rules.warning_reason = "Warning - Not found in partner's quad list."
						quad_rules:Warn()
						return false
					end
				end
			end
		end
	end

	return true
end

-- Registers
function quad_rules:Register(fail_function_executor, _hardcore_character, _hardcore_settings)
	if quad_rules.minimap_button == nil then
		initMinimapButton()
	end

	quad_rules.accumulated_warn_time = 0
	quad_rules._hardcore_character_ref = _hardcore_character
	quad_rules._hardcore_settings_ref = _hardcore_settings
	if _hardcore_character.team ~= nil and _hardcore_character.team[1] then
		quad_rules.teammate_1 = _hardcore_character.team[1]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == quad_rules.teammate_1 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up quad registration; character team data nil. Did you enter teammate name?")
	end

	if _hardcore_character.team ~= nil and _hardcore_character.team[2] then
		quad_rules.teammate_2 = _hardcore_character.team[2]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == quad_rules.teammate_2 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up quad registration; character team data nil. Did you enter teammate name?")
	end

	if _hardcore_character.team ~= nil and _hardcore_character.team[3] then
		quad_rules.teammate_3 = _hardcore_character.team[3]
		for i, trading_player_name in ipairs(_hardcore_character.trade_partners) do
			if trading_player_name == quad_rules.teammate_3 then
				table.remove(_hardcore_character.trade_partners, i)
			end
		end
	else
		Hardcore:Print("Error setting up quad registration; character team data nil. Did you enter teammate name?")
	end

	quad_rules.timer_handle = C_Timer.NewTicker(check_rate, function()
		quad_rules:Check()
	end)
	quad_rules:RegisterEvent("PLAYER_DEAD")
	quad_rules.fail_function_executor = fail_function_executor
end

function quad_rules:Unregister()
	if quad_rules.minimap_button ~= nil then
		quad_rules.minimap_button:Hide("Quad")
	end
	if quad_rules.timer_handle ~= nil then
		quad_rules.timer_handle:Cancel()
	end
	quad_rules:UnregisterEvent("PLAYER_DEAD")
	quad_rules.accumulated_warn_time = 0
end

function quad_rules:Warn()
	if UnitLevel("player") == 1 then
		return
	end
	quad_rules.accumulated_warn_time = quad_rules.accumulated_warn_time + check_rate
	if max_warn_time - quad_rules.accumulated_warn_time > 0 then
		minimap_button.icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap_warning.blp"
		minimap_button.OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Quad status:")
			tooltip:AddLine("|c00FFFF00" .. quad_rules.warning_reason .. "|r ")
		end
		Hardcore:Print(
			"Warning - HC Quad: Get back to your quad partner. "
				.. max_warn_time - quad_rules.accumulated_warn_time
				.. " seconds remaining before failing the challenge."
		)
	else
		quad_rules._hardcore_character_ref.party_mode = "Failed Quad"
		Hardcore:Print("Failed Quad")
	end
end

function quad_rules:ResetWarn()
	if quad_rules.accumulated_warn_time > 1 then
		Hardcore:Print("Quad - All conditions met.")

		minimap_button.icon = "Interface\\Addons\\Hardcore\\Media\\duo_minimap.blp"
		minimap_button.OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:AddLine("Quad status:")
			tooltip:AddLine("|c0000FF00Good|r ")
		end
	end
	quad_rules.accumulated_warn_time = 0
end

function quad_rules:Check()
	-- this code causes the rules checker to ignore all duo/quad rules at max level
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
	if num_members < 4 then
		Hardcore:Print("Quad check: not in big enough group")
		quad_rules.warning_reason = "Warning - Not in big enough group."
		quad_rules:Warn()
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

	for i, id in ipairs(identifiers) do
		local member_name = UnitName(id)
		if member_name ~= nil then
			if member_name == quad_rules.teammate_1 then
				found_member_1 = true
				member_str_1 = id
			end
			if member_name == quad_rules.teammate_2 then
				found_member_2 = true
				member_str_2 = id
			end
			if member_name == quad_rules.teammate_3 then
				found_member_3 = true
				member_str_3 = id
			end
		end
	end

	if found_member_1 == false or found_member_2 == false or found_member_3 == false then
		Hardcore:Print("Quad check: did not find partner(s) in group")
		quad_rules.warning_reason = "Warning - did not find your partner(s) in party."
		quad_rules:Warn()
		return
	end

	local in_follow_range_1 = CheckInteractDistance(member_str_1, 4)
	local in_follow_range_2 = CheckInteractDistance(member_str_2, 4)
	local in_follow_range_3 = CheckInteractDistance(member_str_3, 4)
	if in_follow_range_1 == true and in_follow_range_2 == true and in_follow_range_3 == true then
		quad_rules:ResetWarn()
		return
	end

	if checkHardcoreStatus() == true then
		quad_rules:ResetWarn()
	end
end

-- Register Definitions
quad_rules:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_DEAD" then
		quad_rules._hardcore_character_ref.party_mode = "Failed Quad"
		Hardcore:Print("Failed Quad")
	end
end)
