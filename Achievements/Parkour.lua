-- Parkour.lua
-- Parkour jumping achievement for WOW Classic Hardcore Addon
-- Written by Frank de Jong

local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.Parkour = _achievement

-- 	General info
_achievement.name = "Parkour"
_achievement.title = "Parkour"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_speedrunner.blp"
_achievement.category = "Miscellaneous"
_achievement.level_cap = 60
_achievement.bl_text = "Miscellaneous"
_achievement.pts = 5
_achievement.description = "Jump to various hard to reach points in Orgrimmar and do a /flex there."
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
	["Cata"] = 1,
}

local first_aid_name = "First Aid"		-- Will be overwritten in the local language by UNIT_SPELLCAST_SUCCEEDED
local parkour_x, parkour_y				-- Retrieved once per callback event to prevent weirdness when you change halfway
local parkour_map_id = 0
local parkour_id_names = {
	["ORGAH"] = "Vanillaman's Lair",
	["ORGB1"] = "Keanu's Korner",
	["ORGB2"] = "Krueger's Point",		-- Dedicated to the player that introduced me to WOW Parkour :-)
}

local function StoreRoundedPlayerPosition()
	local x,y = UnitPosition("player")
	parkour_x = math.floor((tonumber(x) * 10) + 0.5)/10		-- Round to first decimal
	parkour_y = math.floor((tonumber(y) * 10) + 0.5)/10		-- Round to first decimal
end

local function UpdateParkourPoints()

	if Hardcore_Character == nil then
		return 0
	end
	if Hardcore_Character.parkour == nil then
		return 0
	end

	local points = 0
	for k, v in pairs( Hardcore_Character.parkour ) do
		if parkour_id_names[ k ] ~= nil then
			points = points + v.points
		end
	end
	_achievement.title = "Parkour (" .. points .. ")"
	return points
end


-- UpdateParkourAchievement
--
-- Stores the current achievement, recounts the number of places and updates the achievement title

local function UpdateParkourAchievement( parkour_id )

	-- Fool proofing
	if Hardcore_Character == nil then
		return
	end

	-- Generate the Parkour data field, if it doesn't exist yet
	if Hardcore_Character.parkour == nil then
		Hardcore_Character.parkour = {}
	end

	-- Check if the parkour_id is still recognised
	if parkour_id_names[ parkour_id ] == nil then
		Hardcore:Debug("Parkour: unknown parkour_id " .. parkour_id)
		return
	end

	-- Check if we had that ID already, then the printed message will be different
	local again
	if Hardcore_Character.parkour[ parkour_id ] ~= nil then
		again = " (again)"
	else
		again = ""
	end

	-- Add or replace the existing parkour spot
	local PARKOUR_DATA = {}
	--PARKOUR_DATA.id = parkour_id
	PARKOUR_DATA.points = 1								-- How many parkour level points for this place
	PARKOUR_DATA.coords = { parkour_x, parkour_y }		-- Store this for later, in case something changes
	PARKOUR_DATA.map_id = parkour_map_id				-- Store this for later, in case something changes
	PARKOUR_DATA.date = date("%m/%d/%y")
	Hardcore_Character.parkour[ parkour_id ] = PARKOUR_DATA

	-- Now update the points (and the title)
	local points = UpdateParkourPoints()

	-- Print congratulation message
	Hardcore:Print( "You have reached " .. parkour_id_names[ parkour_id ] .. again )
	Hardcore:Print( "You currently have " .. points .. " Parkour points")

	-- Call the general succeed function to log it in the achievement system
	_achievement.succeed_function_executor.Succeed(_achievement.name)

	return
end


local function IsPointWithinTriangle( x, y, x1, y1, x2, y2, x3, y3)

	-- Calculate coords with respect to vertices
	local dx1, dy1, dx2, dy2, dx3, dy3
	dx1 = x - x1
	dy1 = y - y1
	dx2 = x - x2
	dy2 = y - y2
	dx3 = x - x3
	dy3 = y - y3

	-- Calculate normal vectors to the edges starting at the three vertices and going clockwise to the next
	local nx1, ny1, nx2, ny2, nx3, ny3
	nx1 = y2 - y1
	ny1 = -(x2 - x1)
	nx2 = y3 - y2
	ny2 = -(x3 - x2)
	nx3 = y1 - y3
	ny3 = -(x1 - x3)

	-- Calculate inner products, should all be positive for points inside the triangle
	local ip1, ip2, ip3
	ip1 = dx1 * nx1 + dy1 * ny1
	ip2 = dx2 * nx2 + dy2 * ny2
	ip3 = dx3 * nx3 + dy3 * ny3

	if ip1 >= 0 and ip2 >= 0 and ip3 >= 0 then
		return true
	end
	return false
end

local function OnOrgrimmarBankLedge()
	if IsPointWithinTriangle( parkour_x, parkour_y, 1614.8, -4384.7, 1616.4, -4388.4, 1613.8, -4386.0 ) then
		return true
	end
	return false
end

-- TODO TODO : Fill this with the coords from Keanu / Krueger
local function OnOrgrimmarBankLedgeTwo()
	if IsPointWithinTriangle( parkour_x, parkour_y, 1610.1, -4373.3, 1611.1, -4376.1, 1610.9, -4377.4 ) then
		return true
	end
	return false
end

local function OnOrgrimmarAuctionHouseLedge()
	if IsPointWithinTriangle( parkour_x, parkour_y, 1671.5, -4429.7, 1671.6, -4428.4, 1675.8, -4427.6 ) then
		return true
	end
	return false
end

-- RegisterSpellEventHandlers()
--
-- Registers the spell handlers for the First Aid range check
-- We only do this after a /flex in the right spot, for performance reasons

local function RegisterSpellEventHandlers()

	_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")			-- Can't get target reliably from this
	_achievement:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

end

---------------------------------
---- GLOBAL FUNCTIONS
---------------------------------


-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement.succeed_function_executor = succeed_function_executor
	_achievement:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
	UpdateParkourPoints()

	-- We don't do the registers for spellcast_succeeded and combat_log here, for performance reasons
	-- They get activated by a flex, until the next reload / logout. 
end

function _achievement:Unregister()
	_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	_achievement:UnregisterEvent("CHAT_MSG_TEXT_EMOTE")
	_achievement:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end


-- Event handling
_achievement:SetScript("OnEvent", function(self, event, ...)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, spell_id = ...
		if unit ~= "player" then
			return
		end
		-- Store the name of the first aid spell in the local language
		if spell_id == 746 or spell_id == 1159 or spell_id == 3267 or spell_id == 3268 or
			spell_id == 7926 or spell_id == 7927 or spell_id == 10838 or spell_id == 10839 or
			spell_id == 18608 or spell_id == 23696 then
			first_aid_name = GetSpellInfo(spell_id)
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, subevent, _, source_guid, _, _, _,	dest_guid, _, _, _,	_, spell_name, _ = CombatLogGetCurrentEventInfo()
		if subevent == "SPELL_CAST_SUCCESS" then
			-- Check if it was a bandage
			if spell_name == first_aid_name then
				-- Check if we are in the Orgrimmar bank ledge and the target is Rokhstrom
				-- Check if it was the player who cast the bandage
				if source_guid ~= UnitGUID("player") then
					return
				end
				-- Check if it was Rokhstrom that got bandaged
				local target_type, _, _, map_id, _, target_type_id = string.split("-", dest_guid)
				map_id = tonumber( map_id )
				target_type_id = tonumber( target_type_id )
				if target_type ~= "Creature" or map_id ~= 1 or target_type_id ~= 13842 then
					return
				end

				-- Check if the coordinates are correct
				StoreRoundedPlayerPosition()
				if OnOrgrimmarBankLedge() == true then
					UpdateParkourAchievement("ORGB1")
				elseif OnOrgrimmarBankLedgeTwo() == true then
					UpdateParkourAchievement("ORGB2")
				end
			end
		end
	elseif event == "CHAT_MSG_TEXT_EMOTE" then			-- 
		_, _, _, _, _, _, _, _, _, _, _, guid = ...
		if guid == nil or guid ~= UnitGUID("player") then
			return
		end
		if IsInInstance() == false then
			local mapID = C_Map.GetBestMapForUnit("player")
			if mapID == 1454 then						-- Orgrimmar
				StoreRoundedPlayerPosition()
				parkour_map_id = mapID
				if OnOrgrimmarBankLedge() then
					Hardcore:Print( "You are at " .. parkour_id_names[ "ORGB1" ] .. ", bandage Ambassador Rokhstrom from here for the Parkour achievement" )
					RegisterSpellEventHandlers()
				elseif OnOrgrimmarBankLedgeTwo() then
					Hardcore:Print( "You are at " .. parkour_id_names[ "ORGB2" ] .. ", bandage Ambassador Rokhstrom from here for the Parkour achievement" )
					RegisterSpellEventHandlers()
				elseif OnOrgrimmarAuctionHouseLedge() then
					UpdateParkourAchievement("ORGAH")
				end
			end
		end
		return
	end
end)
