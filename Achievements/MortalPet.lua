local _G = _G
local mortal_pet_achievement = CreateFrame("Frame")
_G.achievements.MortalPet = mortal_pet_achievement

-- General info
mortal_pet_achievement.name = "MortalPet"
mortal_pet_achievement.title = "Mortal Pet"
mortal_pet_achievement.class = "Hunter"
mortal_pet_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_mortal_pet.blp"
mortal_pet_achievement.pts = 10
mortal_pet_achievement.description =
	"Complete the Hardcore challenge without at any point resurrecting your pet. If your pet dies for any reason, you have to release it and tame another one."

-- Registers
function mortal_pet_achievement:Register(fail_function_executor)
	mortal_pet_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	mortal_pet_achievement.fail_function_executor = fail_function_executor
end

function mortal_pet_achievement:Unregister()
	mortal_pet_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
mortal_pet_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id, _, _ = ...
		if unit == "player" and spell_id == 982 then
			mortal_pet_achievement.fail_function_executor.Fail(mortal_pet_achievement.name)
		end
	end
end)
