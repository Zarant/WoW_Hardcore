local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.MasterFirstAid = _achievement

-- General info
_achievement.name = "MasterFirstAid"
_achievement.title = "Master Doctor"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_master_first_aid.blp"
_achievement.level_cap = 59
_achievement.profession_name = "First Aid"
_achievement.bl_text = "Profession"
_achievement.pts = 10
_achievement.profession_threshold = 300
_achievement.category = "Profession"
_achievement.description = HCGeneratePassiveAchievementProfLevelDescription(
	_achievement.profession_name,
	_achievement.profession_threshold,
	_achievement.level_cap
)
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
}

-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement:RegisterEvent("SKILL_LINES_CHANGED")
	_achievement:RegisterEvent("PLAYER_ENTERING_WORLD")
	_achievement.succeed_function_executor = succeed_function_executor
end

function _achievement:Unregister()
	_achievement:UnregisterEvent("SKILL_LINES_CHANGED")
end

-- Register Definitions
_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	HCCommonPassiveAchievementProfLevelCheck(_achievement, event, arg)
end)
