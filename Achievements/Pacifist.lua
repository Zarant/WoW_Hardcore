local _G = _G
local pacifist_achievement = CreateFrame("Frame")
_G.achievements.Pacifist = pacifist_achievement

-- General info
pacifist_achievement.name = "Pacifist"
pacifist_achievement.title = "Pacifist"
pacifist_achievement.class = "Priest"
pacifist_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_pacifist.blp"
pacifist_achievement.pts = 10
pacifist_achievement.description =
	"Complete the Hardcore challenge without at any point wielding a weapon. One-handed weapons, staves, and wands are not allowed. Upon logging in, unequip your weapon and never equip a new one. All off-hand items and fishing poles are allowed."

-- Registers
function pacifist_achievement:Register(fail_function_executor)
	pacifist_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	pacifist_achievement.fail_function_executor = fail_function_executor
end

function pacifist_achievement:Unregister()
	pacifist_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

-- Register Definitions
pacifist_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
		if item_type == "Weapon" then
			print(item_subtype)
			if item_subtype == "Fishing Poles" or item_subtype == "Fishing Pole" or item_subtype == "Miscellaneous" then
				return
			end
			Hardcore:Print("Equipped " .. item_name .. ".")
			pacifist_achievement.fail_function_executor.Fail(pacifist_achievement.name)
		end
	end
end)
