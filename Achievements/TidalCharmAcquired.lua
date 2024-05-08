local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.TidalCharmAcquired = _achievement

-- General info
_achievement.name = "TidalCharmAcquired"
_achievement.title = "Tidal Charm Acquired"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_tidal_charm.blp"
_achievement.level_cap = 59
_achievement.item = "Tidal Charm"
_achievement.item_rarity = "Uncommon"
_achievement.category = "Miscellaneous"
_achievement.bl_text = "Miscellaneous"
_achievement.pts = 10
_achievement.description = HCGeneratePassiveAchievementItemAcquiredDescription(
	_achievement.item,
	_achievement.item_rarity,
	_achievement.level_cap
)
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
	HCCommonPassiveAchievementItemAcquiredCheck(_achievement, event, arg)
end)
