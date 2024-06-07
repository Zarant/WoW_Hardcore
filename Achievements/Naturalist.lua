local _G = _G
local naturalist_achievement = CreateFrame("Frame")
_G.achievements.Naturalist = naturalist_achievement

local blacklist_spells_named = {
	"Cat Form",
	"Bear Form",
	"Dire Bear Form",
	"Travel Form",
	"Aquatic Form",
	"Flight Form",
}

-- General info
naturalist_achievement.name = "Naturalist"
naturalist_achievement.title = "Naturalist"
naturalist_achievement.class = "Druid"
naturalist_achievement.pts = 10
naturalist_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_naturalist.blp"
naturalist_achievement.description =
	"Complete the Hardcore challenge without at any point using a shape shifting ability. Travel Form and Aquatic Form are not allowed. Items and quests that make you change your form are allowed."

-- Registers
function naturalist_achievement:Register(fail_function_executor)
	naturalist_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	naturalist_achievement.fail_function_executor = fail_function_executor
end

function naturalist_achievement:Unregister()
	naturalist_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
naturalist_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit ~= "player" then
			return
		end
		for i, blacklist_spell_named in ipairs(blacklist_spells_named) do
			local spell_name = GetSpellInfo(spell_id)
			if spell_name == blacklist_spell_named then
				Hardcore:Print("Casted shape shift spell." .. blacklist_spell_named)
				naturalist_achievement.fail_function_executor.Fail(naturalist_achievement.name)
			end
		end
	end
end)
