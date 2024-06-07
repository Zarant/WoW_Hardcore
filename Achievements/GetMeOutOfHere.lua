local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.GetMeOutOfHere = _achievement

-- General info
_achievement.name = "GetMeOutOfHere"
_achievement.title = "An Ally Saved"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_get_me_out_of_here.blp"
_achievement.level_cap = 41
_achievement.quest_num = 6132
_achievement.quest_name = "Get Me Out of Here!"
_achievement.zone = "Desolace"
_achievement.bl_text = "Desolace Quest"
_achievement.pts = 10
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
