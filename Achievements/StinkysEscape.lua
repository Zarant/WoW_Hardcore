local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.StinkysEscape = _achievement

-- General info
_achievement.name = "StinkysEscape"
_achievement.title = "Stinky's Escape"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_stinkys_escape.blp"
_achievement.level_cap = 34
_achievement.quest_num = 1270
_achievement.quest_num_alt = 1222
_achievement.quest_name = "Stinky's Escape"
_achievement.bl_text = "Dustwallow Marsh Quest"
_achievement.pts = 10
_achievement.zone = "Dustwallow Marsh"
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
	HCCommonPassiveAchievementAltBasicQuestCheck(_achievement, event, arg)
end)
