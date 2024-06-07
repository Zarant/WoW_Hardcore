local _G = _G
local heirloom_rules = CreateFrame("Frame")
_G.extra_rules.Heirlooms = heirloom_rules

-- General info
heirloom_rules.name = "Heirlooms"
heirloom_rules.title = "Heirlooms"
heirloom_rules.class = "All"
heirloom_rules.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_default.blp"
heirloom_rules.description = ""

-- Registers
function heirloom_rules:Register(fail_function_executor, _hardcore_character) 
	--print("Registering Heirloom Rules")
	heirloom_rules:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	heirloom_rules:RegisterEvent("PLAYER_LEVEL_UP")
	heirloom_rules:RegisterEvent("PLAYER_ENTER_COMBAT")
	heirloom_rules:RegisterEvent("PLAYER_ENTERING_WORLD")
	heirloom_rules:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	heirloom_rules.fail_function_executor = fail_function_executor
	heirloom_rules._hardcore_character_ref = _hardcore_character
end

function heirloom_rules:Unregister()
	--print("Unregistering Heirloom Rules")
	heirloom_rules:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	heirloom_rules:UnregisterEvent("PLAYER_LEVEL_UP")
	heirloom_rules:UnregisterEvent("PLAYER_ENTER_COMBAT")
	heirloom_rules:UnregisterEvent("PLAYER_ENTERING_WORLD")
	heirloom_rules:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- Register Definitions
heirloom_rules:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	--print("equipped item: " .. tostring(arg[1]) .. " " .. tostring(arg[2]))
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		if arg[1] > 1 and arg[1] < 16 then -- 1 ammo, 16+ weapons
			-- Equipped an item if true
			if arg[2] ~= true then
				-- Timed for accidental equips
				local item_id = GetInventoryItemID("player", arg[1])
				if item_id == nil then
					--Hardcore:Print("No item in slot " .. i)
				else
					local item_name, _, item_rarity, _, _, _, _, _, _, _, _ = GetItemInfo(item_id)
					--print(item_name, item_rarity)
					--Hardcore:Print("Equiped " .. item_name .. " with rarity " .. item_rarity)
					if item_rarity == 7 then -- 7: heirloom, 0: poor (gray), 1: common (white), 2: uncommon (green) ...
						
						Hardcore:Print("HEIRLOOMS ARE BANNED\nUnequip within 10 seconds or you will fail the challenge")
						Hardcore:ShowAlertFrame(Hardcore.ALERT_STYLES.hc_red, "HEIRLOOMS ARE BANNED\nUnequip within 10 seconds or you will fail the challenge")
						heirloom_rules:TimedHeirloomFailure()
					end
				end
			end
		end
	elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTER_COMBAT" or event == "UNIT_SPELLCAST_SUCCEEDED" then
		-- Instant when it can affect actual gameplay
		heirloom_rules:CheckHeirloomFailure()
	elseif event == "PLAYER_ENTERING_WORLD" then
		if heirloom_rules:HasHeirlooms() then
			-- Timed when entering the world, delay so they can hear the sound
			Hardcore:Print("HEIRLOOMS ARE BANNED\nUnequip within 10 seconds or you will fail the challenge")
			Hardcore:ShowAlertFrame(Hardcore.ALERT_STYLES.hc_red, "HEIRLOOMS ARE BANNED\nUnequip within 10 seconds or you will fail the challenge")						
			C_Timer.After(0, function() heirloom_rules:TimedHeirloomFailure() end)
		end
	end
end)

function heirloom_rules:HasHeirlooms()
	-- print("Heirloom scanning...")
	for i = 2, 15 do
		local item_id = GetInventoryItemID("player", i)
		--print(item_id)
		if item_id == nil then
			--Hardcore:Print("No item in slot " .. i)
		else
			local item_name, _, item_rarity, _, _, _, _, _, _, _, _ = GetItemInfo(item_id)
			--print(item_name, item_rarity)
			if item_rarity == 7 then -- 7: heirloom, 0: poor (gray), 1: common (white), 2: uncommon (green) ...
				-- Hardcore:Print("Equiped " .. item_name .. " with rarity " .. item_rarity)
				-- white_knight_achievement.fail_function_executor.Fail(white_knight_achievement.name)
				
				--print("BUSTED")
				return true
			end
		end
	end
	return false
end

function heirloom_rules:CheckHeirloomFailure()
	--print("Checking Heirloom Failure")

	if heirloom_rules:HasHeirlooms() then
		--print("FAILED")
		heirloom_rules.fail_function_executor.Fail(heirloom_rules.name)
		table.insert(Hardcore_Character.trade_partners, "HEIRLOOM")
		Hardcore:Print("Failed due to equipping an Heirloom")
		Hardcore:ShowAlertFrame(Hardcore.ALERT_STYLES.hc_red, "HEIRLOOMS ARE BANNED\nYou equipped an Heirloom and failed the challenge!")
		PlaySoundFile("Interface\\Addons\\Hardcore\\Media\\achievement_failure.ogg")
		local level = UnitLevel("player")
		local mapID
		local deathData = string.format("%s%s%s", level, COMM_FIELD_DELIM, mapID and mapID or "")
		local commMessage = COMM_COMMANDS[3] .. COMM_COMMAND_DELIM .. deathData

		local messageString = UnitName("player") .. " has equipped an Heirloom and failed the challenge!"
		SendChatMessage(messageString, "GUILD")
		startXGuildChatMsgRelay(messageString)
		startXGuildDeathMsgRelay()
		if CTL then
			CTL:SendAddonMessage("ALERT", COMM_NAME, commMessage, "GUILD")
		end
	end
end

function heirloom_rules:TimedHeirloomFailure()
	-- Check after 10 seconds if they still have items equipped
	C_Timer.After(10, function() heirloom_rules:CheckHeirloomFailure() end)
end
