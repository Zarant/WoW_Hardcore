local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.MasterEngineering = _achievement

-- General info
_achievement.name = "MasterEngineering"
_achievement.title = "Master Engineering"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_master_engineering.blp"
_achievement.level_cap = 50
_achievement.category = "Profession"
_achievement.bl_text = "Profession"
_achievement.pts = 10
_achievement.craft_set = {
	["Masterwork Target Dummy"] = 1,
}
_achievement.craft_name = "[Masterwork Target Dummy]"
_achievement.description =
	HCGeneratePassiveAchievementCraftedDescription(_achievement.craft_name, _achievement.level_cap)
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
}

-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement:RegisterEvent("CHAT_MSG_LOOT")
	_achievement.succeed_function_executor = succeed_function_executor
end

function _achievement:Unregister()
	_achievement:UnregisterEvent("CHAT_MSG_LOOT")
end

-- Register Definitions
_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	HCCommonPassiveAchievementCraftedCheck(_achievement, event, arg)
end)
