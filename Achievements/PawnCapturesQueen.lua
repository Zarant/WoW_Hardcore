local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.PawnCapturesQueen = _achievement

-- General info
_achievement.name = "PawnCapturesQueen"
_achievement.title = "Brain of the Queen"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_pawn_captures_queen.blp"
_achievement.level_cap = 56
_achievement.quest_num = 4507
_achievement.quest_name = "Pawn Captures Queen"
_achievement.bl_text = "Un'Goro Crater Quest"
_achievement.zone = "Un'Goro"
_achievement.pts = 10
_achievement.kill_target = "Gorishi Hive Queen"
_achievement.description = HCGeneratePassiveAchievementKillDescription(
	_achievement.kill_target,
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
