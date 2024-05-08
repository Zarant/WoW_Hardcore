local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.Morladim = _achievement

-- General info
_achievement.name = "Morladim"
_achievement.title = "Mor'Ladim Defeated"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_morladim.blp"
_achievement.level_cap = 33
_achievement.quest_num = 228
_achievement.quest_name = "Mor'Ladim"
_achievement.bl_text = "Duskwood Quest"
_achievement.pts = 10
_achievement.zone = "Duskwood"
_achievement.kill_target = "Mor'Ladim"
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
