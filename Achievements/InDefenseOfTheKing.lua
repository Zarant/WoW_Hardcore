local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.InDefenseOfTheKing = _achievement

-- General info
_achievement.name = "InDefenseOfTheKing"
_achievement.title = "Grawmug Taken Down!"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_in_defense_of_the_king.blp"
_achievement.level_cap = 16
_achievement.quest_num = 217
_achievement.quest_name = "In Defense of the King's Land"
_achievement.zone = "Loch Modan"
_achievement.kill_target = "Grawmug"
_achievement.faction = "Alliance"
_achievement.bl_text = "Loch Modan Quest"
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
