local _G = _G
local berserker_achievement = CreateFrame("Frame")
_G.achievements.Berserker = berserker_achievement

-- General info
berserker_achievement.name = "Berserker"
berserker_achievement.title = "Berserker"
berserker_achievement.class = "Warrior"
berserker_achievement.pts = 10
berserker_achievement.bl_text = "Starting Achievement"
berserker_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_berserker.blp"
berserker_achievement.description =
	"Complete the Hardcore challenge without at any point equipping Mail or Plate armor or a Shield. Only cloth and leather armor are allowed. If your race starts with a Shield, unequip it upon logging in."

-- Registers
function berserker_achievement:Register(fail_function_executor)
	berserker_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	berserker_achievement:RegisterEvent("PLAYER_LEVEL_UP")
	berserker_achievement.fail_function_executor = fail_function_executor
end

function berserker_achievement:Unregister()
	berserker_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	berserker_achievement:UnregisterEvent("PLAYER_LEVEL_UP")
end

-- Register Definitions
berserker_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
		if item_type == "Armor" then
			if item_subtype == "Shields" or item_subtype == "Mail" or item_subtype == "Plate" then
				local time_elapsed = 0 -- seconds
				C_Timer.NewTicker(1, function(self)
					time_elapsed = time_elapsed + 1
					Hardcore:Print(
						"<Berserker>: Unequip Mail or Plate weapon, "
							.. item_name
							.. ", or your achievement will fail in "
							.. 60 - time_elapsed
							.. " seconds."
					)
					if IsEquippedItem(item_id) == false then
						Hardcore:Print("<Berserker>: You unequipped " .. item_name .. ". No further action needed.")
						self:Cancel()
						return
					end
					if time_elapsed > 60 then
						Hardcore:Print("Equipped " .. item_name .. ".")
						berserker_achievement.fail_function_executor.Fail(berserker_achievement.name)

						self:Cancel()
					end
				end)
			end
		end
	elseif event == "PLAYER_LEVEL_UP" then
		for i = 1, 15 do
			local item_id = GetInventoryItemID("player", i)
			if item_id ~= nil then
				local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
				if item_type == "Armor" then
					if item_subtype == "Shields" or item_subtype == "Mail" or item_subtype == "Plate" then
						Hardcore:Print("Equipped " .. item_name .. ".")
						berserker_achievement.fail_function_executor.Fail(berserker_achievement.name)
					end
				end
			end
		end
	end
end)
