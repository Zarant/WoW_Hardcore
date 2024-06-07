local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.Deathclasp = _achievement

-- General info
_achievement.name = "Deathclasp"
_achievement.title = "Terror of the Sands Eliminated"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_deathclasp.blp"
_achievement.level_cap = 59
_achievement.quest_num = 8283
_achievement.zone = "Silithus"
_achievement.quest_name = "Wanted: Deathclasp, Terror of the Sands"
_achievement.kill_target = "Deathclasp"
_achievement.bl_text = "Silithus Quest"
_achievement.pts = 10
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
