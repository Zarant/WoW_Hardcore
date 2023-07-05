local _G = _G
local close_combat_achievement = CreateFrame("Frame")
_G.achievements.CloseCombat = close_combat_achievement

-- General info
close_combat_achievement.name = "CloseCombat"
close_combat_achievement.title = "Close Combat"
close_combat_achievement.class = "Hunter"
close_combat_achievement.bl_text = "Starting Achievement"
close_combat_achievement.pts = 10
close_combat_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_close_combat.blp"
close_combat_achievement.description =
	"Complete the Hardcore challenge without at any point using a ranged weapon attack (any ability requiring a ranged weapon to be equipped). Upon logging in, unequip your ranged weapon and quiver and never equip a new one. Throwing weapons are not allowed."

-- Registers
function close_combat_achievement:Register(fail_function_executor)
	close_combat_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	close_combat_achievement:RegisterEvent("PLAYER_LEVEL_UP")
	close_combat_achievement.fail_function_executor = fail_function_executor
end

function close_combat_achievement:Unregister()
	close_combat_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	close_combat_achievement:UnregisterEvent("PLAYER_LEVEL_UP")
end

-- Register Definitions
close_combat_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
		if item_type == "Weapon" then
			if item_subtype == "Bows" or item_subtype == "Guns" or item_subtype == "Thrown" then
				Hardcore:Print("Equipped " .. item_name .. ".")
				close_combat_achievement.fail_function_executor.Fail(close_combat_achievement.name)
			end
		end
	end
end)
