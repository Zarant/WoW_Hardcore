local _G = _G
local no_hit_achievement = CreateFrame("Frame")
_G.achievements.NoHit = no_hit_achievement

-- General info
no_hit_achievement.name = "NoHit"
no_hit_achievement.title = "Stadics' Challenge"
no_hit_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_no_hit.blp"
no_hit_achievement.pts = 50
no_hit_achievement.description =
	"Complete the hardcore challenge without taking a point of damage.  Falling, drowning, fatigue and other such sources that count as “Environmental Damage” according to the Combat Log are, as such, Damage. This also means that spells that expend life as a resource, such as the Warlock’s Life Tap, do not cause any 'damage' and are as such perfectly viable.  Futhermore, you must accumulate over 45,000 reputation across the four main factions."
no_hit_achievement.class = "All"
no_hit_achievement.alert_on_fail = 1

local faction_indices = { 2, 3, 4, 5 }

local faction_ids_horde = { 68, 76, 81, 530}
local faction_ids_alliance = { 47, 54, 69, 72}

local starting_rep = {
	["Gnome"] = 13300,
	["Human"] = 13300,
	["Night Elf"] = 13300,
	["Dwarf"] = 13300,
	["Undead"] = 5500,
	["Tauren"] = 10700,
	["Orc"] = 10700,
	["Troll"] = 10700,
	["Blood Elf"] = 500 + 500 + 500 + 3100,
	["Goblin"] = 3100 + 3100 + 3100 + 500,
	["Draenei"] = 3100 + 3100 + 3100 + 3100,
	["Worgen"] = 3100 + 3100 + 3100 + 3100
}

function no_hit_achievement:UpdateDescription()
	no_hit_achievement.description =
		"Complete the hardcore challenge without taking a point of damage.  Falling, drowning, fatigue and other such sources that count as “Environmental Damage” according to the Combat Log are, as such, Damage. This also means that spells that expend life as a resource, such as the Warlock’s Life Tap, do not cause any 'damage' and are as such perfectly viable.  Futhermore, you must accumulate over 45,000 reputation across the four main factions."
	local total_earned_value = 0
	local faction_ids
	local player_faction_group, _ = UnitFactionGroup( "player")
	if player_faction_group == "Horde" then
		faction_ids = faction_ids_horde
	elseif player_faction_group == "Alliance" then
		faction_ids = faction_ids_alliance
	else
		faction_ids = {}
		Hardcore:Print( "Warning: player's faction is unexpected")
	end
	for _, idx in ipairs(faction_ids) do
		local name, description, standingId, bottomValue, topValue, earnedValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild =
			GetFactionInfoByID(idx)
		total_earned_value = total_earned_value + earnedValue
	end
	if starting_rep[UnitRace("player")] == nil then
		total_earned_value = total_earned_value - starting_rep["Human"]
		Hardcore:Print( "Warning: no starting reputation for race " .. UnitRace("player"))
	else
		total_earned_value = total_earned_value - starting_rep[UnitRace("player")]
	end
	if total_earned_value > 45000 then
		no_hit_achievement.description = no_hit_achievement.description .. "\n|c0000FF00Progress: Complete!|r"
	else
		no_hit_achievement.description = no_hit_achievement.description
			.. "\n|c00FFFF00Progress: "
			.. total_earned_value
			.. "/45,000|r"
	end
end

-- Registers
function no_hit_achievement:Register(fail_function_executor)
	no_hit_achievement:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	no_hit_achievement.fail_function_executor = fail_function_executor
	no_hit_achievement:UpdateDescription()
end

function no_hit_achievement:Unregister()
	no_hit_achievement:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Register Definitions
no_hit_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local combat_log_payload = { CombatLogGetCurrentEventInfo() }
		-- 2: subevent index, 8: dest_guid, 15: amount
		if not (combat_log_payload[8] == nil) then
			if combat_log_payload[8] == UnitGUID("player") then
				if string.find(combat_log_payload[2], "ENVIRONMENTAL_DAMAGE") ~= nil then
					-- 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane
					if combat_log_payload[13] > 0 then
						print("Failing Stadics' Challenge, took " .. combat_log_payload[13] .. " environmental damage")
						no_hit_achievement.fail_function_executor.Fail(no_hit_achievement.name)
					end
				elseif string.find(combat_log_payload[2], "SWING_DAMAGE") ~= nil then
					-- 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane
					if combat_log_payload[12] > 0 then
						print("Failing Stadics' Challenge, took " .. combat_log_payload[12] .. " swing damage")
						no_hit_achievement.fail_function_executor.Fail(no_hit_achievement.name)
					end
				elseif string.find(combat_log_payload[2], "_DAMAGE") ~= nil then
					-- 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane
					if combat_log_payload[15] > 0 then
						print("Failing Stadics' Challenge, took " .. combat_log_payload[15] .. " cast damage")
						no_hit_achievement.fail_function_executor.Fail(no_hit_achievement.name)
					end
				end
			end
		end
	end
end)
