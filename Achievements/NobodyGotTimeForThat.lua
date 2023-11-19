local _G = _G
local nobody_got_time_for_that_achievement = CreateFrame("Frame")
_G.achievements.NobodyGotTimeForThat = nobody_got_time_for_that_achievement

local profession_names = {
	"Alchemy",
	"Tailoring",
	"Blacksmithing",
	"Cooking",
	"Enchanting",
	"Engineering",
	"Herbalism",
	"First Aid",
	"Fishing",
	"Mining",
	"Leatherworking",
	"Skinning",
	"Tailoring",
	"Jewelcrafting",
	"Inscription",
}

-- General info
nobody_got_time_for_that_achievement.name = "NobodyGotTimeForThat"
nobody_got_time_for_that_achievement.pts = 25
nobody_got_time_for_that_achievement.title = "Nobody Got Time For That"
nobody_got_time_for_that_achievement.class = "All"
nobody_got_time_for_that_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_nobody_got_time_for_that.blp"
nobody_got_time_for_that_achievement.description =
	"Complete the Hardcore challenge without learning or using any professions. Secondary professions such as Cooking, Fishing and First Aid are not allowed. Lockpicking, Poisons, and Beast Training are class skills, not professions."
if _G["HardcoreBuildLabel"] == "WotLK" then
	nobody_got_time_for_that_achievement.warnings = {
		"Note: Unavailable for Death Knights.",
	}
end

-- Registers
function nobody_got_time_for_that_achievement:Register(fail_function_executor)
	nobody_got_time_for_that_achievement:RegisterEvent("SKILL_LINES_CHANGED")
	nobody_got_time_for_that_achievement.fail_function_executor = fail_function_executor
end

function nobody_got_time_for_that_achievement:Unregister()
	nobody_got_time_for_that_achievement:UnregisterEvent("SKILL_LINES_CHANGED")
end

-- Register Definitions
nobody_got_time_for_that_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SKILL_LINES_CHANGED" then
		for i = 1, GetNumSkillLines() do
			local arg = GetSkillLineInfo(i)
			for i, profession in ipairs(profession_names) do
				if arg == profession then
					Hardcore:Print("Learned " .. profession .. " profession.")
					nobody_got_time_for_that_achievement.fail_function_executor.Fail(
						nobody_got_time_for_that_achievement.name
					)
				end
			end
		end
	end
end)
