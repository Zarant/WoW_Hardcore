local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.AbsentMindedProspector = _achievement

-- General info
_achievement.name = "AbsentMindedProspector"
_achievement.title = "Protect the Prospector"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_absent_minded_prospector.blp"
_achievement.level_cap = 19
_achievement.quest_num = 731
_achievement.quest_name = "Absent Minded Prospector"
_achievement.zone = "Darkshore"
_achievement.bl_text = "Darkshore Quest"
_achievement.faction = "Alliance"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementBasicQuestDescription(
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
