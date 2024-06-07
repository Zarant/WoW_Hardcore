local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.HintsOfANewPlague = _achievement

-- General info
_achievement.name = "HintsOfANewPlague"
_achievement.title = "Hints of a New Plague"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_hints_of_a_new_plague.blp"
_achievement.level_cap = 34
_achievement.quest_num = 658
_achievement.quest_name = "Hints of a New Plague"
_achievement.zone = "Hillsbrad Foothills"
_achievement.kill_target = "Forsaken Courier"
_achievement.bl_text = "Hillsbrad Foothills Quest"
_achievement.pts = 10
_achievement.faction = "Alliance"
_achievement.description = HCGeneratePassiveAchievementKillDescription(
	_achievement.kill_target,
	_achievement.quest_name,
	_achievement.zone,
	_achievement.level_cap,
	"Alliance"
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
