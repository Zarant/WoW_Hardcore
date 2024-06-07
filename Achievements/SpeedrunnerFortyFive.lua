local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.SpeedrunnerFortyFive = _achievement

-- General info
_achievement.name = "SpeedrunnerFortyFive"
_achievement.title = "Speedrunner (45)"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_speedrunner.blp"
_achievement.category = "Miscellaneous"
_achievement.level_cap = 45
_achievement.bl_text = "Miscellaneous"
_achievement.description = "Reach level 45 by x time"
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
}

-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement.succeed_function_executor = succeed_function_executor
end

function _achievement:Unregister() end

-- Register Definitions
_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
end)
