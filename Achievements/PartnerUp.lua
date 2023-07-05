local _G = _G
local partner_up_achievement = CreateFrame("Frame")
_G.achievements.PartnerUp = partner_up_achievement

-- General info
partner_up_achievement.name = "PartnerUp"
partner_up_achievement.title = "Partner Up!"
partner_up_achievement.class = "All"
partner_up_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_default.blp"
partner_up_achievement.pts = 10
partner_up_achievement.description =
	"Complete the Hardcore challenge in a group of two. Read the rules, if you want to know more about Hardcore Duos. For all Achievements within the General category, your duo is considered one character (i.e. the achievement’s rules apply to both of you as if you were one character). |c00FFA500 Note: You must be in a Duo or Trio group to complete this achievement.|r"
partner_up_achievement.updated = false

-- Registers
function partner_up_achievement:Register(fail_function_executor)
	partner_up_achievement:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	partner_up_achievement.updated = false
	partner_up_achievement.fail_function_executor = fail_function_executor
end

function partner_up_achievement:Unregister()
	partner_up_achievement:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
end

local function checkAchievements(name_1, name_2)
	for _, achievement_check in ipairs(other_hardcore_character_cache[name_1].achievements) do
		if _G.achievements[achievement_check].class and _G.achievements[achievement_check].class ~= "All" then
			return
		end
		local has_achievement = false
		for i, other_achievement in ipairs(other_hardcore_character_cache[name_2].achievements) do
			if other_achievement == achievement_check then
				has_achievement = true
				break
			end
		end
		if has_achievement == false then
			Hardcore:Print("Failed partner up; partner is missing achievement " .. achievement_check)
			partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
			return false
		end
	end
	return true
end

-- Register Definitions
partner_up_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UPDATE_MOUSEOVER_UNIT" then
		-- UNIT TESTS
		-- Initialized and passes
		-- other_hardcore_character_cache[UnitName("player")] = {}
		-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
		-- other_hardcore_character_cache[UnitName("player")].party_mode = "Duo"
		-- other_hardcore_character_cache[UnitName("player")].team = {"s"}
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]] = {}
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]].party_mode = "Duo"
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]].achievements = {"Nudist", "Power From Within"}
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]].team = {UnitName("player")}
		------------------------
		-- Initialized and fails; different party member
		-- other_hardcore_character_cache[UnitName("player")] = {}
		-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
		-- other_hardcore_character_cache[UnitName("player")].party_mode = "Duo"
		-- other_hardcore_character_cache[UnitName("player")].team = {"s"}
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]] = {}
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]].party_mode = "Duo"
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]].achievements = {"Power From Within"}
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]].team = {UnitName("player")}
		------------------------
		-- Initialized and fails; different party member
		-- other_hardcore_character_cache[UnitName("player")] = {}
		-- other_hardcore_character_cache[UnitName("player")].achievements = {"Nudist", "Power From Within"}
		-- other_hardcore_character_cache[UnitName("player")].party_mode = "Duo"
		-- other_hardcore_character_cache[UnitName("player")].team = {"s"}
		-- other_hardcore_character_cache[other_hardcore_character_cache[UnitName("player")].team[1]] = nil

		if partner_up_achievement.updated then
			return
		end
		C_Timer.After(1, function()
			if other_hardcore_character_cache[UnitName("player")] ~= nil then
				if
					other_hardcore_character_cache[UnitName("player")].party_mode ~= "Duo"
					and other_hardcore_character_cache[UnitName("player")].party_mode ~= "Trio"
				then
					Hardcore:Print("Failed partner up; invalid party mode.")
					partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
				end
				if
					other_hardcore_character_cache[UnitName("player")].party_mode == "Duo"
					and other_hardcore_character_cache[UnitName("player")].team[1] == nil
				then
					Hardcore:Print("Failed partner up; missing partner.")
					partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
				end
				if
					other_hardcore_character_cache[UnitName("player")].party_mode == "Trio"
					and (
						other_hardcore_character_cache[UnitName("player")].team[1] == nil
						or other_hardcore_character_cache[UnitName("player")].team[2] == nil
					)
				then
					Hardcore:Print("Failed partner up; missing partner(s).")
					partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
				end
			else
				return
			end

			local partner_name_1 = other_hardcore_character_cache[UnitName("player")].team[1]
			if other_hardcore_character_cache[partner_name_1] ~= nil then
				if
					other_hardcore_character_cache[partner_name_1].party_mode ~= "Duo"
					and other_hardcore_character_cache[partner_name_1].party_mode ~= "Trio"
				then
					Hardcore:Print("Failed partner up; invalid party mode.")
					partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
				end
				if
					other_hardcore_character_cache[partner_name_1].party_mode == "Duo"
					and other_hardcore_character_cache[partner_name_1].team[1] == nil
				then
					Hardcore:Print("Failed partner up; missing partner.")
					partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
				end
				if
					other_hardcore_character_cache[partner_name_1].party_mode == "Trio"
					and (
						other_hardcore_character_cache[partner_name_1].team[1] == nil
						or other_hardcore_character_cache[partner_name_1].team[2] == nil
					)
				then
					Hardcore:Print("Failed partner up; missing partner(s).")
					partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
				end

				if checkAchievements(UnitName("player"), partner_name_1) == false then
					return
				end
			else
				return
			end

			if other_hardcore_character_cache[UnitName("player")].party_mode == "Trio" then
				local partner_name_2 = other_hardcore_character_cache[UnitName("player")].team[2]
				if other_hardcore_character_cache[partner_name_2] ~= nil then
					if
						other_hardcore_character_cache[partner_name_2].party_mode ~= "Duo"
						and other_hardcore_character_cache[partner_name_2].party_mode ~= "Trio"
					then
						Hardcore:Print("Failed partner up; invalid party mode.")
						partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
					end
					if
						other_hardcore_character_cache[partner_name_2].party_mode == "Duo"
						and other_hardcore_character_cache[partner_name_2].team[1] == nil
					then
						Hardcore:Print("Failed partner up; missing partner.")
						partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
					end
					if
						other_hardcore_character_cache[partner_name_2].party_mode == "Trio"
						and (
							other_hardcore_character_cache[partner_name_2].team[1] == nil
							or other_hardcore_character_cache[partner_name_2].team[2] == nil
						)
					then
						Hardcore:Print("Failed partner up; missing partner(s).")
						partner_up_achievement.fail_function_executor.Fail(partner_up_achievement.name)
					end

					if checkAchievements(UnitName("player"), partner_name_2) == false then
						return
					end
				else
					return
				end
			end
			partner_up_achievement.updated = true
		end)
	end
end)
