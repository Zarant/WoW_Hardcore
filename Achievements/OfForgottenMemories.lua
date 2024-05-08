local _G = _G
local of_forgotten_memories = CreateFrame("Frame")
_G.passive_achievements.OfForgottenMemories = of_forgotten_memories

-- General info
of_forgotten_memories.name = "OfForgottenMemories"
of_forgotten_memories.title = "Grave Digger"
of_forgotten_memories.class = "All"
of_forgotten_memories.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_grave_digger.blp"
of_forgotten_memories.level_cap = 57
of_forgotten_memories.quest_num = 5781
of_forgotten_memories.zone = "Eastern Plaguelands"
of_forgotten_memories.bl_text = "Eastern Plaguelands Quest"
of_forgotten_memories.pts = 10
of_forgotten_memories.quest_name = "Of Forgotten Memories"
of_forgotten_memories.kill_target = "Mercutio Filthgorger"
of_forgotten_memories.description = HCGeneratePassiveAchievementKillDescription(
	of_forgotten_memories.kill_target,
	of_forgotten_memories.quest_name,
	of_forgotten_memories.zone,
	of_forgotten_memories.level_cap
)
of_forgotten_memories.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
}

-- Registers
function of_forgotten_memories:Register(succeed_function_executor)
	of_forgotten_memories:RegisterEvent("QUEST_TURNED_IN")
	of_forgotten_memories.succeed_function_executor = succeed_function_executor
end

function of_forgotten_memories:Unregister()
	of_forgotten_memories:UnregisterEvent("QUEST_TURNED_IN")
end

-- Register Definitions
of_forgotten_memories:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	HCCommonPassiveAchievementBasicQuestCheck(of_forgotten_memories, event, arg)
end)
