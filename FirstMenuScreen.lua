local achievement_icons = {}
local CLASSES = {
	-- Classic:
	[1] = "Warrior",
	[2] = "Paladin",
	[3] = "Hunter",
	[4] = "Rogue",
	[5] = "Priest",
	[6] = "Death Knight",
	[7] = "Shaman",
	[8] = "Mage",
	[9] = "Warlock",
	[11] = "Druid",
}

local function FormatStrForParty(input_str)
	local ouput_str = string.lower(input_str)
	output_str = ouput_str:gsub("^%l", string.upper)
	return output_str
end

function ShowFirstMenu(_hardcore_character, _hardcore_settings, _failure_function_executor)
	local AceGUI = LibStub("AceGUI-3.0")
	local f = AceGUI:Create("HardcoreFrame")
	f:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
	end)
	f:SetTitle("Classic Hardcore")
	f:SetStatusText("")
	f:SetWidth(900)
	f:SetHeight(600)
	f:SetLayout("Flow")

	local function DrawGeneralTab(container)
		local scroll_container = AceGUI:Create("SimpleGroup")
		scroll_container:SetFullWidth(true)
		scroll_container:SetFullHeight(true)
		scroll_container:SetLayout("Fill")
		tabcontainer:AddChild(scroll_container)

		local scroll_frame = AceGUI:Create("ScrollFrame")
		scroll_frame:SetLayout("Flow")
		scroll_container:AddChild(scroll_frame)

		local first_menu_description_title = AceGUI:Create("Label")
		first_menu_description_title:SetFullWidth(1)
		first_menu_description_title:SetText("Welcome to Classic hardcore!")
		first_menu_description_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
		-- first_menu_description_title:SetPoint("TOP", 2,5)
		scroll_frame:AddChild(first_menu_description_title)

		local first_menu_description = AceGUI:Create("Label")
		first_menu_description:SetFullWidth(1)
		first_menu_description:SetText(
			"\n\nIf playing in a duo or trio, click the `Party` tab.\n\n" .. 
			"To select achievements, click on an icon in the achievement tab.\n\n" .. 
			"At any point during the run, open the HC tab on the character screen to check party status and achievements.\n\n" ..
			"This window will not appear past level 2 and configuration cannot be changed later so make sure to fill these out correctly." ..
			"\n\n\n"
		)
		first_menu_description:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		scroll_frame:AddChild(first_menu_description)

		-- ToS-style "I Agree"
		local second_menu_description_title = AceGUI:Create("Label")
		second_menu_description_title:SetFullWidth(1)
		second_menu_description_title:SetText("The Hardcore Contract")
		second_menu_description_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
		scroll_frame:AddChild(second_menu_description_title)

		local second_menu_description_subtitle = AceGUI:Create("Label")
		second_menu_description_subtitle:SetFullWidth(1)
		second_menu_description_subtitle:SetText("Join the Discord!")
		second_menu_description_subtitle:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16, "")
		scroll_frame:AddChild(second_menu_description_subtitle)

		local second_menu_description = AceGUI:Create("Label")
		second_menu_description:SetFullWidth(1)
		second_menu_description:SetText(
			"\n\n" .. 
			"By clicking the button below, you agree to the following statements:\n\n" .. 
			"+ \"I have read the rules (#hardcore-rules, Discord)\"\n\n" .. 
			"+ \"I have read the FAQ (#faq, Discord)\"\n\n" .. 
			"+ \"I understand that disconnect appeal approval requires video of both pre-disconnect activity and the reconnect/login process,\"\n\n" ..
			"+ \"I accept responsibility for /reloading regularly and logging out cleanly to protect my data,\"\n\n" .. 
			"+ \"I understand that buffing a PvP-flagged player will cause me to become PvP-flagged, and I may die,\"\n\n" .. 
			"+ \"I understand that my presence in official guilds is subject to the Discord and Guild Rules (#getting-started, Discord)\"\n\n" ..  
			"+ \"I understand that non-Classic HC affiliated guilds do not follow our standards, and thus are at your own risk.\"\n\n" .. 
			""
		)
		second_menu_description:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		-- first_menu_description:SetPoint("TOP", 2,5)
		scroll_frame:AddChild(second_menu_description)
	end


	local function DrawPartyTab(container, _scroll_frame)
		local title = AceGUI:Create("Label")
		title:SetWidth(700)
		title:SetHeight(60)
		title:SetText("Rules for Duos and Trios\n\n")
		title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
		_scroll_frame:AddChild(title)

		local first_menu_description = AceGUI:Create("Label")
		first_menu_description:SetWidth(620)
		first_menu_description:SetText(
			"1. For new runs, all players need to start with the new Hardcore addon.\n2. You must choose a combo that spawns in the same starting location (unless you can find a way to travel to other players at level 1).\n3. You must stay in the same zone together eg Darkshore (unless you are a Druid going to Moonglade to complete essential class quests). \n4. You must be logged on together at the same time even if not questing.\n5. You are Soulbound and share one life. If one of you dies, the other/s must fall on the sword and the run is over.\n6. You can trade any solo self found items or crafted items to each other including conjurables and gold.\n\n\n\n\n"
		)
		first_menu_description:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		first_menu_description:SetPoint("TOP", 2, 5)
		_scroll_frame:AddChild(first_menu_description)

		local row_container = AceGUI:Create("SimpleGroup")
		row_container:SetWidth(800)
		row_container:SetHeight(60)
		row_container:SetLayout("Flow")
		_scroll_frame:AddChild(row_container)

		local first_menu_description = AceGUI:Create("Label")
		first_menu_description:SetWidth(300)
		first_menu_description:SetText("Enter your party mode and partners.\n")
		first_menu_description:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		first_menu_description:SetPoint("TOP", 2, 5)
		row_container:AddChild(first_menu_description)

		local dropdown = AceGUI:Create("Dropdown")
		dropdown:SetWidth(80)
		dropdown:SetLabel("Party type\n")
		dropdown:AddItem("Solo", "Solo")
		dropdown:AddItem("Duo", "Duo")
		dropdown:AddItem("Trio", "Trio")
		dropdown:SetValue(_hardcore_character.party_mode)
		dropdown:SetPoint("TOP", 2, 5)
		row_container:AddChild(dropdown)

		local tm1 = AceGUI:Create("EditBox")
		tm1:SetWidth(120)
		tm1:SetDisabled(true)
		tm1:SetLabel("Teammate 1\n")
		tm1:SetPoint("TOP", 2, 5)
		if _hardcore_character.team ~= nil then
			if _hardcore_character.team[1] ~= nil then
				tm1:SetText(_hardcore_character.team[1])
			end
		end
		tm1:SetPoint("TOP", 2, 5)
		tm1:DisableButton(true)
		row_container:AddChild(tm1)

		local tm2 = AceGUI:Create("EditBox")
		tm2:SetWidth(120)
		tm2:SetDisabled(true)
		tm2:SetLabel("Teammate 2\n")
		tm2:SetPoint("TOP", 2, 5)
		if _hardcore_character.team ~= nil then
			if _hardcore_character.team[2] ~= nil then
				tm2:SetText(_hardcore_character.team[2])
			end
		end
		tm2:DisableButton(true)
		row_container:AddChild(tm2)

		dropdown:SetCallback("OnValueChanged", function(args)
			local new_mode = dropdown:GetValue()
			tm1:SetText("")
			tm2:SetText("")
			_hardcore_character.party_mode = new_mode
			_hardcore_character.team = {}
			if new_mode == "Solo" then
				tm1:SetDisabled(true)
				tm2:SetDisabled(true)
			elseif new_mode == "Duo" then
				tm1:SetDisabled(false)
				tm2:SetDisabled(true)
			elseif new_mode == "Trio" then
				tm1:SetDisabled(false)
				tm2:SetDisabled(false)
			end
		end)
		tm1:SetCallback("OnTextChanged", function()
			_hardcore_character.team = {}
			table.insert(_hardcore_character.team, FormatStrForParty(tm1:GetText()))
			table.insert(_hardcore_character.team, FormatStrForParty(tm2:GetText()))
		end)

		tm2:SetCallback("OnTextChanged", function()
			_hardcore_character.team = {}
			table.insert(_hardcore_character.team, FormatStrForParty(tm1:GetText()))
			table.insert(_hardcore_character.team, FormatStrForParty(tm2:GetText()))
		end)
	end

	tabcontainer = AceGUI:Create("TabGroup") -- "InlineGroup" is also good
	tabcontainer:SetTabs({
		{ value = "WelcomeTab", text = "General" },
		{ value = "PartyTab", text = "Party" },
		{ value = "AchievementsTab", text = "Achievements" },
	}) -- ,
	tabcontainer:SetFullWidth(true)
	tabcontainer:SetFullHeight(true) -- probably?
	tabcontainer:SetLayout("Flow") -- important!

	-- Callback function for OnGroupSelected
	local function SelectGroup(container, event, group)
		container:ReleaseChildren()
		if group == "WelcomeTab" then
			DrawGeneralTab(container)
		elseif group == "PartyTab" then
			local scroll_container = AceGUI:Create("SimpleGroup")
			scroll_container:SetFullWidth(true)
			scroll_container:SetFullHeight(true)
			scroll_container:SetLayout("Fill")
			tabcontainer:AddChild(scroll_container)

			local scroll_frame = AceGUI:Create("ScrollFrame")
			scroll_frame:SetLayout("Flow")
			scroll_container:AddChild(scroll_frame)

			DrawPartyTab(container, scroll_frame)
		elseif group == "AchievementsTab" then
			achievement_tab_handler:DrawAchievementTab(tabcontainer, _hardcore_character, true, _failure_function_executor)
		end
	end

	tabcontainer:SetCallback("OnGroupSelected", SelectGroup)
	tabcontainer:SelectTab("WelcomeTab")

	f:AddChild(tabcontainer)
	f:SetCallback("OnClose", function()
		local party_modes = {
			"Solo",
			"Duo",
			"Trio",
		}
		for i, mode in ipairs(party_modes) do
			if _G.extra_rules[mode] ~= nil then
				_G.extra_rules[mode]:Unregister()
			end
		end
		if _G.extra_rules[_hardcore_character.party_mode] ~= nil then
			_G.extra_rules[_hardcore_character.party_mode]:Register(_, _hardcore_character, _hardcore_settings)
		end
	end)
end
