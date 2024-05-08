local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.SealOfEarth = _achievement

-- General info
_achievement.name = "SealOfEarth"
_achievement.title = "Kill the Betrayer"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_seal_the_earth.blp"
_achievement.level_cap = 40
_achievement.quest_num = 782
_achievement.quest_name = "Broken Alliances"
_achievement.zone = "Badlands"
_achievement.kill_target = "Boss Tho'grun"
_achievement.faction = "Horde"
_achievement.bl_text = "Badlands Quest"
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
