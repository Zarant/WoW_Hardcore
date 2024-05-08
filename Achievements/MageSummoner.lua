local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.MageSummoner = _achievement

-- General info
_achievement.name = "MageSummoner"
_achievement.title = "Light of Elune"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_mage_summoner.blp"
_achievement.level_cap = 23
_achievement.quest_num = 1017
_achievement.quest_name = "Mage Summoner"
_achievement.zone = "Ashenvale"
_achievement.kill_target = "Sarilus Foulborne"
_achievement.faction = "Alliance"
_achievement.bl_text = "Ashenvale Quest"
_achievement.pts = 10
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
