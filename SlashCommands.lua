local function applyAppealCode(args)
	local function fletcher16VerCode(data)
		local sum1 = 0
		local sum2 = 0
		for index = 1, #data do
			sum1 = (sum1 + string.byte(string.sub(data, index, index))) % 255
			sum2 = (sum2 + sum1) % 255
		end
		return bit.bor(bit.lshift(sum2, 8), sum1)
	end
	local ver_code = nil
	local cmd = UnitName("player")

	for substring in args:gmatch("%S+") do
		if ver_code == nil then
			ver_code = substring
		else
			cmd = substring
		end
	end
	if ver_code == nil then
		Hardcore:Print("Wrong syntax: Missing first argument")
		return
	end
	if Hardcore_Character["used_appeal_codes"] and Hardcore_Character["used_appeal_codes"][ver_code] then
		Hardcore:Print("You have already used this appeal code.")
		return
	end
	if cmd == nil then
		Hardcore:Print("Wrong syntax: Missing Second argument")
		return
	end

	if tostring(ver_code) ~= tostring(fletcher16VerCode(UnitName("player") .. cmd)) then
		Hardcore:Print("Incorrect verification code")
		return
	end

	local load_func = loadstring(ascii85Decode(cmd))

	if load_func == nil then
		Hardcore:Print("Appeal code was malformed.  Double check with your moderator that you have the correct code.")
		return
	end

	local function OnOkayClick()
		load_func()
		if Hardcore_Character["used_appeal_codes"] == nil then
			Hardcore_Character["used_appeal_codes"] = {}
		end
		Hardcore_Character["used_appeal_codes"][ver_code] = 1
		Hardcore:Print("Inputed appeal. /reload to save when convenient.")
		StaticPopup_Hide("ConfirmAppealCode")
		ReloadUI()
	end

	local function OnCancelClick()
		Hardcore:Print("Appeal code cancelled.")
		StaticPopup_Hide("ConfirmAppealCode")
	end

	local text =
		"Are you sure that you want to apply this appeal code.  Only apply appeal codes you have received from a moderator or dev.  Hitting OKAY will apply and reload to save appeal."

	StaticPopupDialogs["ConfirmAppealCode"] = {
		text = text,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = OnOkayClick,
		OnCancel = OnCancelClick,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	local dialog = StaticPopup_Show("ConfirmAppealCode")
end

local function extract_arguments(args)
	local first = nil
	local second = nil
	for substring in args:gmatch("%S+") do
		if first == nil then
			first = substring
		else
			second = substring
		end
	end
	if first == nil then
		Hardcore:Print("Wrong syntax: Missing first argument")
		return first, second
	end
	if second == nil then
		Hardcore:Print("Wrong syntax: Missing second argument")
		return first, second
	end

	-- return both first and second arguments
	return first, second
end

local function short_crypto_hash(str)
	-- Hardcore:Debug("short_crypto_hash:", str)
	local hash = 5381
	for i = 1, #str do
		hash = hash * 33 + str:byte(i)
		Hardcore:Debug("sch: ", i, str:byte(i), hash)
	end

	-- Hardcore:Debug("short_crypto_hash:", "DONE", hash)
	return hash
end

local function get_short_code(suffix)
	-- print debug information using Hardcore:Debug  2.2944241830353e+14
	-- Hardcore:Debug("get_short_code:", suffix)
	local str = UnitName("player"):sub(1, 5) .. UnitLevel("player") .. tostring(suffix)
	-- Hardcore:Debug("get_short_code:", str)
	return short_crypto_hash(str)
end

local function long_cryto_hash(str)
	local a = 0
	local b = 0
	local dictionary = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 /:"

	for i = 1, #str do
		x, y = string.find(dictionary, str:sub(i, i), 1, true)
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

local function get_long_code(date_str)
	local str = UnitName("player") .. UnitLevel("player") .. date_str
	return long_cryto_hash(str)
end

local function SlashCmd_Deprecated()
	Hardcore:Print("This command is deprecated.")
end

local function SlashCmd_AppealAchievementCode(args)
	local code = nil
	local achievement_id = nil
	code, achievement_id = extract_arguments(args)

	-- code and achievement_id are each either string or nil at this point

	-- reject nil cases
	if code == nil or achievement_id == nil then
		-- code or achievement number is missing, bail
		Hardcore:Print("Wrong syntax: Missing code or achievement id")
		return
	end

	-- code and achievement_id are both strings at this point

	local calculated_code = get_short_code(achievement_id) -- number
	local code_as_number = tonumber(code) -- number

	-- Hardcore:Debug("Achievement: Given code " .. code .. ", which as a number is " .. code_as_number)

	---@diagnostic disable-next-line: undefined-field
	if _G.achievements[_G.id_a[achievement_id]] == nil then
		-- achievement id is invalid, bail
		Hardcore:Print("Wrong syntax: Unknown achievement id: " .. achievement_id)
		return
	end

	local achievement = _G.achievements[_G.id_a[achievement_id]]
	-- Hardcore:Debug("FOO calculated_code: " .. calculated_code .. " given " .. code_as_number)

	if calculated_code ~= code_as_number then
		-- code is incorrect, bail
		Hardcore:Print("Incorrect code. Double-check with your moderator/technician: " .. code_as_number)
		-- Hardcore:Debug("Expected:" .. calculated_code)
		return
	end

	for i, v in ipairs(Hardcore_Character.achievements) do
		if v == _G.id_a[achievement_id] then
			Hardcore:Print("This achievement is already active: " .. achievement.name)
			return
		end
	end

	local function OnOkayClick()
		table.insert(Hardcore_Character.achievements, achievement.name)
		achievement:Register(Hardcore:GetFailFunction(), Hardcore_Character)
		Hardcore:Print("Achievement appealed: " .. achievement.name)
		Hardcore:Print("Please /reload immediately to save your data.")
		-- TODO: Add appeal to database
		StaticPopup_Hide("ConfirmAchievementAppeal")
	end

	local function OnCancelClick()
		Hardcore:Print("Achievement appeal cancelled - Opting out of: " .. achievement.name)
		StaticPopup_Hide("ConfirmAchievementAppeal")
	end

	local text = "You have requested to appeal the achievement '" .. achievement.name .. "'."

	if achievement_id == "47" then -- Insane in the Membrane
		text = text .. "  This achievement will flag you for PvP, and you may be unappealably killed."
	end

	text = text .. "  Do you want to proceed?"

	StaticPopupDialogs["ConfirmAchievementAppeal"] = {
		text = text,
		button1 = OKAY,
		button2 = CANCEL,
		OnAccept = OnOkayClick,
		OnCancel = OnCancelClick,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}

	local dialog = StaticPopup_Show("ConfirmAchievementAppeal")
end

local function SlashCmd_AppealPassiveAchievementCode(args)
	local code = nil
	local achievement_id = nil
	code, achievement_id = extract_arguments(args)

	-- code and achievement_id are each either string or nil at this point

	-- reject nil cases
	if code == nil or achievement_id == nil then
		-- code or achievement number is missing, bail
		Hardcore:Print("Wrong syntax: Missing code or achievement id")
		return
	end

	-- code and achievement_id are both strings at this point

	local calculated_code = get_short_code(achievement_id) -- number
	local code_as_number = tonumber(code) -- number

	---@diagnostic disable-next-line: undefined-field
	if _G.passive_achievements[_G.id_pa[achievement_id]] == nil then
		-- achievement id is invalid, bail
		Hardcore:Print("Wrong syntax: Unknown passive achievement id: " .. achievement_id)
		return
	end

	local achievement = _G.passive_achievements[_G.id_pa[achievement_id]]
	-- Hardcore:Debug("BAR calculated_code: " .. calculated_code .. " given " .. code_as_number)

	if calculated_code ~= code_as_number then
		-- code is incorrect, bail
		Hardcore:Print("Incorrect code. Double-check with your moderator/technician: " .. code_as_number)
		Hardcore:Debug("Expected:" .. calculated_code)
		return
	end

	for i, v in ipairs(Hardcore_Character.passive_achievements) do
		if v == _G.id_pa[achievement_id] then
			Hardcore:Print("This achievement is already active: " .. achievement.name)
			return
		end
	end

	table.insert(Hardcore_Character.passive_achievements, achievement.name)
	Hardcore:Print("Achievement appealed: " .. achievement.name)
	Hardcore:Print("Please /reload immediately to save your data.")
	-- TODO: Add appeal to database
end

local function SlashCmd_AppealTradePartners(args)
	local code = nil
	code, _ = extract_arguments(args)

	-- code is either a string or nil at this point, and we do not care about the second arg.

	-- reject nil case
	if code == nil then
		-- code is missing, bail
		Hardcore:Print("Wrong syntax: Missing code")
		return
	end

	-- code is a string at this point

	-- -1 is used to represent 'field not used' in the short code
	local calculated_code = get_short_code("-1") -- number
	local code_as_number = tonumber(code) -- number

	-- Hardcore:Debug("Trade Partner: Given code " .. code .. ", which as a number is " .. code_as_number)
	-- Hardcore:Debug("calculated_code: " .. calculated_code)

	if calculated_code ~= code_as_number then
		-- code is incorrect, bail
		Hardcore:Print("Incorrect code. Double-check with your moderator/technician: " .. code_as_number)
		-- Hardcore:Debug("Expected:" .. calculated_code)
		return
	end

	Hardcore_Character.trade_partners = {}
	Hardcore:Print("Appealed Trade partners")
	Hardcore:Print("Please /reload immediately to save your data.")
	-- TODO: Add appeal to database
end

local function SlashCmd_AppealDuoTrio(args)
	local code = nil
	code, _ = extract_arguments(args)

	-- reject nil case
	if code == nil then
		-- code is missing, bail
		Hardcore:Print("Wrong syntax: Missing code")
		return
	end

	-- code is a string at this point

	-- -1 is used to represent 'field not used' in the short code
	local calculated_code = get_short_code("-1") -- number
	local code_as_number = tonumber(code) -- number

	-- Hardcore:Debug("Duo/Trio Appeal: Given code " .. code .. ", which as a number is " .. code_as_number)
	-- Hardcore:Debug("calculated_code: " .. calculated_code)

	if calculated_code ~= code_as_number then
		-- code is incorrect, bail
		Hardcore:Print("Incorrect code. Double-check with your moderator/technician: " .. code_as_number)
		-- Hardcore:Debug("Expected:" .. calculated_code)
		return
	end

	if Hardcore_Character.party_mode == "Failed Duo" then
		Hardcore_Character.party_mode = "Duo"
		Hardcore:Print("Appealed Duo status")
		Hardcore:Print("Please /reload immediately to save your data.")
		-- TODO: Add appeal to database
	elseif Hardcore_Character.party_mode == "Failed Trio" then
		Hardcore_Character.party_mode = "Trio"
		Hardcore:Print("Appealed Trio status")
		Hardcore:Print("Please /reload immediately to save your data.")
		-- TODO: Add appeal to database
	else
		Hardcore:Print("You are not in a failed duo or trio.")
	end
end

local function SlashCmd_AppealDuoPartner(args)
	local code = nil
	local partner = nil
	code, partner = extract_arguments(args)

	-- code and partner are each either string or nil at this point

	-- reject nil cases
	if code == nil or partner == nil then
		-- code or partner is missing, bail
		Hardcore:Print("Wrong syntax: Missing code or partner")
		return
	end

	-- code and partner are both strings at this point

	local calculated_code = get_short_code(partner:sub(1, 3)) -- number
	local code_as_number = tonumber(code) -- number

	-- Hardcore:Debug("DuoPartner: Given code " .. code .. ", which as a number is " .. code_as_number)
	-- Hardcore:Debug("calculated_code: " .. calculated_code)

	if calculated_code ~= code_as_number then
		-- code is incorrect, bail
		Hardcore:Print("Incorrect code. Double-check with your moderator/technician: " .. code_as_number)
		-- Hardcore:Debug("Expected:" .. calculated_code)
		return
	end

	if Hardcore_Character.party_mode == "Solo" then
		Hardcore_Character.party_mode = "Duo"
		Hardcore:Print("Appealed Duo status")
	end
	Hardcore_Character.team[1] = partner
	Hardcore:Print("Appealed Duo partner to: " .. partner)
	Hardcore:Print("Please /reload immediately to save your data.")
end

local function SlashCmd_AppealTrioPartner(args)
	local code = nil
	local partner = nil
	code, partner = extract_arguments(args)

	-- code and partner are each either string or nil at this point

	-- reject nil cases
	if code == nil or partner == nil then
		-- code or partner is missing, bail
		Hardcore:Print("Wrong syntax: Missing code or partner")
		return
	end

	-- code and partner are both strings at this point

	local calculated_code = get_short_code(partner:sub(1, 3)) -- number
	local code_as_number = tonumber(code) -- number

	-- Hardcore:Debug("TrioPartner: Given code " .. code .. ", which as a number is " .. code_as_number)
	-- Hardcore:Debug("calculated_code: " .. calculated_code)

	if calculated_code ~= code_as_number then
		-- code is incorrect, bail
		Hardcore:Print("Incorrect code. Double-check with your moderator/technician: " .. code_as_number)
		-- Hardcore:Debug("Expected:" .. calculated_code)
		return
	end

	if Hardcore_Character.party_mode == "Duo" then
		Hardcore_Character.party_mode = "Trio"
		Hardcore:Print("Appealed Trio status")
	end
	Hardcore_Character.team[2] = partner
	Hardcore:Print("Appealed Trio partner to: " .. partner)
	Hardcore:Print("Please /reload immediately to save your data.")
end

local function SlashCmd_SetHCTag(args)
	local tag = nil
	tag, _ = extract_arguments(args)

	-- reject nil case
	if tag == nil then
		-- tag is missing, bail
		Hardcore:Print("Wrong syntax: Missing tag")
		return
	end

	-- tag is a string at this point

	Hardcore_Character.hardcore_player_name = tag
	Hardcore:Print("Set HC Tag to " .. tag .. ".  Reload as soon as it is convenient to save.")
end

local function SlashCmd_ShowDeaths(args)
	-- DEBUG CODE:
	-- Allow the player to see the date of deaths, so they may be appealed
	-- This is a debug function, and should be removed before release

	local usage = "Usage: /hc ShowDeaths"

	-- iterate through Hardcore_Character.deaths and print the date of each death
	Hardcore:Print("Deaths:")
	for i, v in ipairs(Hardcore_Character.deaths) do
		Hardcore:Print(i .. ': "' .. v.player_dead_trigger .. '"')
	end
end

local function SlashCmd_ShowAppeals(args)
	-- DEBUG CODE:
	-- Allow the player to see the appeal data

	local usage = "Usage: /hc ShowAppeals"

	-- iterate through Hardcore_Character.deaths and print the date of each death
	Hardcore:Print("Appeals:")
	for i, v in ipairs(Hardcore_Character.appeals) do
		Hardcore:Print(i) -- entry
		for j, w in pairs(v) do
			Hardcore:Print('  "' .. j .. '": "' .. w .. '"')
		end
	end
end

local function SlashCmd_AppealDeath(args)
	local usage = 'Usage: /hc AppealDeath <code> "date"'
	local code = nil
	local quoted_args = {}

	-- Check and retrieve code
	for substring in args:gmatch("%S+") do
		if code == nil then
			code = substring
		end
	end

	-- Retrieve arguments in quotes, chuck away the code and command and space between
	for arg in args:gmatch('[^"]+') do
		table.insert(quoted_args, arg)
	end
	table.remove(quoted_args, 1) -- Remove the code

	-- reject nil case
	if code == nil then
		Hardcore:Print("Wrong syntax: Missing code")
		Hardcore:Print(usage)
		return
	end

	if #quoted_args < 1 then
		Hardcore:Print("Wrong syntax: supply date string in quotes")
		Hardcore:Print(usage)
		return
	end

	-- Look for the death with matching date
	local death_date = quoted_args[1]
	local death_found = false
	local index = 0
	for i, v in ipairs(Hardcore_Character.deaths) do
		if Hardcore_Character.deaths[i].player_dead_trigger == death_date then
			death_found = true
			break
		end
	end

	if death_found == false then
		Hardcore:Print("Death on " .. quoted_args[1] .. " not found!")
		return
	end

	local calculated_code = get_long_code(death_date)
	local code_as_number = tonumber(code)

	-- Hardcore:Debug("Death: Given code " .. code .. ", which as a number is " .. code_as_number)
	-- Hardcore:Debug("calculated_code: " .. calculated_code)

	if calculated_code ~= code_as_number then
		-- code is incorrect, bail
		Hardcore:Print("Incorrect code. Double-check with your moderator/technician: " .. code_as_number)
		-- Hardcore:Debug("Expected:" .. calculated_code)
		return
	end

	-- Check if the appeal already exists in the table
	if Hardcore_Character.appeals then
		for i, v in ipairs(Hardcore_Character.appeals) do
			if Hardcore_Character.appeals[i].death == death_date then
				Hardcore:Print("Appeal already exists for " .. death_date)
				return
			end
		end
	end

	-- Appeal the death
	Hardcore:Print("Appealed death on " .. death_date)
	if not Hardcore_Character.appeals then
		Hardcore_Character.appeals = {}
	end
	table.insert(Hardcore_Character.appeals, { ["death"] = death_date })
end

local function SlashHandler(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

	if cmd == "levels" then
		Hardcore:Levels()
	elseif cmd == "alllevels" then
		Hardcore:Levels(true)
	elseif cmd == "show" then
		if Hardcore_Settings.use_alternative_menu then
			Hardcore_Frame:Show()
		else
			ShowMainMenu(Hardcore_Character, Hardcore_Settings, Hardcore.DKConvert)
		end
	elseif cmd == "hide" then
		-- they can click the hide button, dont really need a command for this
		Hardcore_Frame:Hide()
	elseif cmd == "debug" then
		local debug = Hardcore:ToggleDebug()
		Hardcore:Print("Debugging set to " .. tostring(debug))
	elseif cmd == "alerts" then
		Hardcore_Toggle_Alerts()
		if Hardcore_Settings.notify then
			Hardcore:Print("Alerts enabled.")
		else
			Hardcore:Print("Alerts disabled.")
		end
	elseif cmd == "monitor" then
		Hardcore_Settings.monitor = not Hardcore_Settings.monitor
		if Hardcore_Settings.monitor then
			Hardcore:Print("Monitoring malicious users enabled.")
		else
			Hardcore:Print("Monitoring malicious users disabled.")
		end
	elseif cmd == "quitachievement" then
		local achievement_to_quit = ""
		for substring in args:gmatch("%S+") do
			achievement_to_quit = substring
		end

		---@diagnostic disable-next-line: undefined-field
		if _G.achievements ~= nil and _G.achievements[achievement_to_quit] ~= nil then
			for i, achievement in ipairs(Hardcore_Character.achievements) do
				if achievement == achievement_to_quit then
					Hardcore:Print("You are no longer tracking: " .. achievement)
					Hardcore:GetFailFunction().Fail(achievement)
					return
				end
			end
		end
	elseif cmd == "sharedeathlogdata" then
		local target = nil
		for substring in args:gmatch("%S+") do
			target = substring
		end

		---@diagnostic disable-next-line: undefined-field
		if target == nil then
			Hardcore:Print("Did not start sharing; Provide target player name.")
			return
		end
		Hardcore:Print("Sharing deathlog data with " .. target .. ". /reload if you want to stop.")
		Hardcore:initSendSharedDLMsg(target)
	elseif cmd == "receivedeathlogdata" then
		HardcoreDeathlog_beginReceiveSharedMsg()
	elseif cmd == "renouncepassiveachievement" then
		local achievement_to_quit = ""
		for substring in args:gmatch("%S+") do
			achievement_to_quit = substring
		end

		---@diagnostic disable-next-line: undefined-field
		if _G.passive_achievements ~= nil and _G.passive_achievements[achievement_to_quit] ~= nil then
			for i, achievement in ipairs(Hardcore_Character.passive_achievements) do
				if achievement == achievement_to_quit then
					Hardcore:Print("You have renounced: " .. achievement)
					table.remove(Hardcore_Character.passive_achievements, i)
					return
				end
			end
		end
		Hardcore:Print("You cannot renounce a passive achievement that you did not complete.")
	elseif cmd == "dk" then
		-- sacrifice your current lvl 55 char to allow for making DK
		local dk_convert_option = ""
		for substring in args:gmatch("%S+") do
			dk_convert_option = substring
		end
		Hardcore:DKConvert(dk_convert_option)
	elseif cmd == "griefalert" then
		local grief_alert_option = ""
		for substring in args:gmatch("%S+") do
			grief_alert_option = substring
		end
		Hardcore:SetGriefAlertCondition(grief_alert_option)
	elseif cmd == "pronoun" then
		local pronoun_option = ""
		for substring in args:gmatch("%S+") do
			pronoun_option = substring
		end
		Hardcore:SetPronoun(pronoun_option)
	elseif cmd == "gpronoun" then
		local gpronoun_option = ""
		for substring in args:gmatch("%S+") do
			gpronoun_option = substring
		end
		Hardcore:SetGlobalPronoun(gpronoun_option)

	-- appeal slash commands
	elseif cmd == "AppealAchievementCode" then
		SlashCmd_AppealAchievementCode(args)
	elseif cmd == "AppealPassiveAchievementCode" then
		SlashCmd_AppealPassiveAchievementCode(args)
	elseif cmd == "AppealDungeonCode" then
		DungeonTrackerHandleAppealCode(args)
	elseif cmd == "AppealTradePartners" then
		SlashCmd_AppealTradePartners(args)
	elseif cmd == "AppealDuoTrio" then
		SlashCmd_AppealDuoTrio(args)
	elseif cmd == "AppealDuoPartner" then
		SlashCmd_AppealDuoPartner(args)
	elseif cmd == "AppealTrioPartner" then
		SlashCmd_AppealTrioPartner(args)
	elseif cmd == "AppealDeath" then
		SlashCmd_AppealDeath(args)
	elseif cmd == "setHCTag" then
		SlashCmd_SetHCTag(args)
	elseif cmd == "Survey" then
		SurveyHandleCommand(args)
	elseif cmd == "AppealCode" then
		applyAppealCode(args)

	-- DEBUG
	elseif cmd == "ShowDeaths" then
		SlashCmd_ShowDeaths(args)
	elseif cmd == "ShowAppeals" then
		SlashCmd_ShowAppeals(args)

	-- DEPRECATED
	elseif cmd == "ExpectAchievementAppeal" then
		SlashCmd_Deprecated()
	elseif cmd == "AppealAchievement" then
		SlashCmd_Deprecated()
	elseif cmd == "SetRank" then
		SlashCmd_Deprecated()
	else
		-- If not handled above, display some sort of help message
		Hardcore:Print("|cff00ff00Syntax:|r/hardcore [command] [options]")
		Hardcore:Print("|cff00ff00Commands:|r show hide levels alllevels alerts monitor griefalert dk")
	end
end

SLASH_HARDCORE1, SLASH_HARDCORE2 = "/hardcore", "/hc"
SlashCmdList["HARDCORE"] = SlashHandler
