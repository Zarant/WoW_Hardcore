local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.SummoningThePrincess = _achievement

-- General info
_achievement.name = "SummoningThePrincess"
_achievement.title = "Myzrael to the Shadowrealm"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_summoning_the_princess.blp"
_achievement.level_cap = 55
_achievement.quest_num = 656
_achievement.quest_name = "Summoning the Princess"
_achievement.zone = "Arathi Highlands"
_achievement.kill_target = "Myzrael"
_achievement.pts = 10
_achievement.bl_text = "Arathi Highlands Quest"
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
