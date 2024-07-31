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
