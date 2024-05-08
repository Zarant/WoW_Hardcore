local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.CuergosGold = _achievement

-- General info
_achievement.name = "CuergosGold"
_achievement.title = "The Hidden Treasure"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_cuergos_gold.blp"
_achievement.level_cap = 45
_achievement.quest_num = 2882
_achievement.quest_name = "Cuergo's Gold"
_achievement.zone = "Tanaris"
_achievement.pts = 10
_achievement.bl_text = "Tanaris Quest"
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
