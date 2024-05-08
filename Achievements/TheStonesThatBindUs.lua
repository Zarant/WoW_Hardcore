local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.TheStonesThatBindUs = _achievement

-- General info
_achievement.name = "TheStonesThatBindUs"
_achievement.title = "Not So Invincible"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_stones_that_bind_us.blp"
_achievement.level_cap = 54
_achievement.quest_num = 2681
_achievement.quest_name = "The Stones That Bind Us"
_achievement.zone = "Blasted Lands"
_achievement.bl_text = "Blasted Lands Quest"
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
