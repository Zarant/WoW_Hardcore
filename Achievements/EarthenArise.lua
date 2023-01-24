local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.EarthenArise = _achievement

-- General info
_achievement.name = "EarthenArise"
_achievement.title = "Death to Goggeroc"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_earthen_arise.blp"
_achievement.level_cap = 20
_achievement.quest_num = 6481
_achievement.quest_name = "Earthen Arise"
_achievement.zone = "Stonetalon Mountains"
_achievement.kill_target = "Goggeroc"
_achievement.faction = "Horde"
_achievement.pts = 10 
_achievement.bl_text = "Stonetalon Mountains Quest"
_achievement.description = HCGeneratePassiveAchievementKillDescription(_achievement.kill_target, _achievement.quest_name, _achievement.zone, _achievement.level_cap, "Horde")
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
}

-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement:RegisterEvent("QUEST_TURNED_IN")
	_achievement.succeed_function_executor = succeed_function_executor 
end

function _achievement:Unregister()
	_achievement:UnregisterEvent("QUEST_TURNED_IN")
end

-- Register Definitions
_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	HCCommonPassiveAchievementKillCheck(_achievement, event, arg)
end)
