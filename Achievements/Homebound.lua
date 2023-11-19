local _G = _G
local homebound_achievement = CreateFrame("Frame")
_G.achievements.Homebound = homebound_achievement

local function getContinent()
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID then
		local info = C_Map.GetMapInfo(mapID)
		if info then
			while info["mapType"] and info["mapType"] > 2 do
				info = C_Map.GetMapInfo(info["parentMapID"])
			end
			if info["mapType"] == 2 then
				return info["mapID"]
			end
		end
	end
end

local kalimdor_id = 1414
local eastern_kingdoms_id = 1415

-- General info
homebound_achievement.name = "Homebound"
homebound_achievement.title = "Homebound"
homebound_achievement.class = "All"
homebound_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_homebound.blp"
homebound_achievement.bl_text = "Starting Achievement"
homebound_achievement.pts = 50
homebound_achievement.description =
	"Complete the Hardcore challenge without at any point leaving the continent on which your character has started. If you started in Kalimdor, you may at no point enter the Eastern Kingdoms. If you started in the Eastern Kingdoms, you may at no point enter Kalimdor."

homebound_achievement.restricted_game_versions = {
	["WotLK"] = 1,
}

-- Registers
function homebound_achievement:Register(fail_function_executor)
	homebound_achievement:RegisterEvent("ZONE_CHANGED")
	homebound_achievement.fail_function_executor = fail_function_executor
end

function homebound_achievement:Unregister()
	homebound_achievement:UnregisterEvent("ZONE_CHANGED")
end

-- Register Definitions
homebound_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "ZONE_CHANGED" then
		local current_zone = GetZoneText()
		local _, race_english = UnitRace("player")
		if
			race_english == "Human"
			or race_english == "Undead"
			or race_english == "Dwarf"
			or race_english == "Gnome"
		then
			if getContinent() == kalimdor_id then
				Hardcore:Print("Detected entering zone " .. current_zone .. ".")
				homebound_achievement.fail_function_executor.Fail(homebound_achievement.name)
			end
		end

		if
			race_english == "Orc"
			or race_english == "Night Elf"
			or race_english == "Tauren"
			or race_english == "Troll"
		then
			if getContinent() == eastern_kingdoms_id then
				Hardcore:Print("Detected entering zone " .. current_zone .. ".")
				homebound_achievement.fail_function_executor.Fail(homebound_achievement.name)
			end
		end
	end
end)
