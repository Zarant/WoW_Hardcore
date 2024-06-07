local _G = _G
local animal_friend_achievement = CreateFrame("Frame")
_G.achievements.AnimalFriend = animal_friend_achievement

animal_friend_achievement.cache = {}
-- General info
animal_friend_achievement.name = "AnimalFriend"
animal_friend_achievement.title = "Animal Friend"
animal_friend_achievement.class = "All"
animal_friend_achievement.pts = 15
animal_friend_achievement.bl_text = "Starting Achievement"
animal_friend_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_animal_friend.blp"
animal_friend_achievement.description =
	"Complete the Hardcore challenge without at any point killing an NPC of the type Beast. Killing is considered any action that gives your character kill credit (experience, eligibility to loot, or quest progress)."

-- Registers
function animal_friend_achievement:Register(fail_function_executor)
	animal_friend_achievement:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
	animal_friend_achievement:RegisterEvent("PLAYER_TARGET_CHANGED")
	animal_friend_achievement:RegisterEvent("PLAYER_LEAVE_COMBAT")
	animal_friend_achievement:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	animal_friend_achievement.fail_function_executor = fail_function_executor
end

function animal_friend_achievement:Unregister()
	animal_friend_achievement:UnregisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
	animal_friend_achievement:UnregisterEvent("PLAYER_TARGET_CHANGED")
	animal_friend_achievement:UnregisterEvent("PLAYER_LEAVE_COMBAT")
end

-- Register Definitions
animal_friend_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local creature_name = string.match(arg[1], "(.+) dies")
		if animal_friend_achievement.cache[creature_name] ~= nil then
			animal_friend_achievement.fail_function_executor.Fail(animal_friend_achievement.name)
		end
	elseif event == "PLAYER_TARGET_CHANGED" then
		if UnitCanAttack("player", "target") then
			if UnitCreatureType("target") == "Beast" then
				animal_friend_achievement.cache[UnitName("target")] = 1
			end
		end
	elseif event == "PLAYER_LEAVE_COMBAT" then
		animal_friend_achievement.cache = {}
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		local creature_name = UnitName("mouseover")
		local creature_type = UnitCreatureType("mouseover")
		if creature_name ~= nil and creature_type ~= nil then
			if creature_type == "Beast" then
				if UnitCanAttack("player", "mouseover") then
					animal_friend_achievement.cache[UnitName("mouseover")] = 1
				end
			end
		end
	end
end)
