local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.BattleOfHillsbrad = _achievement

-- General info
_achievement.name = "BattleOfHillsbrad"
_achievement.title = "Battle of Hillsbrad"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_battle_of_hillsbrad.blp"
_achievement.level_cap = 33
_achievement.quest_num = 550
_achievement.quest_name = "Battle of Hillsbrad"
_achievement.zone = "Hillsbrad Foothills"
_achievement.kill_target = "Captain Ironhill"
_achievement.faction = "Horde"
_achievement.bl_text = "Hillsbrad Foothills Quest"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementKillDescription(
	_achievement.kill_target,
	_achievement.quest_name,
	_achievement.zone,
	_achievement.level_cap,
	"Horde"
)
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
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
	HCCommonPassiveAchievementBasicQuestCheck(_achievement, event, arg)
end)
