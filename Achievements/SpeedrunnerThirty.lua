local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.SpeedrunnerThirty = _achievement

-- General info
_achievement.name = "SpeedrunnerThirty"
_achievement.title = "Speedrunner (30)"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_speedrunner.blp"
_achievement.category = "Miscellaneous"
_achievement.level_cap = 30
_achievement.played_time_threshold = 27 * 60 * 60
_achievement.bl_text = "Miscellaneous"
_achievement.pts = 10
_achievement.description = "Reach level "
	.. _achievement.level_cap
	.. " within "
	.. _achievement.played_time_threshold / 60 / 60
	.. " hours of play time."
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
}

-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement.succeed_function_executor = succeed_function_executor
	_achievement:RegisterEvent("PLAYER_LEVEL_UP")
	_achievement:RegisterEvent("TIME_PLAYED_MSG")
end

function _achievement:Unregister()
	_achievement:UnRegisterEvent("PLAYER_LEVEL_UP")
	_achievement:UnRegisterEvent("TIME_PLAYED_MSG")
end

local recently_leveled = false

-- Register Definitions
_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_LEVEL_UP" then
		local new_level = arg[1]
		if new_level == _achievement.level_cap then
			recently_leveled = true
			RequestTimePlayed()
		end
	elseif event == "TIME_PLAYED_MSG" then
		local seconds_played = arg[1]
		if recently_leveled == false then
			return
		end
		recently_leveled = false
		if seconds_played <= _achievement.played_time_threshold then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end)
