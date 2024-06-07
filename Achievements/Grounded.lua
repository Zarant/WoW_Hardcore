local _G = _G
local grounded_achievement = CreateFrame("Frame")
_G.achievements.Grounded = grounded_achievement

local blacklist_spells_named = {
	["Teleport: Stormwind"] = 1,
	["Teleport: Ogrimmar"] = 1,
	["Teleport: Darnassus"] = 1,
	["Teleport: Undercity"] = 1,
	["Teleport: Ironforge"] = 1,
	["Teleport: Thunder Bluff"] = 1,
}

-- General info
grounded_achievement.name = "Grounded"
grounded_achievement.title = "Grounded"
grounded_achievement.class = "All"
grounded_achievement.bl_text = "Starting Achievement"
grounded_achievement.pts = 15
grounded_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_grounded.blp"
grounded_achievement.description =
	"Complete the Hardcore challenge without at any point using a mount, flight path, or portal. Zeppelins and ships can be used."
grounded_achievement.mouse_over_portal = false

-- Registers
function grounded_achievement:Register(fail_function_executor)
	grounded_achievement:RegisterEvent("PLAYER_CONTROL_LOST")
	grounded_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	grounded_achievement:RegisterEvent("CURSOR_CHANGED")
	grounded_achievement:RegisterEvent("GLOBAL_MOUSE_DOWN")
	grounded_achievement.fail_function_executor = fail_function_executor
	hooksecurefunc(StaticPopupDialogs["CONFIRM_SUMMON"], "OnAccept", function(self, button)
		grounded_achievement.fail_function_executor.Fail(grounded_achievement.name)
	end)
end

function grounded_achievement:Unregister()
	grounded_achievement:UnregisterEvent("PLAYER_CONTROL_LOST")
	grounded_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	grounded_achievement:UnregisterEvent("CURSOR_CHANGED")
	grounded_achievement:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end

local function isMagePortal(...)
	for i = 1, select("#", ...) do
		local region = select(i, ...)
		if region and region:GetObjectType() == "FontString" then
			local text = region:GetText() -- string or nil
			if text ~= nil then
				if string.find(text, "Portal to") ~= nil then -- e.g. "Portal to Stormwind"
					return true
				end
			end
		end
	end
	return false
end

-- Register Definitions
grounded_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_CONTROL_LOST" then
		C_Timer.After(5, function()
			if UnitOnTaxi("player") then
				Hardcore:Print("Player is on taxi")
				grounded_achievement.fail_function_executor.Fail(grounded_achievement.name)
			end
		end)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if IsMounted() then
			Hardcore:Print("Player is on mount")
			grounded_achievement.fail_function_executor.Fail(grounded_achievement.name)
			return
		end

		local unit, _, spell_id, _, _ = ...
		if unit ~= "player" then
			return
		end
		local spell_name = GetSpellInfo(spell_id)
		if blacklist_spells_named[spell_name] ~= nil then
			Hardcore:Print("Casted teleport spell" .. spell_name)
			grounded_achievement.fail_function_executor.Fail(grounded_achievement.name)
		end
	elseif event == "CURSOR_CHANGED" then
		C_Timer.After(0.01, function()
			if isMagePortal(GameTooltip:GetRegions()) then
				grounded_achievement.mouse_over_portal = not grounded_achievement.mouse_over_portal
			else
				grounded_achievement.mouse_over_portal = false
			end
		end)
	elseif event == "GLOBAL_MOUSE_DOWN" then
		if arg[1] == "RightButton" then
			if grounded_achievement.mouse_over_portal then
				grounded_achievement.fail_function_executor.Fail(grounded_achievement.name)
			end
		end
	end
end)
