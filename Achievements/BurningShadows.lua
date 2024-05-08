local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.BurningShadows = _achievement

-- General info
_achievement.name = "BurningShadows"
_achievement.title = "Burning Shadows"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_voidwalker.blp"
_achievement.level_cap = 12
_achievement.quest_num = 832
_achievement.quest_name = "Burning Shadows"
_achievement.zone = "Durotar"
_achievement.kill_target = "Gazz'uz"
_achievement.bl_text = "Durotar Quest"
_achievement.pts = 10
_achievement.faction = "Horde"
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
