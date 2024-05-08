local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.RitesOfTheEarthmother = _achievement

-- General info
_achievement.name = "RitesOfTheEarthmother"
_achievement.title = "Arra'chea goes down"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_rites_of_the_earthmother.blp"
_achievement.level_cap = 11
_achievement.quest_num = 776
_achievement.quest_name = "Rites of the Earthmother"
_achievement.zone = "Mulgore"
_achievement.kill_target = "Arra'chea"
_achievement.faction = "Horde"
_achievement.bl_text = "Mulgore Quest"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementKillDescription(
	_achievement.kill_target,
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
