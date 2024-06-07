local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.TheFamilyCrypt = _achievement

-- General info
_achievement.name = "TheFamilyCrypt"
_achievement.title = "Captain Dargol Goes Back to the Grave"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_the_family_crypt.blp"
_achievement.level_cap = 11
_achievement.quest_num = 408
_achievement.quest_name = "The Family Crypt"
_achievement.zone = "Tirisfal Glades"
_achievement.kill_target = "Captain Dargol"
_achievement.bl_text = "Tirisfal Glades Quest"
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
