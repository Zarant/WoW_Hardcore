local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.KimjaelIndeed = _achievement

-- General info
_achievement.name = "KimjaelIndeed"
_achievement.title = "Kim'Jael's Equipment Found"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_kimjael_indeed.blp"
_achievement.level_cap = 51
_achievement.quest_num = 3601
_achievement.quest_name = "Kim'Jael Indeed!"
_achievement.zone = "Azshara"
_achievement.bl_text = "Azshara Quest"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementBasicQuestDescription(
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
