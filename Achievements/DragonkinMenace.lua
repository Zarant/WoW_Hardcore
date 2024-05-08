local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.DragonkinMenace = _achievement

-- General info
_achievement.name = "DragonkinMenace"
_achievement.title = "Pushing Back the Dragonkin"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_dragonkin_menace.blp"
_achievement.level_cap = 57
_achievement.quest_num = 4182
_achievement.quest_name = "Dragonkin Menace"
_achievement.zone = "Burning Steppes"
_achievement.faction = "Alliance"
_achievement.bl_text = "Burning Steppes Quest"
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
