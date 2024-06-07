local _G = _G
local white_knight_achievement = CreateFrame("Frame")
_G.achievements.WhiteKnight = white_knight_achievement

-- General info
white_knight_achievement.name = "WhiteKnight"
white_knight_achievement.title = "White Knight"
white_knight_achievement.class = "All"
white_knight_achievement.pts = 15
white_knight_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_white_knight.blp"
white_knight_achievement.description =
	"Complete the Hardcore challenge without at any point equipping an item that is of Green, Blue, or Purple quality. Only White and Gray items are allowed. Bags are equipped items."

-- Registers
function white_knight_achievement:Register(fail_function_executor)
	white_knight_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	white_knight_achievement.fail_function_executor = fail_function_executor
end

function white_knight_achievement:Unregister()
	white_knight_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

-- Register Definitions
white_knight_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... } --- arg1: inventory index, arg2: isEmpty on update
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, item_rarity, _, _, _, _, _, _, _, _ = GetItemInfo(item_id)
		if item_rarity > 1 then -- 0: poor (gray), 1: common (white), 2: uncommon (green) ...
			Hardcore:Print("Equiped " .. item_name .. " with rarity " .. item_rarity)
			white_knight_achievement.fail_function_executor.Fail(white_knight_achievement.name)
		end
	end
end)
