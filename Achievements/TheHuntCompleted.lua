local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.TheHuntCompleted = _achievement

-- General info
_achievement.name = "TheHuntCompleted"
_achievement.title = "Eradicate the Beasts"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_the_hunt_completed.blp"
_achievement.level_cap = 26
_achievement.quest_num = 247
_achievement.quest_name = "The Hunt Completed"
_achievement.zone = "Ashenvale"
_achievement.faction = "Horde"
_achievement.bl_text = "Ashenvale Quest"
_achievement.pts = 10 
_achievement.description = HCGeneratePassiveAchievementBasicQuestDescription(_achievement.quest_name, _achievement.zone, _achievement.level_cap, "Horde")
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
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
