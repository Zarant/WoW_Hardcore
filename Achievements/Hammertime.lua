local _G = _G
local hammertime_achievement = CreateFrame("Frame")
_G.achievements.Hammertime = hammertime_achievement

-- General info
hammertime_achievement.name = "Hammertime"
hammertime_achievement.title = "Hammertime"
hammertime_achievement.class = "Paladin"
hammertime_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_hammertime.blp"
hammertime_achievement.bl_text = "Starting Achievement"
hammertime_achievement.pts = 10
hammertime_achievement.description =
	"Complete the Hardcore challenge without at any point equpping a melee weapon other than a two-handed mace. Fishing Pole is acceptable"

-- Registers
function hammertime_achievement:Register(fail_function_executor)
	hammertime_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	hammertime_achievement.fail_function_executor = fail_function_executor
end

function hammertime_achievement:Unregister()
	hammertime_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

-- Register Definitions
hammertime_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
		if arg[1] == 16 then -- Mainhand
			-- Checks if the mainhand is of type weapon, then checks to make sure it is not of Fishing Poles type and not of Two Handed Maces type,
			-- If it passes those checks the player fails.
			if item_type == "Weapon" then
				if item_subtype == "Fishing Poles" or item_subtype == "Fishing Pole" then
					return
				else
					if item_subtype ~= "Two-Handed Maces" then
						Hardcore:Print("Equipped " .. item_name .. ".")
						hammertime_achievement.fail_function_executor.Fail(hammertime_achievement.name)
					end
				end
			end
		elseif arg[1] == 17 then -- Offhand
			Hardcore:Print("Equipped " .. item_name .. ".")
			hammertime_achievement.fail_function_executor.Fail(hammertime_achievement.name)
		end
	end
end)
