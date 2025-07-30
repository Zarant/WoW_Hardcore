-- Dungeons.lua
-- Dungeon tracking functionality for WOW Classic Hardcore Addon
-- Written by Frank de Jong

-- Definitions
local DT_WARN_INTERVAL = 10 					-- Warn every 10 seconds about repeated run (while in dungeon)
local DT_INSIDE_MAX_TIME = 60 					-- Maximum time inside a dungeon without it being logged
local DT_INSIDE_MAX_TIME_NO_KILLS = 450			-- Maximum time inside a dungeon without it being logged if there are no kills
local DT_OUTSIDE_MAX_REAL_TIME = 1800 			-- If seen outside, how many seconds since last seen inside before finalization (1800 = 30m)
local DT_OUTSIDE_MAX_RUN_TIME = 21600 			-- If seen outside, how many seconds since start of run before finalization (21600 = 6 hrs)
local DT_TIME_STEP = 1 							-- Dungeon code called every 1 second
local DT_GROUP_PULSE = 30 						-- Send group pulse every 30 seconds
local DT_VERSION = 4 							-- Increasing this will trigger a full rebuild of the dungeon tracker info

-- Some local variables defined in Hardcore.lua -- Make sure these are the same as in Hardcore.lua!!
local CTL = _G.ChatThrottleLib
local COMM_NAME = "HardcoreAddon" 				-- Overwritten in DungeonTrackerInitiate()
local COMM_COMMAND_DELIM = "$" 					-- Overwritten in DungeonTrackerInitiate()
local COMM_FIELD_DELIM = "|" 					-- Overwritten in DungeonTrackerInitiate()
local DT_PULSE_COMMAND = "DTPULSE" 				-- Overwritten in DungeonTrackerInitiate()

local combat_log_frame = nil

local dt_checked_for_missing_runs = false		-- Did we check for missing runs in this session already?

local dt_party_member_addon_version = {}
local dt_party_member_verif_status = {}

local dt_player_level = 0

local dt_db_id_to_name = nil
local dt_db_max_levels = nil
local dt_db_name_to_index = nil			-- Gives index in the database of the dungeon with given name

-- DungeonTrackerInitializeHashes()
--
-- Compiles the lookup tables dt_db_* for faster lookup of specific dungeons

local function DungeonTrackerInitializeHashes()

	-- Hash from MapID to dungeon name
	if dt_db_id_to_name == nil then
		dt_db_id_to_name = {}
		for i, v in ipairs(dt_db) do
			dt_db_id_to_name[v[1]] = v[3]
		end
	end
	
	-- Hash from name to max level
	if dt_db_max_levels == nil then
		dt_db_max_levels = {}
		for i, v in ipairs(dt_db) do
			if v[7] ~= nil then
				dt_db_max_levels[v[3]] = v[7]
			else
				dt_db_max_levels[v[3]] = { 1000, 1000 }
			end
		end
	end
	
	-- Hash from name to index in the database
	if dt_db_name_to_index == nil then
		dt_db_name_to_index = {}
		for i, v in ipairs(dt_db) do
			dt_db_name_to_index[v[3]] = i
		end
	end
	
end

-- DungeonTrackerGetDungeonName( id )
--
-- Needed to get around regionalised names. We want everything in English, yo!

local function DungeonTrackerGetDungeonName(id)

	if dt_db_id_to_name == nil or dt_db_id_to_name[id] == nil then
		return "Unknown"
	end

	return dt_db_id_to_name[id]
end

-- DungeonTrackerGetDungeonMaxLevel
--
-- Returns the max level for a dungeon from the database above, or 1000 if not known

local function DungeonTrackerGetDungeonMaxLevel(name)
	local max_level = 1000 -- Default: if we can't find it, or game version not set: it doesn't have a max level

	if dt_db_max_levels ~= nil and dt_db_max_levels[name] ~= nil then
		if Hardcore_Character.game_version ~= nil and _G.HC_CONSTANTS and _G.HC_CONSTANTS.DB_LEVEL_INDEX then
			local index = _G.HC_CONSTANTS.DB_LEVEL_INDEX
			if dt_db_max_levels[name] and dt_db_max_levels[name][index] then
				max_level = dt_db_max_levels[name][index]
			end
		end
	end

	return max_level
end

-- DungeonTrackerGetDungeonMaxLevelAtRunTime
--
-- Returns the max level for a dungeon from the database at the specified run time
-- This is used to see if previous runs may have been under another version of the
-- game where the max levels were different

local function DungeonTrackerGetDungeonMaxLevelAtRunTime(run)
    -- This logic is for a past event. For MoP and future versions,
    -- simply return the current max level.
    return DungeonTrackerGetDungeonMaxLevel(run.name)
end

-- DungeonTrackerGetAllDungeonMaxLevels()
--
-- Returns a table of dungeons and associated max levels
-- (only dungeons, not raids, not battle grounds)
-- Mostly for use in the Rules tab (so not local), called from Mainmenu.lua

function DungeonTrackerGetAllDungeonMaxLevels()
	local the_table = {}
	local game_version = Hardcore_Character.game_version
	-- Use the constant for the database level index, which is correctly set to 3 for MoP
	local level_index = _G.HC_CONSTANTS and _G.HC_CONSTANTS.DB_LEVEL_INDEX or 2

	for i, v in pairs(dt_db) do
		-- Only show entries that are dungeons
		if v[4] == "D" then
			local name = v[3]
			local era_level = v[7][1]
			-- This now correctly gets the level from the MoP slot (index 3)
			-- It no longer falls back to index 2 if the MoP level is nil
			local current_level = v[7][level_index]

			-- If a level is not defined or is set to 1000 (meaning no cap), display it as "--"
			if era_level == 1000 or era_level == nil then
				era_level = "--"
			end
			if current_level == 1000 or current_level == nil then
				current_level = "--"
			end

			table.insert(the_table, { name, era_level, current_level })
		end
	end

	return the_table
end

-- DungeonTrackerHasRun( name )
--
-- Returns true if a dungeon with the given name was found in any of .runs[], .pending[] or .current,
-- or false otherwise

local function DungeonTrackerHasRun( name )

	if Hardcore_Character.dt.runs ~= nil then
		for i, v in ipairs(Hardcore_Character.dt.runs) do
			if v.name == name then
				return true
			end
		end
	end
	
	if Hardcore_Character.dt.pending ~= nil then
		for i, v in ipairs(Hardcore_Character.dt.pending) do
			if v.name == name then
				return true
			end
		end
	end
	
	if Hardcore_Character.dt.current ~= nil then
		if Hardcore_Character.dt.current.name == name then
			return true
		end
	end
	
	return false

end



-- DungeonTrackerFindMissingRunsFromQuests()
--
-- Finds any dungeons that have the flagging quests, but do not have an associated run
-- (for whatever reason, such as weird update problems).

local function DungeonTrackerFindMissingRunsFromQuests()

	local game_version_index = 1
	local game_version_max_level = 60

	-- Double check inputs
	if Hardcore_Character.dt == nil or Hardcore_Character.dt.runs == nil then
		return
	end

	-- For Era/SoM, we only look at the quests for dungeons with a max level of 60
	if Hardcore_Character.game_version == "Era" or Hardcore_Character.game_version == "SoM" then
		game_version_index = 1
		game_version_max_level = 60
	elseif Hardcore_Character.game_version == "WotLK" or Hardcore_Character.game_version == "Cata" then
		game_version_index = 2
		game_version_max_level = 80
	else
		return
	end

	-- Go through the list and log a run for each dungeon for which one or more quests are flagged as completed
	for i, v in pairs(dt_db) do
		local dungeon_done = false
		local quests = v[8]
		local name = v[3]
		local map_id = v[1]
		local max_levels = v[7]
		
		if (quests ~= nil) and (max_levels ~= nil) and (max_levels[game_version_index] <= game_version_max_level) and (DungeonTrackerHasRun( name ) == false) then
			local j, quest_num
			for j = 1, #quests do
				if C_QuestLog.IsQuestFlaggedCompleted(quests[j]) then
					Hardcore:Debug("Found legacy quest " .. quests[j])
					dungeon_done = true
					quest_num = quests[j]
					break
				end
			end
			if dungeon_done == true then
				DUNGEON_RUN = {}
				DUNGEON_RUN.name = name
				DUNGEON_RUN.id = map_id
				DUNGEON_RUN.date = "(legacy)"
				DUNGEON_RUN.time_inside = 0
				DUNGEON_RUN.level = 0
				DUNGEON_RUN.quest_id = quest_num
				Hardcore:Debug("Logging missing run in " .. DUNGEON_RUN.name)
				table.insert(Hardcore_Character.dt.runs, DUNGEON_RUN)
			end
		end
	end
end

local function DungeonTrackerIsRepeatedRun(run1, run2)
	-- If one of the runs is for an unknown SM wing, we don't count this as repeated
	if run1.name == "Scarlet Monastery" or run2.name == "Scarlet Monastery" then
		return false
	end

	-- Most common case is where everything is in English; then the names should be the same
	if run1.name == run2.name then
		return true
	end

	-- Handle exceptional case for Scarlet Monastery -- there, the instanceMapID will be the same for different wings,
	-- but there is no repeated run if you do them both. The "true" must have come from the run name comparison above.
	if run1.id ~= nil and run1.id == 189 then
		return false
	end

	-- Handle more exotic cases where some of the names of the logged runs are in another language (backward compatibility)
	-- or there was somehow an update in the dungeon database which caused a small change in the name
	if run1.id ~= nil and run2.id ~= nil and run1.id == run2.id then
		return true
	end

	-- Player-friendly: we can't figure it out, so we assume it's good
	return false
end

-- DungeonTrackerAnyRunNamesRepeated()
--
-- Efficiency function for checking all logged runs to each other.
-- For N runs, N(N-1)/2 checks are necessary if you want to compare all to all.
-- This function simply checks if any of the names occurs more than once; this is Order(N).

local function DungeonTrackerAnyRunNamesRepeated()

	if Hardcore_Character.dt.runs == nil then
		return false
	end
	local names_table = {}
	for i, v in ipairs(Hardcore_Character.dt.runs) do
		if v.name ~= nil and v.name ~= "" then
			if names_table[ v.name ] ~= nil then
				return true
			end
			names_table[ v.name ] = 1
		end
	end
	return false
end

-- DungeonTrackerUpdateInfractions()
--
-- Updates the dt.overleveled_runs and dt.repeated_runs variables
-- from the list of finalized runs. This can be called after a Mod command to
-- recalculate the infraction statistics

local function DungeonTrackerUpdateInfractions()
	local repeated = 0
	local over_leveled = 0

	for i = 1, #Hardcore_Character.dt.runs do
		-- Check overleveled run
		if Hardcore_Character.dt.runs[i].level > DungeonTrackerGetDungeonMaxLevelAtRunTime(Hardcore_Character.dt.runs[i]) then
			over_leveled = over_leveled + 1
		end
		-- Check if the run is repeated further down in the array (this prevents counting runs twice when i ends up at j)
		for j = i + 1, #Hardcore_Character.dt.runs do
			if DungeonTrackerIsRepeatedRun(Hardcore_Character.dt.runs[i], Hardcore_Character.dt.runs[j]) then
				repeated = repeated + 1
			end
		end
	end

	Hardcore_Character.dt.overleveled_runs = over_leveled
	Hardcore_Character.dt.repeated_runs = repeated
end

local function DungeonTrackerWarnInfraction()

	local message
	local chat_color = "\124cffFF0000"

	-- We only warn if there is still chance to get out in time
	local time_left = DT_INSIDE_MAX_TIME_NO_KILLS - Hardcore_Character.dt.current.time_inside
	if time_left <= 0 then
		return
	end

	-- Don't warn too frequently
	if (Hardcore_Character.dt.current.last_warn ~= nil) and (Hardcore_Character.dt.current.time_inside - Hardcore_Character.dt.current.last_warn < DT_WARN_INTERVAL) then
		return
	end

	-- Don't warn in the first few seconds of an unidentified SM wing. The time_left will be shorter after
	-- a reconnect to an existing wing run, so then that first warning of 60s would be confusing
	if (Hardcore_Character.dt.current.name == "Scarlet Monastery") and (time_left > 50) then
		return
	end

	-- Don't warn at max level (they can do whatever dungeon then) or when the user turned warnings off
	-- /run Hardcore_Character.dt.warn_infractions=false
	if Hardcore_Character.dt.warn_infractions == false then
		return
	end

	-- Get max level to know if we should even warn
	if _G.HC_CONSTANTS and _G.HC_CONSTANTS.MAX_LEVEL then
		if UnitLevel("player") >= _G.HC_CONSTANTS.MAX_LEVEL then
			Hardcore_Character.dt.warn_infractions = false
			return
		end
	end

	-- See if the player's level is allowed in this dungeon
	local max_level = DungeonTrackerGetDungeonMaxLevel(Hardcore_Character.dt.current.name)
	if Hardcore_Character.dt.current.level > max_level then
		Hardcore_Character.dt.current.last_warn = Hardcore_Character.dt.current.time_inside
		message = "You are overleveled for " .. Hardcore_Character.dt.current.name .. ". Leave dungeon now!"
		Hardcore:Print(chat_color .. message)
		Hardcore:ShowRedAlertFrame( message )
	end

	-- See if this dungeon was already in the list of completed runs, and warn every so many seconds if that is so
	for i, v in ipairs(Hardcore_Character.dt.runs) do
		if DungeonTrackerIsRepeatedRun(v, Hardcore_Character.dt.current) then
			Hardcore_Character.dt.current.last_warn = Hardcore_Character.dt.current.time_inside
			local instance_info1 = ""
			local instance_info2 = ""
			if v.iid ~= nil and Hardcore_Character.dt.current.iid ~= nil and v.iid ~= Hardcore_Character.dt.current.iid then
				instance_info1 = " (ID:" .. Hardcore_Character.dt.current.iid .. ")"
				instance_info2 = " (ID:" .. v.iid .. ")"
			end
			message = "You entered " .. v.name .. instance_info1 .. " already on " .. v.date .. instance_info2	
					.. ". Leave dungeon now!"
			Hardcore:Print( chat_color .. message)
			Hardcore:ShowRedAlertFrame( message )
			break -- No need to warn about 3rd and higher entries
		end
	end

	-- The following code probably can't ever be called, since pending runs with different instance IDs are automatically
	-- logged upon entry. But let's keep it here for now. Better warned twice, than never.
	-- See if this dungeon was already in the list of pending runs (but with a different instanceID), and warn every so many seconds if that is so
	for i, v in ipairs(Hardcore_Character.dt.pending) do
		-- We never warn about pending runs without an instanceID, they may or may not be the same as the current
		-- (However, such pending runs should not exist, as they are deleted immediately when you exit the dungeon)
		-- It is not possible for the IIDs to be the same at this point, as they would have been merged already
		if v.iid ~= nil and Hardcore_Character.dt.current.iid ~= nil then
			if DungeonTrackerIsRepeatedRun(v, Hardcore_Character.dt.current) then
				Hardcore_Character.dt.current.last_warn = Hardcore_Character.dt.current.time_inside
				message = "Your idle run of " .. v.name .. " of date ".. v.date .. " has another instance ID"
					.. ". Leave dungeon now!"
				Hardcore:Print( chat_color .. message )
				Hardcore:ShowRedAlertFrame( message )
				break -- No need to warn about 3rd and higher entries
			end
		end
	end

end

local function DungeonTrackerLogRun(run)

	-- We don't log this run if the inside time is too small
	if run.time_inside < DT_INSIDE_MAX_TIME then
		Hardcore:Debug("Not logging short run in " .. run.name)
		return
	end

	-- We don't log this run if no instance ID was found (indicating that no mobs were attacked)
	if run.iid == nil then
		Hardcore:Debug("Not logging run without instanceID in " .. run.name)
		return
	end

	-- We don't log this run if it's relatively short, there is an instance ID (checked above), but no kills
	if run.num_kills ~= nil and run.num_kills == 0 and run.time_inside < (DT_INSIDE_MAX_TIME_NO_KILLS) then
		Hardcore:Debug("Not logging short run without kills in " .. run.name)
		return
	end

	-- Warn if this is a repeated run and log
	for i, v in ipairs(Hardcore_Character.dt.runs) do
		if DungeonTrackerIsRepeatedRun(v, run) then
			local instance_info = ""
			if v.iid ~= nil then
				instance_info = " (ID:" .. v.iid ..  ")"
			end
			if Hardcore_Character.dt.warn_infractions == true then
				Hardcore:Print(
					"\124cffFF0000You entered "
						.. run.name .. " (ID:" .. run.iid .. ")"
						.. " already on "
						.. v.date .. instance_info
						.. " -- logging repeated run"
				)
			end
			break
		end
	end

	-- Warn if this is an overleveled run and log
	local max_level = DungeonTrackerGetDungeonMaxLevel(run.name)
	if run.level > max_level then
		if Hardcore_Character.dt.warn_infractions == true then
			Hardcore:Print("\124cffFF0000You were overleveled for " .. run.name .. " -- logging overleveled run")
		end
	end

	-- Now actually log the run
	Hardcore:Debug("Logging run in " .. run.name)
	table.insert(Hardcore_Character.dt.runs, run)

	-- Update infraction statistics (involves a re-count)
	DungeonTrackerUpdateInfractions()
end

-- DungeonTrackerUpdateEntryCount()
--
-- Keeps count of how often each dungeon has been entered
-- (= 1 + number of reconnects)

local function DungeonTrackerUpdateEntryCount()

	local name = Hardcore_Character.dt.current.name
	if name == nil then
		return
	end

	-- Create the count if we don't have it already
	if Hardcore_Character.dt.current.num_entries == nil then
		Hardcore_Character.dt.current.num_entries = 0
	end

	-- Update or create the entry for this dungeon
	Hardcore_Character.dt.current.num_entries = Hardcore_Character.dt.current.num_entries + 1

end

-- DungeonTrackerIdentifyScarletMonasteryWing( map_id, mob_type_id )
--
-- Finds the SM wing in which a certain mob_type_id is found. Only works for unique mob_ids,
-- so not for mobs that appear in more than one wing.

local function DungeonTrackerIdentifyScarletMonasteryWing( map_id, mob_type_id )

	local SM = "Scarlet Monastery"

	-- If this is SM (=189), and we don't know the wing yet, we try to find it
	if map_id == 189 and Hardcore_Character.dt.current.name == SM then

		local wing_spawns = {
			{4293, "Scarlet Scryer", "GY"},
			{4306, "Scarlet Torturer", "GY"},
			{4287, "Scarlet Gallant", "Lib"},
			{4296, "Scarlet Adept", "Lib"},
			{4286, "Scarlet Soldier", "Arm"},
			{4297, "Scarlet Conjuror", "Arm"},
			{4298, "Scarlet Defender", "Cath"},
			-- One more round of deeper-in mobs
			{6427, "Haunting Phantasm", "GY"},
			{4288, "Scarlet Beastmaster", "Lib"},
			{4291, "Scarlet Diviner", "Lib"},
			{4289, "Scarlet Evoker", "Arm"},
			{4294, "Scarlet Sorceror", "Cath"},
			-- Bosses as a last resort
			{3983, "Interrogator Vishas", "GY"},
			{6490, "Azshir the Sleepless", "GY"},
			{6488, "Fallen Champion", "GY"},
			{6489, "Ironspine", "GY"},
			{3974, "Houndmaster Loksey", "Lib"},
			{6487, "Arcanist Doan", "Lib"},
			{3975, "Herod", "Arm"},
			{3976, "Scarlet Commander Mograine", "Cath"},
			{3977, "High Inquisitor Whitemane", "Cath"},
			{4542, "High Inquisitor Fairbanks", "Cath"},
		}

		-- See if any of the listed mobs is recognised
		for i, v in ipairs( wing_spawns ) do
			if mob_type_id == v[1] then
				Hardcore_Character.dt.current.name = SM .. " (" .. v[3] .. ")"
				Hardcore:Debug( "Identified SM wing " .. v[3] .. " from " .. v[2] )
				return
			end
		end
	end

	-- If not SM, or wing already known, or wing not found, we do nothing

end

-- DungeonTrackerCheckChanged(name)
--
-- Handles changes of dungeon (to do "emergency" logging or current run)
-- Also adapts the SM dungeon name to include the wing, if we know it

local function DungeonTrackerCheckChanged(name)

	-- If there is no current, there is no change
	if not next(Hardcore_Character.dt.current) then
		return name
	end

	local SM = "Scarlet Monastery"

	-- If this is Scarlet Monastery (any wing), we need to check if the wing changed
	if name == SM then
		-- If we don't know which wing we are in, try to identify any of the dungeon wing's mobs
		if Hardcore_Character.dt.current.name ~= SM then
			-- We already know our wing -- just copy over what we already had
			name = Hardcore_Character.dt.current.name
		end

		-- At this point, either dt.current.name is "SM", or it is "SM (Wing)".
		-- If it's "SM", the name can only be "SM", too. This happens if no door spawn was found yet.
		-- If it's "SM (Wing)", then "name" has a wing too, which is either the same or different
	end

	-- Now check if the name changed (whether it's SM or RFC or whatever)
	-- This should normally not happen, as once we're outside, the current dungeon is queued
	-- But it could happen if people disable the addon inside a dungeon, and re-enable it in another
	if Hardcore_Character.dt.current.name ~= name then
		-- Change to the new dungeon, but we store only if we spent enough time
		Hardcore:Print("Left dungeon " .. Hardcore_Character.dt.current.name .. " for dungeon " .. name)
		DungeonTrackerLogRun(Hardcore_Character.dt.current)
		Hardcore_Character.dt.current = {}
	end

	return name
end

-- DungeonTrackerAddToParty( run, name )
--
-- Adds the name to the party, if it's not already there

local function DungeonTrackerAddToParty( run, name )

	-- Easy if there is no party yet
	if run.party == nil or run.party == "" then
		run.party = name
		return
	end

	-- If there is at least one name already, let's make sure the new name is not there already
	-- Can't use string.find, because that will bork if you have "Leet" and "Leethc"
	local found = false
	local names = { string.split(",", run.party ) }
	for i, v in ipairs( names ) do
		if v == name then
			return					-- Already there, done!
		end
	end
	run.party = run.party .. "," .. name

end

-- DungeonTrackerReceivePulse( data, sender )
--
-- Receives a group pulse, storing the time in the message and the sender in the associated pending run
-- Not a local function, called from Hardcore.lua

function DungeonTrackerReceivePulse(data, sender)
	local short_name
	local version
	local ping_time
	local dungeon_name
	local dungeon_id
	local iid
	local status

	short_name, version, ping_time, dungeon_name, dungeon_id, iid, status = string.split(COMM_FIELD_DELIM, data)
	-- Handle malformed pulse that breaks the script
	if short_name == nil or version == nil or ping_time == nil or dungeon_name == nil or dungeon_id == nil then
		return
	end
	dungeon_id = tonumber(dungeon_id)
	-- Old version of the pulse does not have instance ID, so set it to 0
	if iid == nil then
		iid = 0
	else
		iid = tonumber(iid)
	end	
	ping_time = tonumber(ping_time)
	-- Versions <= 0.11.22 do not have status
	if status == nil then
		status = "?"
	end

	Hardcore:Debug(
		"Received dungeon group pulse from "
			.. sender
			.. ", data = "
			.. short_name
			.. ", "
			.. version
			.. ", "
			.. ping_time
			.. ", "
			.. dungeon_name
			.. ", "
			.. iid
			.. ", "
			.. status
	)

	-- Save the addon version and verification status for this player
	dt_party_member_addon_version[ short_name ] = version
	dt_party_member_verif_status[ short_name ] = status

	-- Check for errors, dt might not be set right now (if it just got reset for some weird reason)
	if (Hardcore_Character.dt == nil) or (not next(Hardcore_Character.dt)) or (not next(Hardcore_Character.dt.pending)) then
		return
	end

	-- Update the latest ping time in the idle runs only (no need to do it in current run)
	for i, v in pairs(Hardcore_Character.dt.pending) do

		-- We only update the pulse time if the instanceIDs from pending and party member aren't known, or when they are the same
		if v.iid == nil or iid == 0 or v.iid == iid then
			local run_name_SM
			-- If we receive a pulse from "Scarlet Monastery" (with or without wing), then we store that 
			-- pulse in all idle SM runs because they all share a single instance ID that is still alive
			run_name_SM = string.sub(dungeon_name, 1, 17)

			-- If this is the run from which the ping originated, and the ping time is later than we already have, store it
			if v.name == dungeon_name or run_name_SM == "Scarlet Monastery" then
				if ping_time > v.last_seen then
					v.last_seen = ping_time
				end

				-- Add the ping sender to the party members, if not already there
				DungeonTrackerAddToParty(v, short_name)
			end
		end
	end
end

-- DungeonTrackerSendPulse( now )
--
-- Sends a group pulse, if the time out is expired

local function DungeonTrackerSendPulse(now)

	local my_verif_status

	-- Don't send too many pulses, one every 30 seconds is enough
	if (Hardcore_Character.dt.sent_pulse ~= nil) and (now - Hardcore_Character.dt.sent_pulse < DT_GROUP_PULSE) then
		return
	end
	Hardcore_Character.dt.sent_pulse = now

	-- Generate PASS/FAIL information
	my_verif_status = Hardcore:GetCleanVerificationStatus()

	-- Send my own info to the party (=name + server time + dungeon)
	if CTL then
		local name = UnitName("player")
		local iid = 0
		if Hardcore_Character.dt.current.iid ~= nil then
			iid = Hardcore_Character.dt.current.iid
		end
		local data = name
			.. COMM_FIELD_DELIM
			.. GetAddOnMetadata("Hardcore", "Version")
			.. COMM_FIELD_DELIM
			.. now
			.. COMM_FIELD_DELIM
			.. Hardcore_Character.dt.current.name
			.. COMM_FIELD_DELIM
			.. Hardcore_Character.dt.current.id
			.. COMM_FIELD_DELIM
			.. iid
			.. COMM_FIELD_DELIM
			.. my_verif_status
		local comm_msg = DT_PULSE_COMMAND .. COMM_COMMAND_DELIM .. data
		CTL:SendAddonMessage("NORMAL", COMM_NAME, comm_msg, "PARTY")
		-- Hardcore:Debug("Sending dungeon group pulse: " .. string.gsub( comm_msg, COMM_FIELD_DELIM, "/" ))

		-- Make sure we get our own ping if we are soloing the dungeon -- this can keep other SM wings alive
		if Hardcore_Character.dt.current.party == UnitName("player") then
			DungeonTrackerReceivePulse(data, Hardcore_Character.dt.current.party .. "-SelfPing")
		end

		-- For debug purposes, set this to true to simulate a send from group members
		if false then
			DungeonTrackerReceivePulse(data, UnitName("player") .. "-SelfPing")
			DungeonTrackerReceivePulse("John|0.11.13|1234324|Ragefire Chasm|189", "John-TestServer")
			DungeonTrackerReceivePulse("Jack|0.11.16|1244334|Ragefire Chasm|189|1113", "Jack-TestServer")
			DungeonTrackerReceivePulse("Peter|0.11.23|1244334|Scarlet Monastery|189|1111|FAIL", "Peter-TestServer")
			DungeonTrackerReceivePulse("Jane|0.11.23|1234324|Ragefire Chasm|189|1111|PASS", "Jane-TestServer")
			Hardcore_Character.dt.current.party = UnitName("player") .. ",John,Jack,Peter,Jane"
		end
	end
end


-- DungeonTrackerDatabaseHasBossInfo( name )
--
-- Queries the dungeon database to see if the boss info is set for this dungeon,
-- basically to cover the period in which we gather the boss info
-- returning true or false

local function DungeonTrackerDatabaseHasBossInfo( name )

	if dt_db_name_to_index ~= nil and dt_db_name_to_index[ name ] ~= nil then
		local index = dt_db_name_to_index[ name ]
		local record = dt_db[ index ]
		if record[9] ~= nil then
			return true
		end
	end
	
	-- Error or not found
	return false

end


-- DungeonTrackerIsBoss( name, mob_id )
--
-- Queries the dungeon database to see if the mob_id was a boss,
-- returning true or false

local function DungeonTrackerIsBoss( name, mob_id )

	if dt_db_name_to_index ~= nil and dt_db_name_to_index[ name ] ~= nil then
		local index = dt_db_name_to_index[ name ]
		local record = dt_db[ index ]
		if record[9] ~= nil then
			local boss_list = record[9]
			for i, v in ipairs( boss_list ) do
				if v[2] ~= nil and v[2] == mob_id then
					return true
				end
			end
		end
	end
	
	-- Error or not found
	return false

end


-- DungeonTrackerLogKill( dst_guid, dst_name )
--
-- Logs the killing of specific units

local function DungeonTrackerLogKill( mob_type_id )

	-- Check if it's a boss
	if DungeonTrackerIsBoss( Hardcore_Character.dt.current.name, mob_type_id ) then
		-- Add it to the list of bosses we've killed
		if Hardcore_Character.dt.current.bosses == nil then
			Hardcore_Character.dt.current.bosses = {}
		end
		if Hardcore_Character.dt.current.bosses[ mob_type_id ] == nil then
			Hardcore_Character.dt.current.bosses[ mob_type_id ] = GetServerTime()
		else
			-- This should not happen, so we log it here
			Hardcore:Debug( "Warning -- repeated boss kill ignored" )
			Hardcore_Character.dt.current.repeated_boss_kill = true
		end
	else
		-- Add it to the list of NPCs we've killed
		if Hardcore_Character.dt.current.kills == nil then
			Hardcore_Character.dt.current.kills = {}
		end
		if Hardcore_Character.dt.current.kills[ mob_type_id ] == nil then
			Hardcore_Character.dt.current.kills[ mob_type_id ] = 1
		else
			Hardcore_Character.dt.current.kills[ mob_type_id ] = Hardcore_Character.dt.current.kills[ mob_type_id ] + 1
		end
	end

	-- Add it to the sum total of NPCs we've killed
	if Hardcore_Character.dt.current.num_kills == nil then
		Hardcore_Character.dt.current.num_kills = 0
	end
	Hardcore_Character.dt.current.num_kills = Hardcore_Character.dt.current.num_kills + 1

end

-- DungeonTrackerStoreInstanceID
--
-- Stores the instance ID, but only switches to it from another IID when there is more
-- evidence for that new instance ID than for the old. This is to work around a bug where
-- someone zones out of an instance, but gets a combat log message from the surrounding
-- zone in the <1s before the combatlog callback is unregistered.

local function DungeonTrackerStoreInstanceID( instance_id, event )

	local instance_id_changed = false

	-- Count the number of times we saw this instance ID
	if Hardcore_Character.dt.current.iid_count == nil then
		Hardcore_Character.dt.current.iid_count = {}
	end
	if Hardcore_Character.dt.current.iid_count[instance_id] == nil then
		Hardcore_Character.dt.current.iid_count[instance_id] = 0
	end
	Hardcore_Character.dt.current.iid_count[instance_id] = Hardcore_Character.dt.current.iid_count[instance_id] + 1

	-- If there is no instance ID yet, we store it
	if Hardcore_Character.dt.current.iid == nil then
		Hardcore_Character.dt.current.iid = instance_id
		instance_id_changed = true
	elseif Hardcore_Character.dt.current.iid ~= instance_id then
		-- We already have a different instance ID

		-- Catch exceptional case where an addon update was done during a dungeon run, and the
		-- .iid_count is not set for the current IID. We then start at 1
		if Hardcore_Character.dt.current.iid_count[Hardcore_Character.dt.current.iid] == nil then
			Hardcore_Character.dt.current.iid_count[Hardcore_Character.dt.current.iid] = 1
		end

		-- Only swith to the new one if we saw it more often than the old one
		if Hardcore_Character.dt.current.iid_count[instance_id] > Hardcore_Character.dt.current.iid_count[Hardcore_Character.dt.current.iid] then
			Hardcore_Character.dt.current.iid = instance_id
			instance_id_changed = true
		end
	end

	-- Show a debug message if the stored IID changed
	if instance_id_changed == true then
		Hardcore:Debug( "Found instanceID " .. instance_id .. " from " .. event )
	end
end


-- DungeonTrackerPlayerTargetChangedEventHandler
--
-- Handler for PLAYER_TARGET_CHANGED event, fired when player's target changes
-- This is used inside dungeons to get the instance ID without actually attacking
-- anything

local function DungeonTrackerPlayerTargetChangedEventHandler( self, event )

	-- Make sure we only respond to the combat_log event
	if event ~= "PLAYER_TARGET_CHANGED" then
		return
	end

	-- Bail out right away if we don't have an active run (shouldn't happen, but could)
	if not next( Hardcore_Character.dt.current ) then
		return
	end

	-- Get our data once, so it can't change halfway this function, either.
	local target_guid = UnitGUID("target")
	local target_name = UnitName("target")

	-- Bail out if the target was unset
	if target_guid == nil or target_name == nil then
		return
	end

	-- Hardcore:Debug("Changed to " .. target_name .. ", GUID=" .. target_guid )

	-- Split the GUID
	local target_type, _, server, map_id, instance_id, target_type_id = string.split("-", target_guid)
	if target_type ~= "Creature" then
		return
	end
	map_id = tonumber( map_id )
	instance_id = tonumber( instance_id )
	target_type_id = tonumber( target_type_id )

	-- Do some checks, to eliminate unexpected results
	if map_id ~= Hardcore_Character.dt.current.id then
		Hardcore:Debug( "Warning: Got a target change to an NPC " .. target_name .. " (" .. target_type_id .. ") in wrong dungeon map " .. map_id .. " -- ignoring" )
		return
	end

	-- Store the instanceID (the dynamic one)
	-- To be thread-safe and fast, the reconnecting happens in the main timer routine
	DungeonTrackerStoreInstanceID( instance_id, event )

	-- Pass this mob to the SM wing identifier. This will update dt.current.name if possible. 
	DungeonTrackerIdentifyScarletMonasteryWing( map_id, target_type_id )
end


-- DungeonTrackerCombatLogEventHandler
--
-- Handler for combat events inside the dungeon
-- Retrieves the mapID (fixed for each dungeon), instanceID (dynamic) and NPCID (fixed) from combat events
-- and updates the dungeon log accordingly. 

local function DungeonTrackerCombatLogEventHandler( self, event )

	-- Make sure we only respond to the combat_log event
	if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
		return
	end

	-- Bail out right away if we don't have an active run (shouldn't happen, but could)
	if not next( Hardcore_Character.dt.current ) then
		return
	end

	-- Get the combat log data
	local time_stamp, subevent, _, src_guid, src_name, _, _, dst_guid, dst_name = CombatLogGetCurrentEventInfo()

	-- We don't want to accidentally identify anything from previous runs (SM wings), like dots and debuffs timing out
	if subevent == "SPELL_AURA_REMOVED" or subevent == "SPELL_AURA_REMOVED_DOSE" then
		return
	end

	-- Combat events have a source and a destination (doing and getting the damage). We don't care which one is the NPC.
	-- If it's an NPC, we'll take it.
	local mob_guid = nil
	local mob_name = nil
	if src_guid ~= nil then
		local mob_type = string.split("-", src_guid)
		if mob_type == "Creature" then
			mob_guid = src_guid
			mob_name = src_name
		end
	end
	if mob_guid == nil and dst_guid ~= nil then
		local mob_type = string.split("-", dst_guid)
		if mob_type == "Creature" then
			mob_guid = dst_guid
			mob_name = dst_name
		end
	end

	-- Return immediately if no NPC guid was found
	if mob_guid == nil then
		return
	end

	-- Split the GUID
	local mob_type, _, server, map_id, instance_id, mob_type_id = string.split("-", mob_guid)
	map_id = tonumber( map_id )
	instance_id = tonumber( instance_id )
	mob_type_id = tonumber( mob_type_id )

	-- Do some checks, to eliminate unexpected results
	if map_id ~= Hardcore_Character.dt.current.id then
		Hardcore:Debug( "Error: Got a combat log message witn an NPC " .. mob_name .. " (" .. mob_type_id .. ") in wrong dungeon map " .. map_id .. " -- bailing out!" )
		return
	end

	-- Store the instanceID (the dynamic one)
	-- To be thread-safe and fast, the reconnecting happens in the main timer routine
	DungeonTrackerStoreInstanceID( instance_id, subevent )

	-- Pass this mob to the SM wing identifier. This will update dt.current.name if possible. 
	DungeonTrackerIdentifyScarletMonasteryWing( map_id, mob_type_id )

	-- If this is a kill, log it (including boss kills)
	if subevent == "UNIT_DIED" then
		DungeonTrackerLogKill( mob_type_id )
	end

end

-- DungeonTrackerEventHandler( self, event )
--
-- Main switch board for event handlers for COMBAT_LOG_EVENT_UNFILTERED and PLAYER_TARGET_CHANGED

local function DungeonTrackerEventHandler( self, event )

	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		return DungeonTrackerCombatLogEventHandler( self, event )
	elseif event == "PLAYER_TARGET_CHANGED" then
		return DungeonTrackerPlayerTargetChangedEventHandler( self, event )
	end
	return
end


-- DungeonTrackerGetBossKillDataForRun( run )
--
-- Called from MainMenu.lua to populate the dungeon log (boss column)

function DungeonTrackerGetBossKillDataForRun( run )

	local main_boss = nil
	local main_boss_time = 0
	local num_bosses = 0
	local max_bosses = -1
	
	-- If there are no killed bosses (as in legacy runs) for this run, we return immediately
	if run == nil or run.bosses == nil then
		return -1, -1, 0
	end
			
	-- Get main boss for this run
	if dt_db_name_to_index[ run.name ] ~= nil then
		local index = dt_db_name_to_index[ run.name ]
		local fields = dt_db[ index ]
		if fields[9] ~= nil then
			local boss_list = fields[9]
			max_bosses = #boss_list
			if max_bosses > 0 then
				main_boss = boss_list[1]			-- e.g. {"Bloodmage Thalnos", 4543}
			end
		end
	end
	
	-- Now find the main boss kill time
	if main_boss ~= nil then
		local main_boss_id = main_boss[2]

		-- Look for the boss kill time with this id
		if run.bosses[ main_boss_id ] ~= nil then
			main_boss_time = run.bosses[ main_boss_id ] - run.start
		end
	end

	-- Count the number of killed bosses
	for i,v in pairs( run.bosses ) do
		num_bosses = num_bosses + 1
	end
	
	-- Fix for when a boss is removed from the boss list after the run is completed -- don't wanna see "8/7 bosses killed"
	if num_bosses > max_bosses then
		num_bosses = max_bosses
	end

	-- Now return the number of bosses and the main boss time
	return num_bosses, max_bosses, main_boss_time

end

-- DungeonTrackerCheckVersions()
-- Prints a list of detected addon versions and verification status for the group members

local function DungeonTrackerCheckVersions()

	if next(Hardcore_Character.dt.current) and Hardcore_Character.dt.current.party ~= nil then

		local party = { string.split(",", Hardcore_Character.dt.current.party ) }

		if #party > 1 then
			local message = "Addon version / verification status check: "
			for i,v in ipairs( party ) do
				if v == UnitName("player") then
					local my_status = Hardcore:GetCleanVerificationStatus()
					message = message .. v .. ":" .. GetAddOnMetadata("Hardcore", "Version") .. " [" .. my_status .. "]"
				else
					message = message .. v .. ":"
					if dt_party_member_addon_version[ v ] ~= nil then
						message = message .. dt_party_member_addon_version[ v ]
					else
						message = message .. "?"
					end
					if dt_party_member_verif_status[ v ] ~= nil then
						message = message .. " [" .. dt_party_member_verif_status[ v ] .. "]"
					else
						message = message .. " [?]"
					end
				end
				if i < #party then
					message = message .. ", "
				end
			end
			Hardcore:Print(message)
		end
	end
end


-- DungeonTrackerCountTotalKills(run)
--
-- Counts the number of kills (normal + boss)

local function DungeonTrackerCountTotalKills(run)

	local num_kills = 0
	if run ~= nil then
		-- Count kills per mob_type
		if run.kills ~= nil then
			for _, w in pairs( run.kills ) do
				num_kills = num_kills + w
			end
		end
		-- Add bosses
		if run.bosses ~= nil then
			for _ in pairs( run.bosses ) do
				num_kills = num_kills + 1
			end
		end
	end
	return num_kills
end


-- DungeonTrackerUpgradeLogVersion3()
-- 
-- Upgrades and cleans up the dungeon log from a version 3 client

local function DungeonTrackerUpgradeLogVersion3()

	-- Fix up pending runs without an instance ID, or they will get dropped
	-- Also recount the number of total kills
	if Hardcore_Character.dt.pending ~= nil then
		for i, v in ipairs( Hardcore_Character.dt.pending ) do
			if v.iid == nil and v.time_inside >= DT_INSIDE_MAX_TIME then
				v.iid = 0
			end
			v.num_kills = DungeonTrackerCountTotalKills( v )
			v.log_now = true
		end
	end
	if Hardcore_Character.dt.runs ~= nil then
		for i, v in ipairs( Hardcore_Character.dt.runs ) do
			if v.date ~= "(legacy)" then
				v.num_kills = DungeonTrackerCountTotalKills( v )
			end
		end
	end
	if Hardcore_Character.dt.current ~= nil and next(Hardcore_Character.dt.current) then
		if Hardcore_Character.dt.current.iid == nil and Hardcore_Character.dt.current.time_inside >= DT_INSIDE_MAX_TIME then
			Hardcore_Character.dt.current.iid = 0			-- Will probably be overwritten by a later kill, but if not, then user can't reconnect later. So be it.
		end
		Hardcore_Character.dt.current.num_kills = DungeonTrackerCountTotalKills( Hardcore_Character.dt.current )
	end

	-- Get rid of some old data associated with the old way of doing legacy quest identification
	Hardcore_Character.dt.legacy_runs_imported = nil

end

-- DungeonTrackerMergeRuns
--
-- Merges a second run into the first, returning also the merged run (=run1)

local function DungeonTrackerMergeRuns( run1, run2 )

	-- Special handling if one of the runs is a legacy run -- then we just return the other one, because there is
	-- nothing interesting in the legacy run records anyway. We don't even want to see the quest_id
	if run1.date == "(legacy)" then
		run1 = run2
		return run1
	elseif run2.date == "(legacy)" then
		return run1
	end

	-- Overwrite the first run with all the new data
	-- The name, instanceID and mapID should not have to be changed (and we wouldn't know how to choose anyway)

	-- Find out the earliest start and latest last_seen
	-- If the first one started earlier, then the data and level should also be the lower one
	if run1.start > run2.start then
		run1.start = run2.start
		run1.date = run2.date
		run1.level = run2.level
	end
	if run1.last_seen < run2.last_seen then
		run1.last_seen = run2.last_seen
	end
	run1.time_inside = run1.time_inside + run2.time_inside

	-- Merge the kills
	if run1.num_kills == nil then
		run1.num_kills = 0
	end
	if run2.num_kills == nil then
		run2.num_kills = 0
	end
	run1.num_kills = run1.num_kills + run2.num_kills
	if run1.kills ~= nil or run2.kills ~= nil then
		if run1.kills == nil then
			run1.kills = {}
		end
		if run2.kills ~= nil then
			for i, v in pairs( run2.kills ) do
				if run1.kills[i] == nil then
					run1.kills[i] = 0
				end
				run1.kills[i] = run1.kills[i] + run2.kills[i]
			end
		end
	end

	-- Merge the boss kills, if any
	if run1.bosses ~= nil or run2.bosses ~= nil then
		if run1.bosses == nil then
			run1.bosses = {}
		end
		if run2.bosses ~= nil then
			for i, v in pairs( run2.bosses ) do
				if run1.bosses[ i ] ~= nil then
					Hardcore:Debug( "Boss " .. i .. " killed in both runs")
					run1.num_kills = run1.num_kills - 1			-- It's gotta add up!
				else
					run1.bosses[ i ] = run2.bosses[ i ]
				end
			end
		end
	end

	-- Merge the party members
	if run1.party == nil or run1.party == "" then
		run1.party = UnitName("player")
	end
	if run2.party ~= nil and run2.party ~= "" then
		local party2 = { string.split(",", run2.party ) }
		for i, v in ipairs( party2 ) do
			DungeonTrackerAddToParty( run1, v )
		end
	end

	return run1
end



-- DungeonTrackerClearOutsideQuestLegacyRuns()
--
-- Finds legacy quests that might have been caused by one of the erroneous dungeon
-- quests in 

local function DungeonTrackerClearOutsideQuestLegacyRuns()

	local tracked_runs = {}
	local legacy_runs_removed = 0

	-- We do this only once, ever
	if Hardcore_Character.dt.outside_quests_fixed ~= nil then
		return
	end
	Hardcore_Character.dt.outside_quests_fixed = true

	-- Get a quick hash of all the runs that are not legacy
	if Hardcore_Character.dt.runs ~= nil then
		for i, v in ipairs( Hardcore_Character.dt.runs ) do
			if v.id ~= nil and v.date ~= "(legacy)" then
				tracked_runs[ v.id ] = 1
			end
		end
	end
	if Hardcore_Character.dt.pending ~= nil then
		for i, v in ipairs( Hardcore_Character.dt.pending ) do
			if v.id ~= nil and v.date ~= "(legacy)" then
				tracked_runs[ v.id ] = 1
			end
		end
	end

	-- Check which of the outside quests was actually done.
	-- This is a table of outside quests (and their map id) that have been removed since 7 Feb 2023
	local outside_quests = { {2928, 90}, { 214, 36} , {1360, 70}, {1275, 48}, { 2922, 90}, {17,70} }
	for i, v in ipairs( outside_quests ) do
		if C_QuestLog.IsQuestFlaggedCompleted( v[1] ) then
			if tracked_runs[ v[2] ] ~= nil then
				-- Okay, we can delete legacy quests with this number (there can be only one!)
				for j, w in ipairs( Hardcore_Character.dt.runs ) do
					if w.date == "(legacy)" and w.id == v[2] then
						table.remove(Hardcore_Character.dt.runs, j)
						legacy_runs_removed = legacy_runs_removed + 1
						break
					end
				end
			end
		end
	end

	Hardcore:Debug( "Removed " .. legacy_runs_removed .. " legacy runs possibly linked to outside quests")
end

-- DungeonTrackerClearShortNoKillRuns()
--
-- Finds short runs with 0 kills logged and removes them

local function DungeonTrackerClearShortNoKillRuns()

	for i = #Hardcore_Character.dt.runs, 1, -1 do
		local v = Hardcore_Character.dt.runs[i]
		if v.num_kills ~= nil and v.num_kills == 0 and v.time_inside < DT_INSIDE_MAX_TIME_NO_KILLS then
			table.remove( Hardcore_Character.dt.runs, i )
			Hardcore:Debug( "Removed run with 0 kills in " .. v.name )
		end
	end

end



--  DungeonTrackerFindMergeableRuns()
--
-- Goes through the list of logged runs and gets rid of any runs that somehow were not
-- seen as one run, but should have been (i.e. same name and same instance ID and
-- not too far away dates)

local function DungeonTrackerFindMergeableRuns()

	local something_removed = false

	-- If there are no runs, or 1 run, there is nothing to merge
	if Hardcore_Character.dt.runs == nil or #Hardcore_Character.dt.runs < 2 then
		return false
	end

	-- Quick O(N) efficiency check -- if none of the dungeon names occur more than once, we can skip this
	if DungeonTrackerAnyRunNamesRepeated() == false then
		return false
	end

	-- Compare each with each, but check the second one backwards so it can be safely deleted
	for i = 1, #Hardcore_Character.dt.runs - 1 do
		if Hardcore_Character.dt.runs[i] ~= nil
			and Hardcore_Character.dt.runs[i].name ~= nil
			and Hardcore_Character.dt.runs[i].iid ~= nil
			and Hardcore_Character.dt.runs[i].start ~= nil
		then
			for j = #Hardcore_Character.dt.runs, i+1, -1 do
				if Hardcore_Character.dt.runs[j] ~= nil
					and Hardcore_Character.dt.runs[j].name ~= nil
					and Hardcore_Character.dt.runs[j].iid ~= nil
					and Hardcore_Character.dt.runs[j].start ~= nil
				then
					local time_diff = Hardcore_Character.dt.runs[i].start - Hardcore_Character.dt.runs[j].start
					if time_diff < 0 then
						time_diff = -time_diff
					end
					if Hardcore_Character.dt.runs[i].name == Hardcore_Character.dt.runs[j].name
						and Hardcore_Character.dt.runs[i].iid == Hardcore_Character.dt.runs[j].iid
						and time_diff < (12*3600)
					then
						Hardcore:Debug( "Merging dungeon runs with same instance ID in " .. Hardcore_Character.dt.runs[i].name .. " of "
								.. Hardcore_Character.dt.runs[i].date .. " and " .. Hardcore_Character.dt.runs[j].date )
						DungeonTrackerMergeRuns(Hardcore_Character.dt.runs[i], Hardcore_Character.dt.runs[j] )
						table.remove( Hardcore_Character.dt.runs, j)
						something_removed = true
					end
				end
			end
		end
	end

	-- Update the statistics if we did something
	if something_removed then
		DungeonTrackerUpdateInfractions()
	end

	return something_removed
end

-- DungeonTrackerGetVerificationData()
--
-- Returns the three fields of data that need to go into the verification string

function DungeonTrackerGetVerificationData()

	local overleveled_runs = 0
	local repeated_runs = 0

	if Hardcore_Character.dt ~= nil then
		if Hardcore_Character.dt.repeated_runs ~= nil then
			repeated_runs = Hardcore_Character.dt.repeated_runs
		end
		if Hardcore_Character.dt.overleveled_runs ~= nil then
			overleveled_runs = Hardcore_Character.dt.overleveled_runs
		end
	end

	return repeated_runs, overleveled_runs

end



-- DungeonTracker
--
-- Main interface function for the dungeon tracker, called on a 1s second timer

local function DungeonTracker()
	-- Era/Ogrimmar = Kalimdor, none, 0, , 0, 0, false, 1, 0, {nil}
	-- Era/RFC = Ragefire Chasm, party, 1, Normal, 5, 0, false, 389, 5, {nil}
	-- Note that the name is locale-dependent (and will be overrided below)
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize, LfgDungeonID =
		GetInstanceInfo()

	-- Handle invalid or legacy data files, or version upgrade (triggers full rebuild of dungeon database)
	if (Hardcore_Character.dt == nil) 						-- no DT yet
		or (Hardcore_Character.dt.version == nil) 			-- initial DT version without a version number
		or (Hardcore_Character.dt.version == 1)				-- older version, needs rebuild
		or (Hardcore_Character.dt.version == 2)				-- older version, needs rebuild
	then 
		Hardcore_Character.dt = {}
	end
	if not next(Hardcore_Character.dt) then
		Hardcore_Character.dt.current = {}
		Hardcore_Character.dt.runs = {}
		Hardcore_Character.dt.pending = {}
		Hardcore_Character.dt.repeated_runs = 0
		Hardcore_Character.dt.overleveled_runs = 0
		Hardcore_Character.dt.warn_infractions = true
		Hardcore_Character.dt.version = DT_VERSION
		Hardcore_Character.dt.sent_pulse = 0 -- Never sent out a pulse (yet)
	end
	if Hardcore_Character.dt.version ~= nil and Hardcore_Character.dt.version == 3 then
		Hardcore_Character.dt.version = DT_VERSION
		DungeonTrackerUpgradeLogVersion3()
	end

	-- Tell the watchdog we are still alive
	ReloadReminderDungeonTrackerUpdate()

	-- Sometimes, runs don't get logged correctly, like when they are pending and the addon is updated to a version
	-- with a different format or when runs are deleted through appeal commands. In those cases, runs might disappear
	-- entirely, while they should be there. We check for any missing or mergeable runs exactly once per session.
	if dt_checked_for_missing_runs == false then
		dt_checked_for_missing_runs = true
		C_Timer.After(5, function()
			Hardcore:Debug("Looking for erroneous, missing and mergeable runs...")
			DungeonTrackerClearOutsideQuestLegacyRuns()
			DungeonTrackerClearShortNoKillRuns()
			DungeonTrackerFindMissingRunsFromQuests()
			DungeonTrackerFindMergeableRuns()
			DungeonTrackerUpdateInfractions()
		end)
	end

	-- If we are outside....
	if instanceType == "none" then
		-- .. store the group composition for later (only works outside the instance)
		Hardcore_Character.dt.group_members = GetHomePartyInfo()
		
		-- Bug fix for the UnitLevel bug (returning a value off by one, probably due to instance still initialising?)
		local player_level = UnitLevel("player")
		if  player_level > dt_player_level then
			dt_player_level = player_level
		end
		
		-- Return if there is nothing more to be done (i.e. we are outside and there are no pending or current runs)
		if (not next(Hardcore_Character.dt.current)) and (not next(Hardcore_Character.dt.pending)) then
			return
		end
	end

	-- At this point, we are either in a dungeon, or we just left one (dt.current is still valid)
	-- If we just left a dungeon, move current to pending, and update timeouts
	if instanceType ~= "party" then
	
		-- Move current to pending
		if next(Hardcore_Character.dt.current) then
			-- Use a local variable to hold the run and clear the global state immediately.
			local runToProcess = Hardcore_Character.dt.current
			Hardcore_Character.dt.current = {}

			-- Now process the local variable. This prevents duplication even if an error occurs.
			if runToProcess.iid == nil then
				Hardcore:Debug("Dropping active run without instanceID in " .. runToProcess.name)
			elseif runToProcess.name == "Scarlet Monastery" then
				Hardcore:Debug("Dropping active Scarlet Monastery run without identified wing")
			else
				Hardcore:Debug("Queuing active run in " .. runToProcess.name)
				table.insert(Hardcore_Character.dt.pending, runToProcess)
			end

			-- We don't need the combat log anymore
			if combat_log_frame ~= nil then
				combat_log_frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
				combat_log_frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
				combat_log_frame.dtcl_script_registered = nil
			end				
		end
	end

	-- Finalize any pending runs for which more than the timeout has passed and for which no recent party pulse was received
	-- Do this backwards so deleting an element is safe.
	local now = GetServerTime()
	for i = #Hardcore_Character.dt.pending, 1, -1 do
		-- Update idle time (=time since we left or got last group pulse)
		Hardcore_Character.dt.pending[i].idle = now - Hardcore_Character.dt.pending[i].last_seen

		-- Calculate remaining time; it's the smallest of the two outside time outs
		local idle_time_left = min(DT_OUTSIDE_MAX_REAL_TIME - Hardcore_Character.dt.pending[i].idle, 
						DT_OUTSIDE_MAX_RUN_TIME - (now - Hardcore_Character.dt.pending[i].start))

		-- Log it if it expired, or if it was flagged by the log version upgrade code
		if idle_time_left <= 0 or Hardcore_Character.dt.pending[i].log_now ~= nil then
			Hardcore_Character.dt.pending[i].log_now = nil			-- clean up
			DungeonTrackerLogRun(Hardcore_Character.dt.pending[i])
			table.remove(Hardcore_Character.dt.pending, i)
			-- Just in case, we check if any of the logged runs is mergeable
			DungeonTrackerFindMergeableRuns()
		end
	end

	-- nothing more to be done when outside (or in raid, battleground, or arena)
	if instanceType ~= "party" then
		return
	end

	-- Start the combat log event handler to get the instance ID, SM wing identification and mob kills
	if combat_log_frame == nil then
		combat_log_frame = CreateFrame("Frame")
	end
	if combat_log_frame.dtcl_script_registered == nil then
		combat_log_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		combat_log_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
		combat_log_frame:SetScript("OnEvent", DungeonTrackerEventHandler )
		combat_log_frame.dtcl_script_registered = true
	end

	-- Override the name, we don't want to use the local language versions (unless we can't find the name)
	local EN_name = DungeonTrackerGetDungeonName(instanceMapID)
	if EN_name ~= "Unknown" then
		name = EN_name
	end

	-- Check if we are in a new dungeon (this has the special handling of Scarlet Monastery, which changes
	-- the name to the name including the wing, if it has been identified)
	name = DungeonTrackerCheckChanged(name)

	-- See if we can reconnect to a pending run (this forgets the current run, which is probably in an unidentified SM wing)
	-- We do this only if the current run and the pending run have the same name and the same instance ID
	for i = #Hardcore_Character.dt.pending, 1, -1 do
		if Hardcore_Character.dt.pending[i].name == name then
			if Hardcore_Character.dt.pending[i].iid ~= nil 			-- Should never happen, but yeah...
				and Hardcore_Character.dt.current.iid ~= nil
				and Hardcore_Character.dt.pending[i].iid == Hardcore_Character.dt.current.iid 
			then
				-- Add the inside time of the current run (should be defined since the iid has been found)
				Hardcore_Character.dt.pending[i].time_inside = Hardcore_Character.dt.pending[i].time_inside + Hardcore_Character.dt.current.time_inside
				Hardcore_Character.dt.current = Hardcore_Character.dt.pending[i]
				table.remove(Hardcore_Character.dt.pending, i)
				DungeonTrackerUpdateEntryCount()
				Hardcore:Debug("Reconnected to pending run in " .. Hardcore_Character.dt.current.name)
				break
			elseif Hardcore_Character.dt.pending[i].iid ~= nil 			-- Should never happen, but yeah...
				and Hardcore_Character.dt.pending[i].name ~= nil
				and Hardcore_Character.dt.current.iid ~= nil
				and Hardcore_Character.dt.current.name ~= nil
				and Hardcore_Character.dt.current.name == Hardcore_Character.dt.pending[i].name
				and Hardcore_Character.dt.pending[i].iid ~= Hardcore_Character.dt.current.iid 
			then
				-- A pending run with the same dungeon name exists, but a different instance ID => log it immediately
				Hardcore_Character.dt.pending[i].log_now = nil			-- clean up
				Hardcore:Debug("Forced logging of pending run in " .. Hardcore_Character.dt.pending[i].name .. " with different instance ID")
				DungeonTrackerLogRun(Hardcore_Character.dt.pending[i])
				table.remove(Hardcore_Character.dt.pending, i)
			else
				-- User did a "reset all instances", probably, or the current didn't have an IID yet.
				-- In the former case, a warning will be a given further down
			end
		end
	end

	-- If we don't have a current run at this point (reconnected or not), start a new run
	if not next(Hardcore_Character.dt.current) then
		DUNGEON_RUN = {}
		DUNGEON_RUN.name = name
		DUNGEON_RUN.id = instanceMapID
		DUNGEON_RUN.date = date("%m/%d/%y %H:%M:%S")
		DUNGEON_RUN.time_inside = 0
		DUNGEON_RUN.start = now
		DUNGEON_RUN.last_seen = now
		DUNGEON_RUN.idle = 0
		DUNGEON_RUN.level = max( dt_player_level, UnitLevel("player") )
		DUNGEON_RUN.num_kills = 0
		local group_composition = UnitName("player")
		if Hardcore_Character.dt.group_members ~= nil then
			for index, player in ipairs(Hardcore_Character.dt.group_members) do
				group_composition = group_composition .. "," .. player
			end
		end
		DUNGEON_RUN.party = group_composition

		-- Having a nil bosses list means we didn't track the bosses; while an empty list 
		-- means we simply didn't kill any. This depends on whether any boss info is in the database
		if DungeonTrackerDatabaseHasBossInfo( name ) then
			DUNGEON_RUN.bosses = {}
		end

		Hardcore_Character.dt.current = DUNGEON_RUN
		Hardcore:Debug("Starting new run in " .. Hardcore_Character.dt.current.name)

		-- Log the (re-)entry
		DungeonTrackerUpdateEntryCount()

		C_Timer.After( 45, function()
			DungeonTrackerCheckVersions()
		end)
	end

	-- Extend the current run (reconnected or new) by another time step and update the last_seen time
	Hardcore_Character.dt.current.time_inside = Hardcore_Character.dt.current.time_inside + DT_TIME_STEP
	Hardcore_Character.dt.current.last_seen = now

	-- Send out pings to group members
	DungeonTrackerSendPulse(now)

	-- Warn the user if he is repeating this run or is overleveled
	DungeonTrackerWarnInfraction()
end

-- DungeonTrackerInitiate()
--
-- Function to get our timer going
-- Called from Hardcore.lua as follows:
--		DungeonTrackerInitiate(COMM_NAME, COMM_COMMANDS[15], COMM_COMMAND_DELIM, COMM_FIELD_DELIM )

function DungeonTrackerInitiate(comm_name, pulse_cmd, cmd_delim, field_delim)
	-- Copy over Hardcore.lua locals needed for communication
	COMM_NAME = comm_name
	DT_PULSE_COMMAND = pulse_cmd
	COMM_COMMAND_DELIM = cmd_delim
	COMM_FIELD_DELIM = field_delim

	-- Compile some hash tables from the database
	DungeonTrackerInitializeHashes()

	-- Start the timer
	C_Timer.NewTicker(DT_TIME_STEP, function()
		DungeonTracker()
	end)
	
end

-- DungeonTrackerHandleAppealCode()
--
-- Handle a Mod command received through a coded string in chat
-- Specifying the date is only necessary when multiple dungeons are given
--
-- /hc AppealDungeonCode <hash> <cmd> <"dungeon name"> <"date">
--
-- /hc AppealDungeonCode <hash> delete <"dungeon name"> ["date"]
-- /hc AppealDungeonCode <hash> merge  <"dungeon name"> <"date1"> <"date2">
--
-- This function uses a proprietory cryptographic hash (yes, I know I shouldn't)
-- different from djb2() in Hardcore.lua, because that one doesn't work for long strings

local function GetCryptoHash(str)
	local a = 0
	local b = 0
	local dictionary = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 /:"

	for i = 1, #str do
		local x, y = string.find(dictionary, str:sub(i, i), 1, true)
		if x == nil then
			x = #dictionary
		end
		for i = 1, 17 do
			a = (a * -6 + b + 0x74FA - x) % 4096
			b = (math.floor(b / 3) + a + 0x81BE - x) % 4096
		end
	end
	return (a * 4096) + b
end

local function GetDungeonAppealCode(dungeon, date_str)
	local str = UnitName("player") .. UnitLevel("player") .. dungeon .. date_str
	return GetCryptoHash(str)
end

-- DungeonTrackerHandleAppealCode( args )
--
-- Called from Hardcore.lua when user types /hc AppealDungeonCode

function DungeonTrackerHandleAppealCode(args)
	local usage = "Usage: /hc AppealDungeonCode <code> <cmd> <args>\nwhere <cmd> = reset, delete or merge"
	local usage1 = '/hc AppealDungeonCode <code> delete "dungeon name" "date"'
	local usage2 = "/hc AppealDungeonCode <code> merge  <\"dungeon name\"> <\"date1\"> <\"date2\">"
	local code = nil
	local cmd = nil
	local quoted_args = {}

	-- Check and retrieve code and command
	for substring in args:gmatch("%S+") do
		if code == nil then
			code = substring
		elseif cmd == nil then
			cmd = substring
		end
	end
	if code == nil then
		Hardcore:Print("Wrong syntax: Missing <code> argument")
		Hardcore:Print(usage)
		return
	end
	if cmd == nil then
		Hardcore:Print("Wrong syntax: Missing <cmd> argument")
		Hardcore:Print(usage)
		return
	end

	-- Handle reset command (which doesn't need arguments)
	if cmd == "reset" then
		local appeal_code = GetDungeonAppealCode("", "")
		if tonumber(code) ~= tonumber(appeal_code) then
			Hardcore:Print("Incorrect code. Double check with a moderator.")
			return
		end
		Hardcore_Character.dt = nil
		Hardcore:Print("Dungeon log reset")
		return
	end

	-- Retrieve arguments in quotes, chuck away the code and command and space between
	-- for arg in args:gmatch('[^"]*') do
	for arg in args:gmatch('"(.-)"') do
		table.insert(quoted_args, arg)
	end

	if cmd == "delete" then
		if #quoted_args < 2 then
			Hardcore:Print("Wrong syntax: delete cmd should be followed by dungeon name and date string (both in quotes)")
			Hardcore:Print(usage1)
			return
		else
			-- Look for the run with that dungeon and date
			local run_found = false
			local index = 0
			for i, v in ipairs(Hardcore_Character.dt.runs) do
				if v.name == quoted_args[1]	and v.date == quoted_args[2] then
					run_found = true
					index = i
				end
			end

			if run_found == true then
				-- Check if the hash code is correct
				local appeal_code =	GetDungeonAppealCode(Hardcore_Character.dt.runs[index].name, Hardcore_Character.dt.runs[index].date)
				if tonumber(code) ~= tonumber(appeal_code) then
					Hardcore:Print("Incorrect code. Double check with a moderator.")
					return
				end

				-- Delete the run
				Hardcore:Print( "Removed dungeon run " 	.. Hardcore_Character.dt.runs[index].name .. " of "
						.. Hardcore_Character.dt.runs[index].date )
				table.remove(Hardcore_Character.dt.runs, index)
				DungeonTrackerUpdateInfractions()
				return
			else
				local message = "Dungeon run in " .. quoted_args[1]
				if #quoted_args == 2 then
					message = message .. " of " .. quoted_args[2]
				end
				Hardcore:Print(message .. " not found!")
				return
			end
		end
	elseif cmd == "merge" then
		if #quoted_args < 3 then
			Hardcore:Print("Wrong syntax: merge cmd should be followed by dungeon name and two date strings (all in quotes)")
			Hardcore:Print(usage2)
			return
		else
			-- Look for the run with that dungeon and date
			local run1_found = false
			local run2_found = false
			local index1
			local index2
			for i, v in ipairs(Hardcore_Character.dt.runs) do
				if v.name == quoted_args[1]	and v.date == quoted_args[2] then
					run1_found = true
					index1 = i
				end
				if v.name == quoted_args[1]	and v.date == quoted_args[3] then
					run2_found = true
					index2 = i
				end
			end

			if run1_found == true then
				if run2_found == true then
					-- Check if the hash code is correct
					local appeal_code =	GetDungeonAppealCode(quoted_args[1], quoted_args[2] .. quoted_args[3] )
					if tonumber(code) ~= tonumber(appeal_code) then
						Hardcore:Print("Incorrect code. Double check with a moderator.")
						return
					end

					-- Merge the runs
					Hardcore:Print( "Merging dungeon runs in " .. Hardcore_Character.dt.runs[index1].name .. " of "
							.. Hardcore_Character.dt.runs[index1].date .. " and " .. Hardcore_Character.dt.runs[index2].date )
					DungeonTrackerMergeRuns( Hardcore_Character.dt.runs[index1], Hardcore_Character.dt.runs[index2])
					table.remove(Hardcore_Character.dt.runs, index2)
					DungeonTrackerUpdateInfractions()
				else
					Hardcore:Print("Second run not found!")
					return
				end
			else
				Hardcore:Print("First run not found!")
				return
			end
		end
	else
		Hardcore:Print("Unknown command: " .. cmd)
		Hardcore:Print(usage)
		return
	end
end
