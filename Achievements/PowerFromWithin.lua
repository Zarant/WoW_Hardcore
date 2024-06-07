local _G = _G
local power_from_within_achievement = CreateFrame("Frame")
_G.achievements.PowerFromWithin = power_from_within_achievement

-- General info
power_from_within_achievement.name = "PowerFromWithin"
power_from_within_achievement.title = "Power From Within"
power_from_within_achievement.class = "All"
power_from_within_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_power_from_within.blp"
power_from_within_achievement.description =
	"Complete the Hardcore challenge without getting any World Buffs. World Buffs are: Warchief’s Blessing, Rallying Cry of the Dragonslayer, and Spirit of Zandalar. If you get a World Buff by accident, click it off as soon as possible. Darkmoon Faire Fortune Buffs and Songflowers are allowed."

-- Registers
function power_from_within_achievement:Register(fail_function_executor)
	power_from_within_achievement:RegisterEvent("UNIT_AURA")
	power_from_within_achievement.fail_function_executor = fail_function_executor
end

function power_from_within_achievement:Unregister()
	power_from_within_achievement:UnregisterEvent("UNIT_AURA")
end

-- Register Definitions
power_from_within_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "UNIT_AURA" then
		if arg[1] == "player" then
			for i = 1, 40 do
				local buff_name, _, _, _, _, _, _, _, _, _, _ = UnitBuff("player", i)
				if buff_name == nil then
					return
				end
				if
					buff_name == "Warchief’s Blessing"
					or buff_name == "Rallying Cry of the Dragonslayer"
					or buff_name == "Spirit of Zandalar"
				then
					CancelUnitBuff("player", i)
					Hardcore:Print("Removing buff " .. buff_name .. ".")
				end
			end
		end
	end
end)
