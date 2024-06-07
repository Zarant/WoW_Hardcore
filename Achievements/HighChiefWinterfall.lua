local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.HighChiefWinterfall = _achievement

-- General info
_achievement.name = "HighChiefWinterfall"
_achievement.title = "Taking Down the Chief"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_high_chief_winterfall.blp"
_achievement.level_cap = 59
_achievement.quest_num = 5121
_achievement.zone = "Winterfall"
_achievement.quest_name = "High Chief Winterfall"
_achievement.kill_target = "High Chief Winterfall"
_achievement.bl_text = "Winterfall Quest"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementKillDescription(
	_achievement.kill_target,
	_achievement.quest_name,
	_achievement.zone,
	_achievement.level_cap
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
