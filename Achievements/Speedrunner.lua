local _G = _G
local speedrunner_achievement = CreateFrame("Frame")
_G.achievements.Speedrunner = speedrunner_achievement

local in_game_limit_seconds = 100 * 60 * 60 -- seconds

-- General info
speedrunner_achievement.name = "Speedrunner"
speedrunner_achievement.title = "Speedrunner"
speedrunner_achievement.class = "All"
speedrunner_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_speedrunner.blp"
speedrunner_achievement.description =
	"Complete the Hardcore challenge in less than 100 hours (4 days and 4 hours) of played time. Make sure to show your /played time when you hit 60. The run must be completed within eight weeks of real time. You are NOT allowed to log off in rested areas."
speedrunner_achievement.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
}

speedrunner_achievement.adjusted_time = nil
speedrunner_achievement.hardcore_char_ref = nil

local time_played_snapshot = nil
local snapshot_server_time = nil
local first_recorded = nil

local function CalculateAdjustedTime(_timeplayed, _irl_time)
	local adjusted_time = _timeplayed
	if _irl_time / 86400 > 14 then
		adjusted_time = adjusted_time + (_irl_time - (86400 * 14)) * 13.5 / 86400 * 60
	end
	return adjusted_time
end

-- Tests
-- if CalculateAdjustedTime(0, 15*86400) ~= 13.5*60 then error("error message") end
-- if CalculateAdjustedTime(5000, 15*86400) ~= 5000+13.5*60 then error("error message") end
-- if CalculateAdjustedTime(5000, 16*86400) ~= 5000+13.5*60*2 then error("error message") end
-- if CalculateAdjustedTime(5000, 14.5*86400) ~= 5000+13.5*60/2 then error("error message") end

-- Registers
function speedrunner_achievement:Register(fail_function_executor, _hardcore_character)
	speedrunner_achievement.fail_function_executor = fail_function_executor
	speedrunner_achievement.hardcore_char_ref = _hardcore_character
	if _hardcore_character.first_recorded == nil or _hardcore_character.first_recorded == -1 then
		Hardcore:Print("Could not register for Speedrunner achievement; invalid creation time")
		speedrunner_achievement.fail_function_executor = fail_function_executor
		return
	end
	first_recorded = _hardcore_character.first_recorded

	RequestTimePlayed()
	speedrunner_achievement:RegisterEvent("PLAYER_LEVEL_UP")
	speedrunner_achievement:RegisterEvent("TIME_PLAYED_MSG")
end

function speedrunner_achievement:Unregister()
	speedrunner_achievement:UnregisterEvent("PLAYER_LEVEL_UP")
	speedrunner_achievement:UnregisterEvent("TIME_PLAYED_MSG")
end

function speedrunner_achievement:UpdateDescription()
	speedrunner_achievement.description =
		"Complete the Hardcore challenge in less than 100 hours (4 days and 4 hours) of adjusted played time. Make sure to show your /played time when you hit 60. Adjusted played time is equal to played time + 13.5 minutes for every real life day that exceeds 14 days."

	local timeplayed = time_played_snapshot + GetServerTime() - snapshot_server_time
	local irl_time = GetServerTime() - first_recorded
	speedrunner_achievement.adjusted_time = CalculateAdjustedTime(timeplayed, irl_time)
	speedrunner_achievement.description = speedrunner_achievement.description
		.. "\n|c00FFFF00Played Time: "
		.. SecondsToTime(timeplayed, false)
		.. "|r."
		.. "\n|c00FFFF00IRL Time: "
		.. SecondsToTime(irl_time, false)
		.. "|r."
		.. "\n|c00FFFF00Adjusted Time: "
		.. SecondsToTime(speedrunner_achievement.adjusted_time, false)
		.. "|r."
end

-- Register Definitions
speedrunner_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_LEVEL_UP" then
		RequestTimePlayed()
		if arg[1] == 60 then
			speedrunner_achievement.UpdateDescription()
			speedrunner_achievement.hardcore_char_ref.adjusted_sixty_time = speedrunner_achievement.adjusted_time
		end
	elseif event == "TIME_PLAYED_MSG" then
		local seconds_played = arg[1]
		time_played_snapshot = seconds_played
		snapshot_server_time = GetServerTime()
		speedrunner_achievement:UpdateDescription()

		if speedrunner_achievement.adjusted_time > in_game_limit_seconds then
			Hardcore:Print("Exceeded game time limit of 100 hours.")
			speedrunner_achievement.fail_function_executor.Fail(speedrunner_achievement.name)
		end
	end
end)
