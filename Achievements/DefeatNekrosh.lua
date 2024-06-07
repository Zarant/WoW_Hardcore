local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.DefeatNekrosh = _achievement

-- General info
_achievement.name = "DefeatNekrosh"
_achievement.title = "Defeat Nek'rosh"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_nekrosh.blp"
_achievement.level_cap = 31
_achievement.quest_num = 474
_achievement.quest_name = "Defeath Nek'rosh"
_achievement.zone = "Wetlands"
_achievement.kill_target = "Chieftain Nek'rosh"
_achievement.faction = "Alliance"
_achievement.bl_text = "Wetlands Quest"
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
