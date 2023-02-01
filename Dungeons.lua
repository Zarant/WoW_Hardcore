-- Dungeons.lua
-- Dungeon tracking functionality for WOW Classic Hardcore Addon
-- Written by Frank de Jong

-- Definitions
local DT_WARN_INTERVAL			  = 10		-- Warn every 10 seconds about repeated run (while in dungeon)
local DT_INSIDE_MAX_TIME          = 61		-- Maximum time inside a dungeon without it being logged (61 looks nicer than 60 in-game)
local DT_OUTSIDE_MAX_TRACKED_TIME = 1200	-- If seen outside, how many seconds seen outside before finalization (1200 = 20m)
local DT_OUTSIDE_MAX_REAL_TIME    = 1800	-- If seen outside, how many seconds since last seen inside before finalization (1800 = 30m)
local DT_OUTSIDE_MAX_RUN_TIME     = 21600	-- If seen outside, how many seconds since start of run before finalization (21600 = 6 hrs)
local DT_TIME_STEP			      = 1		-- Dungeon code called every 1 second
local DT_GROUP_PULSE			  = 30		-- Send group pulse every 30 seconds
local DT_VERSION			      = 3		-- Increasing this will trigger a full rebuild of the dungeon tracker info

-- Some local variables defined in Hardcore.lua -- Make sure these are the same as in Hardcore.lua!!
local CTL = _G.ChatThrottleLib
local COMM_NAME = "HardcoreAddon"			-- Overwritten in DungeonTrackerInitiate()
local COMM_COMMAND_DELIM = "$"				-- Overwritten in DungeonTrackerInitiate()
local COMM_FIELD_DELIM = "|"				-- Overwritten in DungeonTrackerInitiate()
local DT_PULSE_COMMAND = "DTPULSE"			-- Overwritten in DungeonTrackerInitiate()


-- dt_db ( = dungeon tracker database )
-- 
-- Contains all the info for the dungeons:
-- { instanceMapID, zoneID, "English Name", type = { "D", "R", "B", "O" }, max_players, max_runs, { max_level_era, max_level_wotlk }, { quests } },
-- Types: D = dungeon (5-player), R = raid, B = battleground, O = other

local dt_db = {

	-- Era dungeons
	{ 389, 2437, "Ragefire Chasm", "D", 5, 1, {18, 20}, {5728, 5761, 5722, 5723, 5725} }, 		-- All 5 quests in RFC
	{  36, 1581, "The Deadmines", "D", 5, 1, {26, 24}, {2040, 166, 214, 373} },					-- Underground Assault, The Defias Brotherhood, Red Silk Bandanas, The Unsent Letter
	{  43,  718, "Wailing Caverns", "D", 5, 1, {24, 24}, {914, 1487, 3366} },					-- Leaders of the Fang, Deviate Eradication, The Glowing Shard
	{  33,  209, "Shadowfang Keep", "D", 5, 1, {30, 25}, {1013, 1098, 1014} },					-- The Book of Ur, Deathstalkers in Shadowfang, Arugal Must Die
	{  48,  719, "Blackfathom Deeps", "D", 5, 1, {32, 28}, {971, 1198, 1199, 1275, 6565, 6921, 1200, 6561, 6922 }} ,
	{  34,  717, "The Stockade", "D", 5, 1, {32, 29}, {387, 386, 378, 388, 377, 391} },
	{  47,  491, "Razorfen Kraul", "D", 5, 1, {38, 31}, {1221, 1102, 1109, 1101, 1144, 1142, 6522} },
	{  90,  721, "Gnomeregan", "D", 5, 1, {38, 32}, {2904, 2951, 2945, 2922, 2928, 2924, 2930, 2929, 2841} },
	{ 129,  722, "Razorfen Downs", "D", 5, 1, {46, 41}, {3636, 3341, 3525} },
	{ 189,  796, "Scarlet Monastery", "D", 5, 1, {45, 44}, {} },
	{ 18901, 79601, "Scarlet Monastery (GY)", "D", 5, 1, {45, 44}, {} },									-- Bit of a hack here, 4 wings don't have a separate ID; No quests in GY
	{ 18902, 79602, "Scarlet Monastery (Lib)", "D", 5, 1, {45, 44}, {1050, 1053, 1049, 1048, 1160, 1951} },	-- 1048+1053: kill 4 bosses needs Lib+Cath+Arm
	{ 18903, 79603, "Scarlet Monastery (Cath)", "D", 5, 1, {45, 44}, {1053, 1048} },
	{ 18904, 79604, "Scarlet Monastery (Arm)", "D", 5, 1, {45, 44}, {1053, 1048} },
	{  70, 1137, "Uldaman", "D", 5, 1, {51, 44}, {1360, 2240, 17, 1139, 2204, 2278} },
	{ 209, 1176, "Zul'Farrak", "D", 5, 1, {54, 50}, {3042, 2865, 2846, 2768, 2770, 3527, 2991, 2936} },
	{ 349, 2100, "Maraudon", "D", 5, 1, {55, 52}, {7041, 7029, 7065, 7064, 7067, 7044, 7046} },
	{ 109, 1477, "The Temple of Atal'Hakkar", "D", 5, 1, {60, 54}, {3528, 3446, 3447, 3373} },			-- 1475, 4143, 4146, removed: tablets and haze drop outside
	{ 229, 1583, "Blackrock Spire", "D", 10, 1, {60, 62}, {4701, 5001, 4724, 4982, 4903, 4862, 4729, 4788, 4768, 4974, 4764, 5102, 6821, 7761} },  -- UBRS and LBRS are one instance
	{ 230, 1584, "Blackrock Depths", "D", 5, 1, {60, 60}, {4136, 4123, 4286, 4126, 4081, 4134} },
	{ 289, 2057, "Scholomance", "D", 5, 1, {60, 62}, {5529, 5582, 5382, 5384, 5466, 5343, 5341} },
	{ 429, 2557, "Dire Maul", "D", 5, 1, {60, 62}, {7488, 7489, 7441, 7461, 7462, 7703, 5526} },
	{ 329, 2017, "Stratholme", "D", 5, 1, {60, 62}, {5282, 5214, 5251, 5262, 5848, 5122, 5212, 5263, 5243, 5122, 6163, 5463, 8945} },	-- Undead / Live parts are one instance
	-- Era Raids
	{ 249, 2159, "Onyxia's Lair", "R", 40, 1000, {1000, 1000}, {} },
	{ 309, 1977, "Zul'Gurub", "R", 20, 1000, {1000, 1000}, {} },
	{ 409, 2717, "Molten Core", "R", 40, 1000, {1000, 1000}, {} },
	{ 469, 2677, "Blackwing Lair", "R", 40, 1000, {1000, 1000}, {} },
	{ 509, 3429, "Ruins of Ahn'Qiraj", "R", 20, 1000, {1000, 1000}, {} },
	{ 531, 3428, "Ahn'Qiraj", "R", 40, 1000, {1000, 1000}, {} },
	-- Era Battlegrounds
	{ 489, 3277, "Warsong Gulch", "B", 10, 1000, {1000, 1000}, {} },
	{ 30,  2597, "Alterac Valley", "B", 40, 1000, {1000, 1000}, {} },
	{ 529, 3358, "Arathi Basin", "B", 15, 1000, {1000, 1000}, {} },
		
	-- TBC dungeons
	{ 543, 3562, "Hellfire Ramparts", "D", 5, 1, {1000,64}, {9575, 9572, 9587, 9588} },
	{ 542, 3713, "The Blood Furnace", "D", 5, 1, {1000,65}, {9607, 9608, 9589, 9590} },
	{ 547, 3717, "The Slave Pens", "D", 5, 1, {1000,66}, {9738} },
	{ 546, 3716, "The Underbog", "D", 5, 1, {1000,66}, {9738, 9717, 9719} },		-- 9715 removed because also drops in Steamvault
	{ 557, 3792, "Mana-Tombs", "D", 5, 1, {1000,68}, {10216, 10218, 10165} },
	{ 558, 3790, "Auchenai Crypts", "D", 5, 1, {1000,70}, {10164, 10167} },			-- "All remaining TBC dungeons have a MAX level of 70"
	{ 560, 2367, "Old Hillsbrad Foothills", "D", 5, 1, {1000,70}, {10283, 10284, 10285 } },
	{ 556, 3791, "Sethekk Halls", "D", 5, 1, {1000,70}, {10097, 10098} },
	{ 553, 3847, "The Botanica", "D", 5, 1, {1000,70}, {10704, 10257, 10897} }, 
	{ 555, 3789, "Shadow Labyrinth", "D", 5, 1, {1000,70}, {10885, 10094, 10095, 10091, 10649, 10666, 9831} },
	{ 545, 3715, "The Steamvault", "D", 5, 1, {1000,70}, {9763, 9832, 10667, 10885} },
	{ 540, 3714, "The Shattered Halls", "D", 5, 1, {1000,70}, {9492, 9495, 9493, 9496, 10670} },
	{ 554, 3849, "The Mechanar", "D", 5, 1, {1000,70}, {10704, 10665} },
	{ 269, 2366, "The Black Morass", "D", 5, 1, {1000,70}, {10296, 10297, 10298, 9836, 9837, 10902} },
	{ 552, 3848, "The Arcatraz", "D", 5, 1, {1000,70}, {9832, 10886} },
	{ 585, 4131, "Magisters' Terrace",  "D", 5, 1, {1000,70}, {11492, 11499} },
	-- TBC Raids
	{ 532, 3457, "Karazhan", "R", 10, 1000, {1000,1000}, {} },
	{ 533, 3456, "Naxxramas", "R", 40, 1000, {1000,1000}, {} },
	{ 534, 3606, "Hyjal Summit", "R", 25, 1000, {1000,1000}, {} },
	{ 544, 3836, "Magtheridon's Lair", "R", 25, 1000, {1000,1000}, {} },
	{ 548, 3607, "Serpentshrine Cavern", "R", 25, 1000, {1000,1000}, {} },
	{ 564, 3959, "Black Temple", "R", 25, 1000, {1000,1000}, {} },
	{ 565, 3923, "Gruul's Lair", "R", 25, 1000, {1000,1000}, {} },
	{ 568, 3805, "Zul'Aman", "R", 10, 1000, {1000,1000}, {} },
	{ 580, 4075, "Sunwell Plateau", "R", 25, 1000, {1000,1000}, {} },
	{ 550, 3845, "Tempest Keep", "R", 25, 1000, {1000,1000}, {} },
	-- TBC Battlegrounds
	{ 566, 3820, "The Eye of the Storm", "B", 15, 1000, {1000,1000}, {} },
	
	-- WotLK dungeons
	{ 574,  206, "Utgarde Keep", "D", 5, 1, {1000,74}, {11272, 13206, 11262, 13245, 13205, 11252} },
	{ 576, 4265, "The Nexus", "D", 5, 1, {1000,75}, {13094, 13095, 11905, 11911, 11973, 13246} },
	{ 601, 4277, "Azjol-Nerub", "D", 5, 1, {1000,76}, {13167, 13182, 13254} },
	{ 619, 4494, "Ahn'kahet: The Old Kingdom", "D", 5, 1, {1000,77}, {13187, 13204, 13190, 13255} },
	{ 600, 4196, "Drak'Tharon Keep", "D", 5, 1, {1000,78}, {12238, 12037, 13129, 13249} },
	{ 608, 4415, "The Violet Hold", "D", 5, 1, {1000,79}, {13158, 13159, 13256} },
	{ 604, 4416, "Gundrak", "D", 5, 1, {1000,80}, {13098, 13096, 13111, 13250} },
	{ 599, 4264, "Halls of Stone", "D", 5, 1, {1000,80}, {13207, 13252} },
	{ 602, 4272, "Halls of Lightning", "D", 5, 1, {1000,80}, {13109, 13108, 13244, 13253} },
	{ 668, 4820, "Halls of Reflection", "D", 5, 1, {1000,80}, {24713, 24711, 24802, 24500, 24561, 24480} },
	{ 595, 4100, "The Culling of Stratholme", "D", 5, 1, {1000,80}, {13151, 13149, 13240, 13251} },
	{ 575, 1196, "Utgarde Pinnacle", "D", 5, 1, {1000,80}, {13131, 13132, 13241, 13248} },
	{ 578, 4228, "The Oculus", "D", 5, 1, {1000,80}, {13124, 13126, 13127, 13128, 13240, 13247} },
	{ 650, 4723, "Trial of the Champion", "D", 5, 1, {1000,80}, {14199} },
	{ 632, 4809, "The Forge of Souls", "D", 5, 1, {1000,80}, {24506, 24510, 24511, 24499, 24682, 24683} },
	{ 658, 4813, "Pit of Saron", "D", 5, 1, {1000,80}, {24682, 24683, 24507, 24498, 24712, 24710, 24713, 24711, 24559, 24461 }},
	-- WotLK raids
	{ 603, 4273, "Ulduar", "R", 25, 1000, {1000,1000}, {} },
	{ 615, 4493, "The Obsidian Sanctum", "R", 25, 1000, {1000,1000}, {} },
	{ 616, 4500, "The Eye of Eternity", "R", 25, 1000, {1000,1000}, {} },
	{ 624, 4603, "Vault of Archavon", "R", 25, 1000, {1000,1000}, {} },
	{ 631, 4812, "Icecrown Citadel", "R", 25, 1000, {1000,1000}, {} },
	{ 649, 4722, "Trial of the Crusader", "R", 25, 1000, {1000,1000}, {} },
	{ 724, 4987, "Ruby Sanctum",  "R", 25, 1000, {1000,1000}, {} },
	-- WotLK Battlegrounds
	{ 628, 4710, "Isle of Conquest", "B", 40, 1000, {1000,1000}, {} },
	
	-- Other
	{ 449, "Champion's Hall", 1000, 1000, {1000, 1000}, {} },
	{ 450, "Hall of Legends", 1000, 1000, {1000, 1000}, {} },
	--{ , "Borean Tundra", },					-- TO BE DONE, maybe
	--{ , "Strand of the Ancients", },			-- TO BE DONE, maybe

}

local dt_db_id_to_name = nil
local dt_db_max_levels = nil

-- DungeonTrackerGetDungeonName( id )
--
-- Needed to get around regionalised names. We want everything in English, yo!

local function DungeonTrackerGetDungeonName( id )

	-- Create the hash if we haven't already
	if dt_db_id_to_name == nil then
		dt_db_id_to_name = {}
		for i, v in ipairs( dt_db ) do
			dt_db_id_to_name[ v[1] ] = v[3]
		end
	end
	
	if dt_db_id_to_name[ id ] == nil then
		return "Unknown"
	end
		
	return dt_db_id_to_name[ id ]

end

local function DungeonTrackerGetDungeonMaxLevel( name )

	local max_level = 1000		-- Default: if we can't find it, or game version not set: it doesn't have a max level

	-- Construct the hash if we haven't already
	if dt_db_max_levels == nil then
		dt_db_max_levels = {}
		for i, v in ipairs( dt_db ) do
			if v[7] ~= nil then
				dt_db_max_levels[ v[3] ] = v[7]
			else
				dt_db_max_levels[ v[3] ] = { 1000, 1000 }
			end
		end
	end

	if dt_db_max_levels[ name ] ~= nil then
		if Hardcore_Character.game_version ~= nil then
			if Hardcore_Character.game_version == "Era" or Hardcore_Character.game_version == "SoM" then
				max_level = dt_db_max_levels[ name ][ 1 ];
			elseif Hardcore_Character.game_version == "WotLK" then
				max_level = dt_db_max_levels[ name ][ 2 ];
			end
		end
	end
	
	return max_level

end


-- DungeonTrackerGetAllDungeonMaxLevels()
--
-- Returns a table of dungeons and associated max levels
-- (only dungeons, not raids, not battle grounds)
-- Mostly for use in the Rules tab (so not local), called from Mainmenu.lua

function DungeonTrackerGetAllDungeonMaxLevels()

	local the_table = {}
	
	for i,v in pairs( dt_db ) do
		if v[4] == "D" then
			local max_era_level = v[7][1]
			if max_era_level == 1000 then
				max_era_level = "--"
			end
			table.insert( the_table, { v[3], max_era_level, v[7][2] } )
		end
	end
	
	return the_table
end


local function DungeonTrackerPopulateFromQuests()

	-- Try to guess the dungeon history prior to tracking by looking at the dungeon quests that have been 
	-- finished. Only use the ones that can ONLY be done inside the dungeon! (So for instance, not 
	-- WC/Serpentbloom or SM/Hearts of Zeal)

	-- Double check that we haven't JUST been reset by an appeal command
	if Hardcore_Character.dt == nil then
		return
	end
	
	-- Only run this when we have no other dungeon info, to prevent mix-ups between legacy and current dungeons
	if next( Hardcore_Character.dt.runs) then
		return
	end

	Hardcore:Debug( "Logging legacy runs.." )

	-- Go through the list and log a run for each dungeon for which one or more quests are flagged as completed
	for i, v in pairs( dt_db ) do
		local dungeon_done = false
		local quests = v[8]
		if quests ~= nil then
			local j
			for j = 1, #quests do
				if C_QuestLog.IsQuestFlaggedCompleted(quests[j]) then
					Hardcore:Debug( "Found legacy quest " .. quests[j] )
					dungeon_done = true
					break
				end
			end
		end
		if dungeon_done == true then
			DUNGEON_RUN = {}
			DUNGEON_RUN.name   		 = v[3]
			DUNGEON_RUN.id			 = v[1]
			DUNGEON_RUN.date   		 = "(legacy)"
			DUNGEON_RUN.time_inside  = 0
			DUNGEON_RUN.level        = 0
			DUNGEON_RUN.quest_id     = quests[j]
			Hardcore:Print( "Logging legacy run in " .. DUNGEON_RUN.name )
			table.insert( Hardcore_Character.dt.runs, DUNGEON_RUN )
		end
	end
end


local function DungeonTrackerIsRepeatedRun( run1, run2 )

	-- Most common case is where everything is in English; then the names should be the same
	if run1.name == run2.name then
		return true
	end
	
	-- Handle exceptional case for Scarlet Monastery -- there, the instanceMapID will be the same for different wings,
	-- but there is no repeated run if you do them both. The "true" must have come from the run name comparison above.
	if run1.id ~= nil and run1.id == 189  then
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
		if Hardcore_Character.dt.runs[ i ].level > DungeonTrackerGetDungeonMaxLevel( Hardcore_Character.dt.runs[ i ].name ) then
			over_leveled = over_leveled + 1
		end
		-- Check if the run is repeated further down in the array (this prevents counting runs twice when i ends up at j)
		for j = i + 1, #Hardcore_Character.dt.runs do

			if DungeonTrackerIsRepeatedRun( Hardcore_Character.dt.runs[ i ], Hardcore_Character.dt.runs[ j ] ) then
				repeated = repeated + 1
			end
		end
	end
	
	Hardcore_Character.dt.overleveled_runs = over_leveled
	Hardcore_Character.dt.repeated_runs = repeated
	
end


local function DungeonTrackerWarnInfraction()

	local time_left = DT_INSIDE_MAX_TIME - Hardcore_Character.dt.current.time_inside
	-- We only warn if there is still chance to get out in time
	if time_left <= 0 then
		return
	end
	
	-- Don't warn too frequently
	if (Hardcore_Character.dt.current.last_warn ~= nil) and
	   (Hardcore_Character.dt.current.time_inside - Hardcore_Character.dt.current.last_warn < DT_WARN_INTERVAL) then
		return
	end
	
	-- Don't warn at max level (they can do whatever dungeon then) or when the user turned warnings off
	-- /run Hardcore_Character.dt.warn_infractions=false
	if Hardcore_Character.dt.warn_infractions == false then
		return
	end
	
	-- Get max level to know if we should even warn
	if Hardcore_Character.game_version ~= nil then
		local max_level
		if Hardcore_Character.game_version == "Era" or Hardcore_Character.game_version == "SoM" then
			max_level = 60
		else -- if Hardcore_Character.game_version == "WotLK" or anything else
			max_level = 80
		end
		if UnitLevel( "player" ) >= max_level then
			Hardcore_Character.dt.warn_infractions = false
			return
		end
	end

	-- See if the player's level is allowed in this dungeon
	local max_level = DungeonTrackerGetDungeonMaxLevel( Hardcore_Character.dt.current.name )
	if Hardcore_Character.dt.current.level > max_level then
		Hardcore_Character.dt.current.last_warn = Hardcore_Character.dt.current.time_inside
		message = "\124cffFF0000You are overleveled for " .. Hardcore_Character.dt.current.name .. ", max level = " .. max_level .. 
				  " -- leave the dungeon within " .. time_left .. " seconds!"
		Hardcore:Print(message)
	end	

	-- See if this dungeon was already in the list of runs, and warn every so many seconds if that is so
	for i, v in ipairs(Hardcore_Character.dt.runs) do
		if DungeonTrackerIsRepeatedRun( v, Hardcore_Character.dt.current ) then
			Hardcore_Character.dt.current.last_warn = Hardcore_Character.dt.current.time_inside
			message = "\124cffFF0000You entered " .. v.name .. " already at date " .. v.date .. 
					  " -- leave the dungeon within " .. time_left .. " seconds!"
			Hardcore:Print(message)
			break		-- No need to warn about 3rd and higher entries
		end
	end
end


local function DungeonTrackerLogRun( run )

	-- We don't log this run if the inside time is too small
	if run.time_inside < DT_INSIDE_MAX_TIME then
		Hardcore:Debug( "Not logging short run in " .. run.name )
		return
	end
	
	-- Don't store an SM run without a wing -- if we didn't even run into any recognised mob, what's the point?
	if run.name == "Scarlet Monastery" then
		Hardcore:Debug( "Not logging run in unidentified SM wing" )
		return
	end

	-- Warn if this is a repeated run and log
	for i, v in ipairs(Hardcore_Character.dt.runs) do
		if DungeonTrackerIsRepeatedRun( v, run ) then
			if Hardcore_Character.dt.warn_infractions == true then
				Hardcore:Print( "\124cffFF0000Player entered " .. run.name .. " already at date " .. v.date .. " -- logging repeated run" )
			end
			break
		end
	end

	-- Warn if this is an overleveled run and log
	local max_level = DungeonTrackerGetDungeonMaxLevel( run.name )
	if run.level > max_level then
		if Hardcore_Character.dt.warn_infractions == true then
			Hardcore:Print( "\124cffFF0000Player was overleveled for " .. run.name .. " -- logging overleveled run" )
		end
	end

	-- Now actually log the run
	Hardcore:Debug( "Logging run in " .. run.name )
	table.insert( Hardcore_Character.dt.runs, run )

	-- Update infraction statistics (involves a re-count)
	DungeonTrackerUpdateInfractions()
end


-- For TargetUnit() trick to find door mobs for Scarlet Monastery
local dt_forbidden = false

-- Function to do the unitscan trick of seeing nearby NPC for dungeon tracking
-- Called from the ADDON_ACTION_FORBIDDEN event handler in Hardcore.lua
function DungeonTrackerHandleActionForbidden(arg1)
	if arg1 == 'Hardcore' then
		dt_forbidden = true
	end
end

local function DungeonTrackerCheckChanged( name )

	-- If there is no current, there is no change
	if not next(Hardcore_Character.dt.current) then
		return name
	end

	local SM = "Scarlet Monastery"

	-- If this is Scarlet Monastery (any wing), we need to check if the wing changed
	if name == SM then
		
		-- If we don't know which wing we are in, try to identify any of the dungeon wing's mobs
		if Hardcore_Character.dt.current.name == SM then
			-- List of door spawns; first try a couple of ones close to the door, then add a few from deeper
			-- to make sure we're not missing anything; finally, add the bosses
			-- Thanks to @Oats for compiling the list.
			local door_spawns = {
					["Scarlet Scryer"] = "GY",
					["Scarlet Torturer"] = "GY",
					["Scarlet Gallant"] = "Lib",
					["Scarlet Adept"] = "Lib",
					["Scarlet Soldier"] = "Arm",
					["Scarlet Conjuror"] = "Arm",
					["Scarlet Defender"] = "Cath",
					--["Scarlet Myrmidon"] = "Cath",		-- Disabled pending @Oats double-check
					-- One more round of deeper-in mobs
					["Haunting Phantasm"] = "GY",
					["Scarlet Beastmaster"] = "Lib",
					["Scarlet Diviner"] = "Lib",
					["Scarlet Evoker"] = "Arm",
					["Scarlet Sorceror"] = "Cath",	
					-- Bosses as a last resort
					["Interrogator Vishas"] = "GY",
					["Houndmaster Loksey"] = "Lib",
					["Arcanist Doan"] = "Lib",
					["Herod"] = "Arm",
					["Scarlet Commander Mograine"] = "Cath",
					["High Inquisitor Whitemane"] = "Cath"					
			}
			
			local npc, wing
			local reaction = 0
			for npc, wing in pairs(door_spawns) do
				dt_forbidden = false
				TargetUnit( npc, true )				-- This throws an exception if the unit is found; we catch this and change dt_forbidden
				if dt_forbidden == true then
					--Hardcore:Debug( "Found " .. npc .. " in " .. wing )
					-- We know where we are now, so set the proper wing name as dungeon name
					name = name .. " (" .. wing .. ")"
					-- Now check if we knew the wing already
					if Hardcore_Character.dt.current.name == SM then
						-- We didn't know the wing, so we set it and assume it didn't change
						Hardcore_Character.dt.current.name = name
						Hardcore:Debug( "Identified SM wing " .. wing )
					end
					break
				end
			end
		else
			-- We already know our wing -- just copy over what we already had
			name = Hardcore_Character.dt.current.name
		end
		
		-- At this point, either dt.current.name is "SM", or it is "SM (Wing)".
		-- If it's "SM", the name can only be "SM", too. This happens if no door spawn was found yet.
		-- If it's "SM (Wing)", then "name" has a wing too, which is either the same or different
		
	end

	-- Now check if the name changed (whether it's SM or RFC or whatever)
	-- This should normally not happen, as once we're outside, the current dungeon is queued
	if Hardcore_Character.dt.current.name ~= name then
		-- Change to the new dungeon, but we store only if we spent enough time
		Hardcore:Debug( "Left dungeon " .. Hardcore_Character.dt.current.name .. " for dungeon " .. name )
		DungeonTrackerLogRun( Hardcore_Character.dt.current )
		Hardcore_Character.dt.current = {}
	end

	return name

end

-- DungeonTrackerReceivePulse( data, sender )
--
-- Receives a group pulse, storing the time in the message and the sender in the associated pending run
-- Not a local function, called from Hardcore.lua

function DungeonTrackerReceivePulse( data, sender )

	local short_name
	local ping_time
	local dungeon_name
	local run_name

	short_name, version, ping_time, dungeon_name, dungeon_id = string.split(COMM_FIELD_DELIM, data)
	ping_time = tonumber( ping_time )
	Hardcore:Debug( "Received dungeon group pulse from " .. sender .. ", data = " .. short_name .. ", " .. ping_time .. ", " .. dungeon_name ) 
	
	-- Check for errors, dt might not be set right now (if it just got reset for some weird reason)
	if  (Hardcore_Character.dt == nil) or 
		(not next( Hardcore_Character.dt )) or 
		(not next( Hardcore_Character.dt.pending )) then
		return
	end
	
	-- Update the latest ping time in the idle runs only (no need to do it in current run)
	for i, v in pairs( Hardcore_Character.dt.pending ) do
		-- If we receive a pulse from "Scarlet Monastery" (without wing), then we have no choice but
		-- to store that pulse in all idle SM runs (the inside party member might be standing on the
		-- doorstep of a partly cleared wing, and see no door mobs). 
		-- So then we don't care about the wing of the pending run, and just update them all
		if dungeon_name == "Scarlet Monastery" then
			run_name = string.sub( v.name, 1, 17 )		-- This also cuts "The Temple of Atal'Hakkar" to "The Temple of Ata", but that's okay
		else
			run_name = v.name
		end
		
		-- If this is the run from which the ping originated, and the ping time is later than we already have, store it
		if run_name == dungeon_name then
			if ping_time > v.last_pulse then
				v.last_pulse = ping_time
			end
			
			-- Add the ping sender to the party members, if not already there
			if string.find( v.party, short_name ) == nil then
				v.party = v.party .. "," .. short_name
			end			
		end
	end
end

-- DungeonTrackerSendPulse( now )
--
-- Sends a group pulse, if the time out is expired

local function DungeonTrackerSendPulse( now )

	-- Don't send too many pulses, one every 30 seconds is enough
	if (Hardcore_Character.dt.sent_pulse ~= nil) and 
	   (now - Hardcore_Character.dt.sent_pulse < DT_GROUP_PULSE) then
		return
	end
	Hardcore_Character.dt.sent_pulse = now

	-- Send my own info to the party (=name + server time + dungeon)
	if( CTL ) then
		local name = UnitName("player")
		local data = name .. COMM_FIELD_DELIM .. 
					GetAddOnMetadata("Hardcore", "Version") .. COMM_FIELD_DELIM .. 
					now .. COMM_FIELD_DELIM .. 
					Hardcore_Character.dt.current.name .. COMM_FIELD_DELIM .. 
					Hardcore_Character.dt.current.id
		local comm_msg = DT_PULSE_COMMAND .. COMM_COMMAND_DELIM .. data
		Hardcore:Debug( "Sending dungeon group pulse: " .. comm_msg )
		CTL:SendAddonMessage("NORMAL", COMM_NAME, comm_msg, "PARTY")

		-- For debug purposes, set this to true to simulate a send
		if false then
			DungeonTrackerReceivePulse( data, name .. "-TestServer" )
		end
	end
end

-- DungeonTracker
--
-- Main interface function for the dungeon tracker, called on a 1s second timer

local function DungeonTracker()

	-- Era/Ogrimmar = Kalimdor, none, 0, , 0, 0, false, 1, 0, {nil}
	-- Era/RFC = Ragefire Chasm, party, 1, Normal, 5, 0, false, 389, 5, {nil}
	-- Note that the name is locale-dependent (and will be overrided below)
	local name, instanceType, difficultyID, difficultyName, 
		maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()

	-- Handle invalid or legacy data files, or version upgrade (triggers full rebuild of dungeon database)
	if (Hardcore_Character.dt == nil) or 					-- no DT yet
	   (Hardcore_Character.dt.version == nil) or 			-- initial DT version without a version number
	   (Hardcore_Character.dt.version ~= DT_VERSION) then	-- older version (with a version number)
		Hardcore_Character.dt = {}
	end
	if not next( Hardcore_Character.dt ) then
		Hardcore_Character.dt.current = {}
		Hardcore_Character.dt.runs = {}
		Hardcore_Character.dt.pending = {}
		Hardcore_Character.dt.repeated_runs = 0
		Hardcore_Character.dt.overleveled_runs = 0
		Hardcore_Character.dt.legacy_runs_imported = false
		Hardcore_Character.dt.warn_infractions = true
		Hardcore_Character.dt.version = DT_VERSION
		Hardcore_Character.dt.sent_pulse = 0				-- Never sent out a pulse (yet)
	end

	-- If there are no logged runs yet, we try to figure out which dungeons were already done from the completed quests.
	-- For some weird reason, this doesn't always work if you just came into an instance or back into the world, so
	-- we do this on a timer. We only do this once, ever.
	if Hardcore_Character.dt.legacy_runs_imported == false then
		C_Timer.After( 5, function () DungeonTrackerPopulateFromQuests() end )
		Hardcore_Character.dt.legacy_runs_imported = true
	end

	-- Quick check to see if there is no work to be done. We also store the group composition for later (only works outside the instance)
	if instanceType == "none" then 
		Hardcore_Character.dt.group_members = GetHomePartyInfo()
		if (not next(Hardcore_Character.dt.current)) and (not next(Hardcore_Character.dt.pending)) then
			return
		end
	end

	-- At this point, we are either in a dungeon, or we just left one (dt.pending is still valid)
	local now = GetServerTime()
	
	-- If we are no longer in a dungeon, move current to pending, and update timeouts
	if instanceType ~= "party" then
		-- Move current to pending
		if next(Hardcore_Character.dt.current) then
			Hardcore:Debug( "Queuing active run in " .. Hardcore_Character.dt.current.name )
			table.insert( Hardcore_Character.dt.pending, Hardcore_Character.dt.current )
			Hardcore_Character.dt.current = {}
		end
	end
	
	-- Finalize any pending runs for which more than the timeout has passed and for which no recent party pulse was received
	-- Do this backwards so deleting an element is safe.
	for i=#Hardcore_Character.dt.pending,1,-1  do
		Hardcore_Character.dt.pending[i].time_outside = Hardcore_Character.dt.pending[i].time_outside + DT_TIME_STEP
		
		-- Calculate remaining time; it's the smallest of the three outside time outs
		local idle_time_left = DT_OUTSIDE_MAX_TRACKED_TIME - Hardcore_Character.dt.pending[ i ].time_outside
		idle_time_left = min( idle_time_left, DT_OUTSIDE_MAX_REAL_TIME - (now - Hardcore_Character.dt.pending[ i ].last_seen)  )
		idle_time_left = min( idle_time_left, DT_OUTSIDE_MAX_RUN_TIME  - (now - Hardcore_Character.dt.pending[ i ].start)  )
		
		-- Override the remaining time if we got a group pulse
		idle_time_left = max( idle_time_left, DT_OUTSIDE_MAX_TRACKED_TIME - (now - Hardcore_Character.dt.pending[ i ].last_pulse) )
		
		-- Update idle time left for the user interface
		Hardcore_Character.dt.pending[ i ].idle_left = idle_time_left
		
		-- Log it if it expired
		if idle_time_left <= 0 then
			DungeonTrackerLogRun(Hardcore_Character.dt.pending[ i ])
			table.remove( Hardcore_Character.dt.pending, i )
		end
	end
	
	-- nothing more to be done when outside (or in raid, battleground, or arena)
	if instanceType ~= "party" then
		return
	end

	-- Override the name, we don't want to use the local language versions (unless we can't find the name)
	local EN_name = DungeonTrackerGetDungeonName( instanceMapID )
	if EN_name ~= "Unknown" then
		name = EN_name
	end

	-- Check if we are in a new dungeon (this has the special handling of Scarlet Monastery)
	name = DungeonTrackerCheckChanged(name)
			
	-- See if we can reconnect to a pending run (this forgets the current run, which is probably in an unidentified SM wing)
	for i = 1, #Hardcore_Character.dt.pending do
		if( Hardcore_Character.dt.pending[i].name == name ) then
			Hardcore_Character.dt.current = Hardcore_Character.dt.pending[ i ]
			table.remove( Hardcore_Character.dt.pending, i )
			Hardcore:Debug( "Reconnected to pending run in " .. Hardcore_Character.dt.current.name )
			break
		end
	end
	
	-- If we don't have a current run at this point (reconnected or not), start a new run
	if not next(Hardcore_Character.dt.current) then
		DUNGEON_RUN = {}
		DUNGEON_RUN.name   		 = name
		DUNGEON_RUN.id   		 = instanceMapID
		DUNGEON_RUN.date   		 = date("%m/%d/%y %H:%M:%S")
		DUNGEON_RUN.time_inside  = 0
		DUNGEON_RUN.time_outside = 0
		DUNGEON_RUN.start		 = now
		DUNGEON_RUN.last_seen	 = now
		DUNGEON_RUN.last_pulse	 = 0
		DUNGEON_RUN.idle_left	 = 0			-- Remaining idle time
		DUNGEON_RUN.level		 = UnitLevel("player")
		local group_composition  = UnitName("player")
		if Hardcore_Character.dt.group_members ~= nil then
			for index, player in ipairs ( Hardcore_Character.dt.group_members ) do
				group_composition = group_composition .. "," .. player 
			end
		end
		DUNGEON_RUN.party = group_composition
		
		Hardcore_Character.dt.current = DUNGEON_RUN
		Hardcore:Debug( "Starting new run in " .. Hardcore_Character.dt.current.name )
	end

	-- Extend the current run (reconnected or new) by another time step and update the last_seen time
	Hardcore_Character.dt.current.time_inside  = Hardcore_Character.dt.current.time_inside + DT_TIME_STEP
	Hardcore_Character.dt.current.time_outside = 0			-- don't want to cumulate outside times
	Hardcore_Character.dt.current.last_seen    = now

	-- Send out pings to group members
	DungeonTrackerSendPulse( now )

	-- Warn the user if he is repeating this run or is overleveled
	DungeonTrackerWarnInfraction()
end

-- DungeonTrackerInitiate()
-- 
-- Function to get our timer going
-- Called from Hardcore.lua as follows:
--		DungeonTrackerInitiate(COMM_NAME, COMM_COMMANDS[15], COMM_COMMAND_DELIM, COMM_FIELD_DELIM )

function DungeonTrackerInitiate( comm_name, pulse_cmd, cmd_delim, field_delim )

	-- Copy over Hardcore.lua locals needed for communication
	COMM_NAME = comm_name
	DT_PULSE_COMMAND = pulse_cmd
	COMM_COMMAND_DELIM = cmd_delim
	COMM_FIELD_DELIM = field_delim

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
-- /hc AppealDungeonCode <hash> merge  <"dungeon name"> <"date"> <"dungeon name"> <"date">
--
-- This function uses a proprietory cryptographic hash (yes, I know I shouldn't)
-- different from djb2() in Hardcore.lua, because that one doesn't work for long strings

local function GetCryptoHash( str )

	local a = 0
	local b = 0
	local dictionary = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 /:"
	
	for i = 1, #str do
		x, y = string.find( dictionary, str:sub(i,i), 1, true )
		if x == nil then
			x = #dictionary
		end
		for i=1, 17 do
			a = (a * (-6) + b + 0x74FA - x) % 4096
			b = (math.floor(b / 3) + a + 0x81BE - x) % 4096
		end
	end
	return (a * 4096) + b
end

local function GetDungeonAppealCode( dungeon, date_str )
  local str = UnitName("player") .. UnitLevel("player") .. dungeon .. date_str
  return GetCryptoHash(str)
end

-- DungeonTrackerHandleAppealCode( args )
--
-- Called from Hardcore.lua when user types /hc AppealDungeonCode

function DungeonTrackerHandleAppealCode( args )

	local usage = "Usage: /hc AppealDungeonCode <code> <cmd> <args>\nwhere <cmd> = delete or reset"
	local usage1 = "/hc AppealDungeonCode <code> delete \"dungeon name\" \"date\""
	--local usage2 = "/hc AppealDungeonCode <code> merge  <\"dungeon name\"> <\"date\"> <\"dungeon name\"> <\"date\">"
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
		local appeal_code = GetDungeonAppealCode( "", "" )
		if tonumber( code ) ~= tonumber( appeal_code ) then
			Hardcore:Print("Incorrect code. Double check with a moderator." )
			return
		end
		Hardcore_Character.dt = nil
		Hardcore:Print("Dungeon log reset")
		return
	end
	
	-- Retrieve arguments in quotes, chuck away the code and command and space between
	for arg in args:gmatch('[^\"]+') do
		table.insert( quoted_args, arg )
	end
	table.remove( quoted_args, 1 )		-- Remove the code and command
	table.remove( quoted_args, 2 )		-- Remove the empty space
		
	if cmd == "delete" then
		if #quoted_args < 2 then
			Hardcore:Print("Wrong syntax: delete cmd should be followed by dungeon name and date string (both in quotes)" )
			Hardcore:Print(usage1)
			return
		else
			-- Look for the run with that dungeon and date
			local run_found = false
			local index = 0
			for i,v in ipairs( Hardcore_Character.dt.runs ) do
				if Hardcore_Character.dt.runs[ i ].name == quoted_args[1] and Hardcore_Character.dt.runs[ i ].date == quoted_args[2] then
					run_found = true
					index = i
				end					
			end
			
			-- If we find multiple matches, we don't do anything
			if run_found == true then
			
				-- Check if the hash code is correct
				local appeal_code = GetDungeonAppealCode( Hardcore_Character.dt.runs[ index ].name, Hardcore_Character.dt.runs[ index ].date )
				
				if tonumber( code ) ~= tonumber( appeal_code ) then
					Hardcore:Print("Incorrect code. Double check with a moderator." )
					return
				end								
				
				-- Delete the run
				Hardcore:Print("Removed dungeon run " .. Hardcore_Character.dt.runs[ index ].name .. " of " .. Hardcore_Character.dt.runs[ index ].date)
				table.remove( Hardcore_Character.dt.runs, index )
				DungeonTrackerUpdateInfractions()
				return
			else
				local message = "Dungeon run in " .. quoted_args[1]
				if #quoted_args == 2 then
					message = message .. " of " .. quoted_args[2]
				end
				Hardcore:Print( message .. " not found!" )
				return
			end
		end		
	elseif cmd == "merge" then
		Hardcore:Print("Merge command not yet implemented!" )
		return
	else
		Hardcore:Print("Unknown command: " .. cmd )
		Hardcore:Print(usage)
		return
	end

end

