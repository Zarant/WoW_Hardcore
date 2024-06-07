local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.NothingButTheTruth = _achievement

-- General info
_achievement.name = "NothingButTheTruth"
_achievement.title = "Serum to the Forsaken"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_seagiant.blp"
_achievement.level_cap = 40
_achievement.quest_num = 1383
_achievement.quest_name = "Nothing but the Truth"
_achievement.zone = "Duskwood"
_achievement.bl_text = "Duskwood Quest"
_achievement.faction = "Horde"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementBasicQuestDescription(
	_achievement.quest_name,
	_achievement.zone,
	_achievement.level_cap,
	"Horde"
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
