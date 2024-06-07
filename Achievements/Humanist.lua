local _G = _G
local humanist_achievement = CreateFrame("Frame")
_G.achievements.Humanist = humanist_achievement

humanist_achievement.cache = {}
-- General info
humanist_achievement.name = "Humanist"
humanist_achievement.title = "Humanist"
humanist_achievement.class = "All"
humanist_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_humanist.blp"
humanist_achievement.bl_text = "Starting Achievement"
humanist_achievement.pts = 15
humanist_achievement.description =
	"Complete the Hardcore challenge without at any point killing an NPC of the type Humanoid. Killing is considered any action that gives your character kill credit (experience, eligibility to loot, or quest progress)."

-- Registers
function humanist_achievement:Register(fail_function_executor)
	humanist_achievement:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
	humanist_achievement:RegisterEvent("PLAYER_TARGET_CHANGED")
	humanist_achievement:RegisterEvent("PLAYER_LEAVE_COMBAT")
	humanist_achievement:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	humanist_achievement.fail_function_executor = fail_function_executor
end

function humanist_achievement:Unregister()
	humanist_achievement:UnregisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
	humanist_achievement:UnregisterEvent("PLAYER_TARGET_CHANGED")
	humanist_achievement:UnregisterEvent("PLAYER_LEAVE_COMBAT")
end

-- Register Definitions
humanist_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local creature_name = string.match(arg[1], "(.+) dies")
		if humanist_achievement.cache[creature_name] ~= nil then
			humanist_achievement.fail_function_executor.Fail(humanist_achievement.name)
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		if UnitCanAttack("player", "target") then
			if UnitCreatureType("target") == "Humanoid" then
				humanist_achievement.cache[UnitName("target")] = 1
			end
		end
	elseif event == "PLAYER_LEAVE_COMBAT" then
		humanist_achievement.cache = {}
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		local creature_name = UnitName("mouseover")
		local creature_type = UnitCreatureType("mouseover")
		if creature_name ~= nil and creature_type ~= nil then
			if creature_type == "Humanoid" then
				if UnitCanAttack("player", "mouseover") then
					humanist_achievement.cache[UnitName("mouseover")] = 1
				end
			end
		end
	end
end)
