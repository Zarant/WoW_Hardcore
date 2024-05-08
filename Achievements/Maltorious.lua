local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.Maltorious = _achievement

-- General info
_achievement.name = "Maltorious"
_achievement.title = "Head of the Dark Iron Slag Pit"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_maltorious.blp"
_achievement.level_cap = 56
_achievement.quest_num = 7701
_achievement.quest_name = "WANTED: Overseer Maltorious"
_achievement.zone = "Searing Gorge"
_achievement.kill_target = "Overseer Maltorious"
_achievement.pts = 10
_achievement.bl_text = "Searing Gorge Quest"
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
