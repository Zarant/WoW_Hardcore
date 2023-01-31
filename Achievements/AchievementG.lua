local _G = _G
_G.achievements = {}
_G.achievements_order = {}
_G.extra_rules = {}
_G.a_id = {
	AnimalFriend = 1,
	Arcanist = 2,
	Berserker = 3,
	Bloodbath = 4,
	CloseCombat = 5,
	Cyromancer = 6,
	DruidOfTheClaw = 7,
	Ephemeral = 8,
	Felfire = 9,
	Grounded = 10,
	Hammertime = 11,
	Homebound = 12,
	Humanist = 13,
	ICanSeeYou = 14,
	ImpMaster = 15,
	KingOfTheJungle = 16,
	LoneWolf = 17,
	MortalPet = 18,
	Naturalist = 19,
	NobodyGotTimeForThat = 20,
	NoHealthPotions = 21,
	NotSoDeadly = 22,
	NotSoTalented = 23,
	NotTheBlessedRun = 24,
	NoWayOut = 25,
	Nudist = 26,
	Pacifist = 27,
	PowerFromWithin = 28,
	Pyromancer = 29,
	SelfMade = 30,
	ShadowEmbrace = 31,
	Shivved = 32,
	Shocked = 33,
	SolitaryStruggle = 34,
	Speedrunner = 35,
	SwordAndBoard = 36,
	Thunderstruck = 37,
	TiedHands = 38,
	TotemicMisery = 39,
	TrueBeliever = 40,
	TunnelVision = 41,
	Unrestored = 42,
	Vagrant = 43,
	VoidServant = 44,
	WhiteKnight = 45,
	Scavenger = 46,
	InsaneInTheMembrane = 47,
	PartnerUp = 48,
	NoHit = 49,
	DuoMade = 50,
	TrioMade = 51,	
}
_G.id_a = {}
for k, v in pairs(_G.a_id) do
	_G.id_a[tostring(v)] = k
end

for k in pairs(_G.a_id) do
	table.insert(_G.achievements_order, k)
end
table.sort(_G.achievements_order)

_G.passive_achievements = {}
_G.passive_achievements_order = {}
_G.pa_id = {
	KingOfTheJungle = 1,
	ShyRotam = 2,
	OfForgottenMemories = 3,
	Maltorious = 4,
	PawnCapturesQueen = 5,
	Deathclasp = 6,
	AFinalBlow = 7,
	SummoningThePrincess = 8,
	AbsentMindedProspector = 9,
	TheHuntCompleted = 10,
	MageSummoner = 11,
	EarthenArise = 12,
	GetMeOutOfHere = 13,
	RitesOfTheEarthmother = 14,
	KimjaelIndeed = 15,
	Counterattack = 16,
	StinkysEscape = 17,
	DarkHeart = 18,
	AgainstLordShalzaru = 19,
	TestOfEndurance = 20,
	CuergosGold = 21,
	TheStonesThatBindUs = 22,
	GalensEscape = 23,
	Morladim = 24,
	TheForgottenHeirloom = 25,
	Hogger = 26,
	Fangore = 27,
	DragonkinMenace = 28,
	SealOfEarth = 29,
	TremorsOfEarth = 30,
	Vagash = 31,
	InDefenseOfTheKing = 32,
	DefeatNekrosh = 33,
	DruidOfTheClawQuest = 34,
	TheCrownOfWill = 35,
	BattleOfHillsbrad = 36,
	TheWeaver = 37,
	TheFamilyCrypt = 38,
	HintsOfANewPlague = 39,
	RecoverTheKey = 40,
	HighChiefWinterfall = 41,
	TidalCharmAcquired = 42,
	MasterLeatherworker = 43,
	MasterBlacksmith = 44,
	MasterAlchemist = 45,
	MasterEnchanter = 46,
	MasterTailoring = 47,
	MasterEngineering = 48,
	MasterSkinner = 49,
	MasterMiner = 50,
	MasterHerbalism = 51,
	MasterFishing = 52,
	MasterCooking = 53,
	MasterFirstAid = 54,
	Tainted = 55,
	TheDungeonCrawler = 56,
	SpeedrunnerFifteen = 57,
	SpeedrunnerThirty = 58,
	SpeedrunnerFortyFive = 59,
	SpeedrunnerSixty = 60,
	BurningShadows = 61,
	SpeedrunnerTen = 62,
	SpeedrunnerTwenty = 63,
	SpeedrunnerForty = 64,
	SpeedrunnerFifty = 65,
	Kromgrul = 66,
	NothingButTheTruth = 67,
}
_G.id_pa = {}
for k, v in pairs(_G.pa_id) do
	_G.id_pa[tostring(v)] = k
end

for k in pairs(_G.pa_id) do
	table.insert(_G.passive_achievements_order, k)
end

-- sort function from stack overflow
local function spairs(t, order)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	if order then
		table.sort(keys, function(a, b)
			return order(t, a, b)
		end)
	else
		table.sort(keys)
	end

	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

local sort_functions = {
	["Level"] = function(t, a, b)
		if _G.passive_achievements[t[a]] and _G.passive_achievements[t[b]] then
			return _G.passive_achievements[t[a]].level_cap < _G.passive_achievements[t[b]].level_cap
		end
		if _G.passive_achievements[t[a]] and _G.passive_achievements[t[b]] == nil then
		  return true
		end
		if _G.passive_achievements[t[a]] == nil and _G.passive_achievements[t[b]] then
		  return false
		end
	end,
}

local kill_list_dict = {}

function reorderPassiveAchievements()
  local order = {}
  for i, v in spairs(_G.passive_achievements_order, sort_functions["Level"]) do
	if _G.passive_achievements[v] then
	  table.insert(order, v)
	  if _G.passive_achievements[v].kill_target then
	    kill_list_dict[_G.passive_achievements[v].kill_target] = v
	  end

	  if _G.passive_achievements[v].kill_targets then
	    for target, _ in pairs(_G.passive_achievements[v].kill_targets) do
	      kill_list_dict[target] = v
	    end
	  end
	end
  end
  _G.passive_achievements_order = order
end

other_hardcore_character_cache = {} -- dict of player name & server to character data

function HCGeneratePassiveAchievementCraftedDescription(set_name, level_cap, faction)
	local faction_info = "" 
	if faction then
	  if faction == "Horde" then
	    faction_info = "\r|cff8c1616Horde Only|r"
	  elseif faction == "Alliance" then
	    faction_info = "\r|cff004a93Alliance Only|r"
	  end
	end
	return "Complete the Hardcore challenge after crafting " .. set_name .. " before reaching level " .. level_cap + 1 .. faction_info
end

function HCGeneratePassiveAchievementItemAcquiredDescription(item, rarity, level_cap, faction)
	local faction_info = "" 
	if faction then
	  if faction == "Horde" then
	    faction_info = "\r|cff8c1616Horde Only|r"
	  elseif faction == "Alliance" then
	    faction_info = "\r|cff004a93Alliance Only|r"
	  end
	end
	return "Complete the Hardcore challenge after acquiring |cff00FF00[" .. item .. "]|r before reaching level " .. level_cap + 1 .. faction_info
end

function HCGeneratePassiveAchievementBasicQuestDescription(quest_name, zone, level_cap, faction)
	local faction_info = "" 
	if faction then
	  if faction == "Horde" then
	    faction_info = "\r|cff8c1616Horde Only|r"
	  elseif faction == "Alliance" then
	    faction_info = "\r|cff004a93Alliance Only|r"
	  end
	end
	return "Complete the Hardcore challenge after having completed the |cffffff00" .. quest_name .. "|r quest before reaching level " .. level_cap + 1 .. ".\n" .. faction_info
end

function HCGeneratePassiveAchievementKillDescription(kill_target, quest_name, zone, level_cap, faction)
	local faction_info = "" 
	if faction then
	  if faction == "Horde" then
	    faction_info = "\r|cff8c1616Horde Only|r"
	  elseif faction == "Alliance" then
	    faction_info = "\r|cff004a93Alliance Only|r"
	  end
	end
	return "Complete the Hardcore challenge after killing |cffFFB9AA" .. kill_target .. "|r and having completed the |cffffff00" .. quest_name .. "|r quest before reaching level " .. level_cap + 1 .. ".\n" .. faction_info
end

function HCGeneratePassiveAchievementProfLevelDescription(profession_name, profession_threshold, level_cap)
	return "Complete the Hardcore challenge after reaching |cff00FF00" .. profession_threshold .. "|r in " .. profession_name .. " before reaching level " .. level_cap + 1 .. "."
end

passive_achievement_kill_handler = CreateFrame("Frame") 
passive_achievement_kill_handler:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")

local registered_kill_event_achievements = {}
function passive_achievement_kill_handler:RegisterKillEvent(achievement_name)
  if _G.passive_achievements[achievement_name] then
    registered_kill_event_achievements[achievement_name] = _G.passive_achievements[achievement_name]
  end
end

passive_achievement_kill_handler:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local combat_log_payload = { CombatLogGetCurrentEventInfo() }
		local v = arg[1]:match("(.+) dies")
		if kill_list_dict[v] then
		  if Hardcore_Character then
		    if Hardcore_Character.kill_list_dict == nil then
		      Hardcore_Character.kill_list_dict = {}
		    end

		    if Hardcore_Character.kill_list_dict[v] == nil then
		      if _G.passive_achievements[kill_list_dict[v]] then
			Hardcore:Print("[" .. _G.passive_achievements[kill_list_dict[v]].title .. "] You have slain " .. v .. "!  Remember to /reload when convenient to save your progress.")
		      end
		      for _, registered_kill_event_achievement in pairs(registered_kill_event_achievements) do
				registered_kill_event_achievement:HandleKillEvent(v, Hardcore_Character)
		      end
		    end
		    Hardcore_Character.kill_list_dict[v] = 1
		  end
		end
	end
end)

function HCCommonPassiveAchievementAltBasicQuestCheck(_achievement, _event, _args)
	if _event == "QUEST_TURNED_IN" then
		if _args[1] ~= nil and (_args[1] == _achievement.quest_num or _args[1] == _achievement.quest_num_alt) and (UnitLevel("player") <= _achievement.level_cap or (hc_recent_level_up and UnitLevel("player") <= _achievement.level_cap + 1)) then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end

function HCCommonPassiveAchievementBasicQuestCheck(_achievement, _event, _args)
	if _event == "QUEST_TURNED_IN" then
		if _args[1] == _achievement.quest_num and (UnitLevel("player") <= _achievement.level_cap or (hc_recent_level_up and UnitLevel("player") <= _achievement.level_cap + 1)) then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end

function HCCommonPassiveAchievementKillCheck(_achievement, _event, _args)
	if _event == "QUEST_TURNED_IN" then
		if _args[1] == _achievement.quest_num and (UnitLevel("player") <= _achievement.level_cap or (hc_recent_level_up and UnitLevel("player") <= _achievement.level_cap + 1)) then
			if Hardcore_Character.kill_list_dict ~= nil and Hardcore_Character.kill_list_dict[_achievement.kill_target] then
				_achievement.succeed_function_executor.Succeed(_achievement.name)
			else
				Hardcore:Print("[" .. _achievement.title .. "] You have completed the " .. _achievement.quest_name .. " quest, but " .. _achievement.kill_target .. " was not slain!")
			end
		end
	end
end

function HCCommonPassiveAchievementItemAcquiredCheck(_achievement, _event, _args)
	if _achievement.item == nil then Hardcore:Print("Achievement doesn't have a specified item") end
	if _event == "CHAT_MSG_LOOT" then
		if string.match(_args[1], _achievement.item) and UnitLevel("player") <= _achievement.level_cap then
			_achievement.succeed_function_executor.Succeed(_achievement.name)
		end
	end
end

function HCCommonPassiveAchievementCraftedCheck(_achievement, _event, _args)
	if _achievement.craft_set == nil then Hardcore:Print("Achievement doesn't have a specified item") end
	if _event == "CHAT_MSG_LOOT" then
		for k, _ in pairs(_achievement.craft_set) do
			if string.match(_args[1], k) and string.match(_args[1], "You create") and UnitLevel("player") <= _achievement.level_cap then
				if Hardcore_Character then
				  if Hardcore_Character.crafted_list_dict == nil then
				    Hardcore_Character.crafted_list_dict = {}
				  end

				  Hardcore_Character.crafted_list_dict[k] = 1
				  for craft_item, _ in pairs(_achievement.craft_set) do
					if Hardcore_Character.crafted_list_dict[craft_item] == nil then
					  Hardcore:Print("[" .. _achievement.title .. "] You have crafted " .. k .. "!  Remember to /reload when convenient to save your progress.")
					  return
					end
				  end
				  _achievement.succeed_function_executor.Succeed(_achievement.name)
				end
			end
		end
	end
end

function HCCommonPassiveAchievementProfLevelCheck(_achievement, _event, _args)
	if _achievement.level_cap and UnitLevel("player") > _achievement.level_cap then return end
	if _event == "SKILL_LINES_CHANGED" or _event == "PLAYER_ENTERING_WORLD" then
		for i = 1, GetNumSkillLines() do
			local arg, _, _, lvl = GetSkillLineInfo(i)
			if arg == _achievement.profession_name then
				  if lvl >= _achievement.profession_threshold then
					  _achievement.succeed_function_executor.Succeed(_achievement.name)
				  end
			end
		end
	end
end

function CalculateHCAchievementPts(_hardcore_character)
  local pts = 0
  for _,achievement in ipairs(_hardcore_character.achievements) do
    if _G.achievements[achievement] and _G.achievements[achievement].pts then
      pts = pts +_G.achievements[achievement].pts 
    end
  end
  for _,achievement in ipairs(_hardcore_character.passive_achievements) do
    if _G.passive_achievements[achievement] and _G.passive_achievements[achievement].pts then
      pts = pts +_G.passive_achievements[achievement].pts 
    end
  end
  return pts
end

function SetAchievementTooltip(achievement_icon, achievement, _player_name)
				achievement_icon:SetCallback("OnEnter", function(widget)
					if UnitName("player") == _player_name and achievement.UpdateDescription then achievement:UpdateDescription() end
					GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
					GameTooltip:AddLine(achievement.title)
					GameTooltip:AddLine(achievement.description, 1, 1, 1, true)
					GameTooltip:AddDoubleLine(achievement.bl_text or "Starting Achievement", (achievement.pts or tostring(0)) .. "pts", 1, .82, 0, 1 ,.82, 0);
					GameTooltip:Show()
				end)
				achievement_icon:SetCallback("OnLeave", function(widget)
					GameTooltip:Hide()
				end)
  end

-- function SetAchievementTooltipB(_tooltip, achievement)
-- 					-- _tooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
-- 					_tooltip:AddLine(achievement.title)
-- 					_tooltip:AddLine(achievement.description, 1, 1, 1, true)
-- 					_tooltip:AddDoubleLine(achievement.bl_text or "Starting Achievement", (achievement.pts or tostring(0)) .. "pts", 1, .82, 0, 1 ,.82, 0);
--   end
