local _G = _G
local _achievement = CreateFrame("Frame")
_G.passive_achievements.Tainted = _achievement

local dungeon_kill_trigger = {
	-- ["Test Dungeon"] = "Young Wolf",
	["Ragefire Chasm"] = "Bazzalan",
	["The Deadmines"] = "Edwin VanCleef",
	["Wailing Caverns"] = "Lord Serpentis",
	["Shadowfang Keep"] = "Archmage Arugal",
	["Blackfathon Deeps"] = "Aku'mai",
	["Stockades"] = "Dextren Ward",
	["Razorfin Kraul"] = "Charlga Razorflank",
	["Gnomeregan"] = "Mekgineer Thermaplugg",
	["Razorfen Downs"] = "Amnennar the Coldbringer",
	["Scarlet Monastery: Graveyard"] = "Bloodmage Thalnos",
	["Scarlet Monastery: Library"] = "Arcanist Doan",
	["Scarlet Monastery: Armory"] = "Herod",
	["Scarlet Monastery: Cathedral"] = "High Inquisitor Whitemane",
	["Uldaman"] = "Archaedas",
	["Zul'Farrak"] = "Sergeant Bly",
	["Maraudon"] = "Princess Theradras",
	["Sunken Temple"] = "Shade of Eranikus",
	["Blackrock Depths"] = "Princess Moira Bronzebeard",
	["Lower Blackrock Spire"] = "Overlord Wyrmthalak",
	["Upper Blackrock Spire"] = "General Drakkisath",
	["Scholomance"] = "Darkmaster Gandling",
	["Dire Maul: East"] = "Alzzin the Wildshaper",
	["Dire Maul: North"] = "Captain Kromcrush",
	["Dire Maul: West"] = "Prince Tortheldrin",
	["Stratholme: Live"] = "Balnazzar",
	["Stratholme: Undead"] = "Baron Rivendare",
}

-- General info
_achievement.name = "Tainted"
_achievement.title = "Tainted"
_achievement.class = "All"
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_tainted.blp"
_achievement.level_cap = 59
_achievement.kill_targets = {}
for i, v in pairs(dungeon_kill_trigger) do
	_achievement.kill_targets[v] = i
end
_achievement.category = "Dungeons"
_achievement.bl_text = "Dungeons"
_achievement.pts = 15
_achievement.description = "Complete 5 dungeons while solo before reaching level 60."
_achievement.restricted_game_versions = {
	["WotLK"] = 1,
}

-- Registers
function _achievement:Register(succeed_function_executor)
	_achievement.succeed_function_executor = succeed_function_executor
	passive_achievement_kill_handler:RegisterKillEvent(_achievement.name)
end

function _achievement:Unregister() end

function _achievement:HandleKillEvent(target_name, _hardcore_character)
	-- Handle kill event
	local num_members = GetNumGroupMembers()
	if num_members >= 2 then
		return
	end

	if _achievement.kill_targets[target_name] then
		if _hardcore_character.dungeon_kill_targets_solo == nil then
			_hardcore_character.dungeon_kill_targets_solo = {}
		end
		print("adding", target_name, _achievement.kill_targets[target_name])
		_hardcore_character.dungeon_kill_targets_solo[_achievement.kill_targets[target_name]] = target_name

		local completed_dungeons = 0
		for k, v in pairs(_achievement.kill_targets) do
			if _hardcore_character.dungeon_kill_targets_solo[v] ~= nil then
				completed_dungeons = completed_dungeons + 1
			end
		end

		if completed_dungeons > 4 then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end
