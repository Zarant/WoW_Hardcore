local _G = _G
local nudist_achievement = CreateFrame("Frame")
_G.achievements.Nudist = nudist_achievement

-- General info
nudist_achievement.name = "Nudist"
nudist_achievement.title = "Nudist"
nudist_achievement.class = "All"
nudist_achievement.pts = 25
nudist_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_nudist.blp"
nudist_achievement.description =
	"Complete the Hardcore challenge naked (no armor, no amulets, no rings, and no trinkets). Weapons, shields, and bags are allowed. Upon logging in, unequip every armor piece."

-- Registers
function nudist_achievement:Register(fail_function_executor)
	nudist_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	nudist_achievement:RegisterEvent("PLAYER_LEVEL_UP")
	nudist_achievement:RegisterEvent("PLAYER_ENTER_COMBAT")
	nudist_achievement:RegisterEvent("PLAYER_ENTERING_WORLD")
	nudist_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	nudist_achievement.fail_function_executor = fail_function_executor
end

function nudist_achievement:Unregister()
	nudist_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	nudist_achievement:UnregisterEvent("PLAYER_LEVEL_UP")
	nudist_achievement:UnregisterEvent("PLAYER_ENTER_COMBAT")
	nudist_achievement:UnregisterEvent("PLAYER_ENTERING_WORLD")
	nudist_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
nudist_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[1] > 1 and arg[1] < 16 then -- 1 ammo, 16+ weapons
			-- Equipped an item if true
			if arg[2] ~= true then
				-- Timed for accidental equips
				nudist_achievement:TimedNudistFailure()
			end
		end
	elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTER_COMBAT" or event == "UNIT_SPELLCAST_SUCCEEDED" then
		-- Instant when it can affect actual gameplay
		nudist_achievement:CheckNudistFailure()
	elseif event == "PLAYER_ENTERING_WORLD" then
		if nudist_achievement:HasEquipment() then
			-- Timed when entering the world, delay so they can hear the sound
			C_Timer.After(0, function() nudist_achievement:TimedNudistFailure() end)
		end
	end
end)

function nudist_achievement:HasEquipment()
	for i = 2, 15 do
		if GetInventoryItemID("player", i) then
			return true
		end
	end
end

function nudist_achievement:CheckNudistFailure()
	if nudist_achievement:HasEquipment() then
		nudist_achievement.fail_function_executor.Fail(nudist_achievement.name)
	end
end

function nudist_achievement:TimedNudistFailure()
	-- Check after 10 seconds if they still have items equipped
	C_Timer.After(10, function() nudist_achievement:CheckNudistFailure() end)
	Hardcore:Print("NUDIST: Equipped an item\nUnequip within 10 seconds or you will fail the Achievement")
	Hardcore:ShowAlertFrame(Hardcore.ALERT_STYLES.hc_red, "NUDIST: Equipped an item\nUnequip within 10 seconds or you will fail the Achievement")
end
