local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.MasterTailoring = _achievement

-- General info
_achievement.name = "MasterTailoring"
_achievement.title = "Master Tailoring"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_master_tailoring.blp"
_achievement.level_cap = 50
_achievement.bl_text = "Profession"
_achievement.pts = 10
_achievement.craft_set = {
	["Dreamweave Gloves"] = 1,
	["Dreamweave Circlet"] = 1,
	["Dreamweave Vest"] = 1,
}
_achievement.craft_name =
	"|cff0070dd[Dreamweave Gloves]|r, |cff0070dd[Dreamweave Circlet]|r, and |cff0070dd[Dreamweave Vest]|r"
_achievement.category = "Profession"
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
