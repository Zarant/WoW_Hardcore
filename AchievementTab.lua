local achievement_icons = {}
local exclude_horde = false
local exclude_alliance = false
local row_form = false
local AceGUI = LibStub("AceGUI-3.0")
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

achievement_tab_handler = {}

local function DrawPassiveAchievementRow(achievement, _scroll_frame)
	local btn_container = AceGUI:Create("SimpleGroup")
	btn_container:SetWidth(800)
	btn_container:SetHeight(60)
	btn_container:SetLayout("Flow")
	_scroll_frame:AddChild(btn_container)

	btn_container_frame = AceGUI:Create("SimpleGroup")
	btn_container_frame:SetLayout("Flow")

	-- Create a button
	local achievement_icon = AceGUI:Create("Icon")
	achievement_icons[achievement.name] = achievement_icon
	achievement_icon:SetWidth(60)
	achievement_icon:SetHeight(60)
	achievement_icon:SetImage(achievement.icon_path)
	achievement_icon:SetImageSize(52, 52)
	achievement_icon.image:SetVertexColor(1, 1, 1)
	btn_container:AddChild(achievement_icon)

	-- achievement_icon:SetCallback("OnClick", function()
	--   local link = "[".. achievement.name .."]"
	--   ChatEdit_InsertLink(link)
	-- end)

	local buffer_frame = AceGUI:Create("SimpleGroup")
	buffer_frame:SetWidth(30)
	buffer_frame:SetHeight(30)
	buffer_frame:SetLayout("Flow")
	btn_container:AddChild(buffer_frame)

	local btn_container_frame = AceGUI:Create("SimpleGroup")
	btn_container_frame:SetLayout("Flow")
	btn_container:AddChild(btn_container_frame)

	local title = AceGUI:Create("Label")
	title:SetWidth(550)
	title:SetText(achievement.title)
	title:SetPoint("TOP", 2, 5)
	title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
	btn_container_frame:AddChild(title)

	local description = AceGUI:Create("InteractiveLabel")
	description:SetWidth(520)
	description:SetFont("", 16, "")
	local description_text = achievement.description
	if achievement.forces ~= nil then
		description_text = description_text .. "\n |c00FFFF00Selecting " .. achievement.title .. " forces "
		for i = 1, #achievement.forces do
			if i == #achievement.forces and #achievement.forces > 1 then
				description_text = description_text .. "and "
			end
			description_text = description_text .. _G.achievements[achievement.forces[i]].title
			if i ~= #achievement.forces then
				description_text = description_text .. ", "
			end
		end
		description_text = description_text .. ".|r"
	end

	if
		achievement.restricted_game_versions ~= nil
		and achievement.restricted_game_versions[_G["HardcoreBuildLabel"]] ~= nil
	then
		description_text = description_text
			.. "\n |c00FF0000This achievement is not available for "
			.. _G["HardcoreBuildLabel"]
			.. ".|r"
	end

	if achievement.warnings ~= nil then
		for _, _warning_msg in ipairs(achievement.warnings) do
			description_text = description_text .. "\n |c00FFFF00 " .. _warning_msg .. "|r"
		end
	end

	description:SetText(description_text)
	description:SetPoint("BOTTOM", 200, 5)
	btn_container_frame:AddChild(description)
end

local function DrawPassiveAchievementsTab3(container, _scroll_frame, class, exclude_alliance, exclude_horde)
	for idx, id in pairs(_G.passive_achievements_order) do
		local v = _G.passive_achievements[id]
		if
			v.faction == nil
			or (v.faction == "Horde" and exclude_horde == false)
			or (v.faction == "Alliance" and exclude_alliance == false)
		then
			if v.category == class then
				DrawPassiveAchievementRow(v, _scroll_frame)
			end
		end
	end
	local bottom_buffer = AceGUI:Create("SimpleGroup")
	bottom_buffer:SetWidth(1)
	bottom_buffer:SetHeight(5)
	bottom_buffer:SetLayout("Flow")
	_scroll_frame:AddChild(bottom_buffer)
end

local function DrawClassTitleRowOffset(_scroll_frame, _title)
	local row_container = AceGUI:Create("SimpleGroup")
	row_container:SetWidth(800)
	row_container:SetHeight(60)
	row_container:SetLayout("Flow")
	_scroll_frame:AddChild(row_container)

	local title = AceGUI:Create("HardcoreClassTitleLabel")
	title:SetWidth(600)
	title:SetHeight(60)
	local CLASS_COLOR_BY_NAME = {
		["Druid"] = "FF7C0A",
		["Warlock"] = "8788EE",
		["Warrior"] = "C69B6D",
		["Mage"] = "3FC7EB",
		["Hunter"] = "AAD372",
		["Priest"] = "FFFFFF",
		["Shaman"] = "0070DD",
		["Paladin"] = "F48CBA",
		["Rogue"] = "FFF468",
		["Death Knight"] = "C41E3A",
		["General"] = "FFFFFF",
		["General Passive"] = "FFFFFF",
		["Horde Only"] = "8C1616",
		["Alliance Only"] = "004A93",
	}
	title:SetText("|c00" .. CLASS_COLOR_BY_NAME[_title] .. _title .. "|r Achievements")
	title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
	row_container:AddChild(title)
end

local function DrawClassTitleRow(_scroll_frame, _title)
	local row_container = AceGUI:Create("SimpleGroup")
	row_container:SetWidth(800)
	row_container:SetHeight(60)
	row_container:SetLayout("Flow")
	_scroll_frame:AddChild(row_container)

	local title = AceGUI:Create("HardcoreClassTitleLabel")
	title:SetWidth(700)
	title:SetHeight(60)
	local CLASS_COLOR_BY_NAME = {
		["Druid"] = "FF7C0A",
		["Warlock"] = "8788EE",
		["Warrior"] = "C69B6D",
		["Mage"] = "3FC7EB",
		["Hunter"] = "AAD372",
		["Priest"] = "FFFFFF",
		["Shaman"] = "0070DD",
		["Paladin"] = "F48CBA",
		["Rogue"] = "FFF468",
		["Death Knight"] = "C41E3A",
		["General"] = "FFFFFF",
		["General Passive"] = "FFFFFF",
		["Horde Only"] = "8C1616",
		["Alliance Only"] = "004A93",
	}
	title:SetText("|c00" .. CLASS_COLOR_BY_NAME[_title] .. _title .. "|r Achievements")
	title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
	row_container:AddChild(title)
end

local function DrawPassiveAchievementsPageIconForm(container, scroll_container, _category)
	local function DrawClassContainer(class_container, low, top, size, category)
		for idx, id in pairs(_G.passive_achievements_order) do
			local v = _G.passive_achievements[id]
			if
				v.level_cap >= low
				and v.level_cap <= top
				and category == v.category
				and (
					v.faction == nil
					or (v.faction == "Horde" and exclude_horde == false)
					or (v.faction == "Alliance" and exclude_alliance == false)
				)
			then
				local achievement_icon = AceGUI:Create("Icon")
				achievement_icon:SetWidth(size)
				achievement_icon:SetHeight(size)
				achievement_icon:SetImage(v.icon_path)
				achievement_icon:SetImageSize(size, size)
				achievement_icon.image:SetVertexColor(1, 1, 1)
				SetAchievementTooltip(achievement_icon, _G.passive_achievements[id], _player_name)
				class_container:AddChild(achievement_icon)
			end
		end

		local achievement_icon = AceGUI:Create("Icon")
		achievement_icon:SetWidth(1)
		achievement_icon:SetHeight(10)
		class_container:AddChild(achievement_icon)
	end

	local function addEntry(_scroll_frame, _player_name, _self_name) end

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("Flow")
	scroll_container:AddChild(achievements_container)

	local achievements_container_second_row = AceGUI:Create("SimpleGroup")
	achievements_container_second_row:SetRelativeWidth(1.0)
	achievements_container_second_row:SetHeight(50)
	achievements_container_second_row:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container_second_row)
	DrawClassContainer(achievements_container, 1, 60, 50, _category)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(200)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)
end

local function DrawAchievementRow(achievement, _scroll_frame, _hardcore_character, _mutable, _failure_function_executor)
	local btn_container = AceGUI:Create("SimpleGroup")
	btn_container:SetWidth(800)
	btn_container:SetHeight(60)
	btn_container:SetLayout("Flow")
	_scroll_frame:AddChild(btn_container)

	btn_container_frame = AceGUI:Create("SimpleGroup")
	btn_container_frame:SetLayout("Flow")

	-- Create a button
	local achievement_icon = AceGUI:Create("Icon")
	achievement_icons[achievement.name] = achievement_icon
	achievement_icon:SetWidth(60)
	achievement_icon:SetHeight(60)
	achievement_icon:SetImage(achievement.icon_path)
	achievement_icon:SetImageSize(60, 60)
	if _mutable then
		achievement_icon.image:SetVertexColor(0.2, 0.2, 0.2)
		if _hardcore_character.achievements == nil then
			_hardcore_character.achievements = {}
		end
		for i, v in ipairs(_hardcore_character.achievements) do
			if v == achievement.name then
				achievement_icon.image:SetVertexColor(1, 1, 1)
			end
		end
	else
		achievement_icon.image:SetVertexColor(1, 1, 1)
	end
	if _mutable then
		achievement_icon:SetCallback("OnClick", function()
			local activate = true
			for i, v in ipairs(_hardcore_character.achievements) do
				if v == achievement.name then
					activate = false
					table.remove(_hardcore_character.achievements, i)
					achievement_icon.image:SetVertexColor(0.1, 0.1, 0.1)
					achievement:Unregister()
					Hardcore:Print("Removed " .. achievement.name .. " challenge!")
				end
			end

			if activate then
				local _, _, _class_id = UnitClass("player")
				if CLASSES[_class_id] ~= achievement.class and achievement.class ~= "All" then
					Hardcore:Print(
						"Cannot start achievement " .. achievement.title .. " as class " .. CLASSES[_class_id]
					)
				elseif
					achievement.restricted_game_versions ~= nil
					and achievement.restricted_game_versions[_G["HardcoreBuildLabel"]] ~= nil
				then
					Hardcore:Print(
						"Achievement " .. achievement.title .. " is not supported in " .. _G["HardcoreBuildLabel"]
					)
				else
					table.insert(_hardcore_character.achievements, achievement.name)
					achievement_icon.image:SetVertexColor(1, 1, 1)
					achievement:Register(_failure_function_executor, _hardcore_character)
					Hardcore:Print("Added " .. achievement.name .. " challenge!")

					if achievement.forces ~= nil then
						for i, other_a in ipairs(achievement.forces) do
							if _G.achievements[other_a] ~= nil then
								local already_active = false
								for _i, _a in ipairs(_hardcore_character.achievements) do
									if _a == other_a then
										already_active = true
									end
								end
								if already_active == false then
									table.insert(_hardcore_character.achievements, _G.achievements[other_a].name)
									achievement_icons[other_a].image:SetVertexColor(1, 1, 1)
									_G.achievements[other_a]:Register(_failure_function_executor, _hardcore_character)
									Hardcore:Print("Added " .. _G.achievements[other_a].name .. " challenge!")
								end
							end
						end
					end
				end
			end
		end)
	end
	btn_container:AddChild(achievement_icon)

	local buffer_frame = AceGUI:Create("SimpleGroup")
	buffer_frame:SetWidth(30)
	buffer_frame:SetHeight(30)
	buffer_frame:SetLayout("Flow")
	btn_container:AddChild(buffer_frame)

	local btn_container_frame = AceGUI:Create("SimpleGroup")
	btn_container_frame:SetLayout("Flow")
	btn_container:AddChild(btn_container_frame)

	local title = AceGUI:Create("Label")
	title:SetWidth(550)
	title:SetText(achievement.title)
	title:SetPoint("TOP", 2, 5)
	title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
	btn_container_frame:AddChild(title)

	local description = AceGUI:Create("InteractiveLabel")
	description:SetWidth(475)
	description:SetFont("", 16, "")
	local description_text = achievement.description
	if achievement.forces ~= nil then
		description_text = description_text .. "\n |c00FFFF00Selecting " .. achievement.title .. " forces "
		for i = 1, #achievement.forces do
			if i == #achievement.forces and #achievement.forces > 1 then
				description_text = description_text .. "and "
			end
			description_text = description_text .. _G.achievements[achievement.forces[i]].title
			if i ~= #achievement.forces then
				description_text = description_text .. ", "
			end
		end
		description_text = description_text .. ".|r"
	end

	if
		achievement.restricted_game_versions ~= nil
		and achievement.restricted_game_versions[_G["HardcoreBuildLabel"]] ~= nil
	then
		description_text = description_text
			.. "\n |c00FF0000This achievement is not available for "
			.. _G["HardcoreBuildLabel"]
			.. ".|r"
	end

	if achievement.warnings ~= nil then
		for _, _warning_msg in ipairs(achievement.warnings) do
			description_text = description_text .. "\n |c00FFFF00 " .. _warning_msg .. "|r"
		end
	end

	description:SetText(description_text)
	description:SetPoint("BOTTOM", 200, 5)
	btn_container_frame:AddChild(description)
end

local function DrawAchievementIntroductionPage(scroll_frame)
	local first_menu_description_title = AceGUI:Create("Label")
	first_menu_description_title:SetWidth(500)
	first_menu_description_title:SetText("Achievements")
	first_menu_description_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
	-- first_menu_description_title:SetPoint("TOP", 2,5)
	scroll_frame:AddChild(first_menu_description_title)

	local first_menu_description = AceGUI:Create("Label")
	first_menu_description:SetWidth(650)
	first_menu_description:SetText(
		"\n\n\n\n|cffFFFF00Starting Achievements|r: Achievements which must be chosen at lvl 1 and act as additional rules.\n\n|cffFFFF00Questing Achievements|r: Awarded when the player meets some requirements and turns in a specified quest before a specified level.\n\n|cffFFFF00Miscellaneous Achievements|r: Awarded when the player meets some requirements before a specified level.\n\n|cffFFFF00Dungeon Achievements|r: Awarded when the player meets some requirements related to dungeons before a specified level.\n\n|cffFFFF00Profession Achievements|r: Awarded when the player meets some requirements related to professions before a specified level."
	)
	first_menu_description:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	-- first_menu_description:SetPoint("TOP", 2,5)
	scroll_frame:AddChild(first_menu_description)
end

local function DrawStartingAchievementsPage(
	container,
	_scroll_frame,
	_hardcore_character,
	_mutable,
	_failure_function_executor
)
	DrawClassTitleRowOffset(_scroll_frame, "General")

	for k, achievement_name in pairs(_G.achievements_order) do
		local achievement = _G.achievements[achievement_name]
		if achievement ~= nil then
			if achievement.class == "All" then
				DrawAchievementRow(
					achievement,
					_scroll_frame,
					_hardcore_character,
					_mutable,
					_failure_function_executor
				)
			end
		end
	end

	local class_list = { "Paladin", "Priest", "Rogue", "Shaman", "Druid", "Mage", "Hunter", "Warlock", "Warrior" }

	for i, class in ipairs(class_list) do
		DrawClassTitleRow(_scroll_frame, class)
		for k, achievement in pairs(_G.achievements) do
			if achievement.class == class then
				DrawAchievementRow(
					achievement,
					_scroll_frame,
					_hardcore_character,
					_mutable,
					_failure_function_executor
				)
			end
		end
	end
	local bottom_buffer = AceGUI:Create("SimpleGroup")
	bottom_buffer:SetWidth(1)
	bottom_buffer:SetHeight(5)
	bottom_buffer:SetLayout("Flow")
	_scroll_frame:AddChild(bottom_buffer)
end

local function DrawStartingAchievementsPageIconForm(
	container,
	scroll_container,
	_hardcore_character,
	_mutable,
	_failure_function_executor
)
	local function addEntry(_scroll_frame, _player_name, _self_name) end

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)

	local achievements_container_second_row = AceGUI:Create("SimpleGroup")
	achievements_container_second_row:SetRelativeWidth(1.0)
	achievements_container_second_row:SetHeight(50)
	achievements_container_second_row:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container_second_row)
	local function DrawClassContainer(class_container, class, size)
		local c = 0
		for k, achievement in pairs(_G.achievements) do
			if achievement.class == class then
				c = c + 1
				local achievement_icon = AceGUI:Create("Icon")
				achievement_icons[achievement.name] = achievement_icon
				achievement_icon:SetWidth(size)
				achievement_icon:SetHeight(size)
				achievement_icon:SetImage(achievement.icon_path)
				achievement_icon:SetImageSize(size, size)
				if _mutable then
					achievement_icon.image:SetVertexColor(0.2, 0.2, 0.2)
					if _hardcore_character.achievements == nil then
						_hardcore_character.achievements = {}
					end
					for i, v in ipairs(_hardcore_character.achievements) do
						if v == achievement.name then
							achievement_icon.image:SetVertexColor(1, 1, 1)
						end
					end
				else
					achievement_icon.image:SetVertexColor(1, 1, 1)
				end

				if _mutable then
					achievement_icon:SetCallback("OnClick", function()
						local activate = true
						for i, v in ipairs(_hardcore_character.achievements) do
							if v == achievement.name then
								activate = false
								table.remove(_hardcore_character.achievements, i)
								achievement_icon.image:SetVertexColor(0.1, 0.1, 0.1)
								achievement:Unregister()
								Hardcore:Print("Removed " .. achievement.name .. " challenge!")
							end
						end

						if activate then
							local _, _, _class_id = UnitClass("player")
							if CLASSES[_class_id] ~= achievement.class and achievement.class ~= "All" then
								Hardcore:Print(
									"Cannot start achievement "
										.. achievement.title
										.. " as class "
										.. CLASSES[_class_id]
								)
							elseif
								achievement.restricted_game_versions ~= nil
								and achievement.restricted_game_versions[_G["HardcoreBuildLabel"]] ~= nil
							then
								Hardcore:Print(
									"Achievement "
										.. achievement.title
										.. " is not supported in "
										.. _G["HardcoreBuildLabel"]
								)
							else
								table.insert(_hardcore_character.achievements, achievement.name)
								achievement_icon.image:SetVertexColor(1, 1, 1)
								achievement:Register(_failure_function_executor, _hardcore_character)
								Hardcore:Print("Added " .. achievement.name .. " challenge!")

								if achievement.forces ~= nil then
									for i, other_a in ipairs(achievement.forces) do
										if _G.achievements[other_a] ~= nil then
											local already_active = false
											for _i, _a in ipairs(_hardcore_character.achievements) do
												if _a == other_a then
													already_active = true
												end
											end
											if already_active == false then
												table.insert(
													_hardcore_character.achievements,
													_G.achievements[other_a].name
												)
												achievement_icons[other_a].image:SetVertexColor(1, 1, 1)
												_G.achievements[other_a]:Register(
													_failure_function_executor,
													_hardcore_character
												)
												Hardcore:Print(
													"Added " .. _G.achievements[other_a].name .. " challenge!"
												)
											end
										end
									end
								end
							end
						end
					end)
				end
				SetAchievementTooltip(achievement_icon, achievement, _player_name)
				class_container:AddChild(achievement_icon)
			end
		end

		local achievement_icon = AceGUI:Create("Icon")
		achievement_icon:SetWidth(1)
		achievement_icon:SetHeight(10)
		class_container:AddChild(achievement_icon)
	end

	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("General Achievements")
	achievements_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16, "")
	achievements_container:AddChild(achievements_title)
	DrawClassContainer(achievements_container, "All", 50)

	local function DrawClassContainer2(container, class, size)
		local class_contianer = AceGUI:Create("SimpleGroup")
		class_contianer:SetWidth(120)
		class_contianer:SetHeight(50)
		class_contianer:SetLayout("Flow")
		container:AddChild(class_contianer)

		local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
		achievements_title:SetRelativeWidth(1.0)
		achievements_title:SetHeight(40)
		achievements_title:SetText(class)
		achievements_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16, "")
		class_contianer:AddChild(achievements_title)
		DrawClassContainer(class_contianer, class, size)
	end

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(200)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)
	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("\n\n\n\n")
	achievements_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16, "")
	scroll_container:AddChild(achievements_title)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	scroll_container:AddChild(achievements_container)
	DrawClassContainer2(achievements_container, "Warrior", 36)
	DrawClassContainer2(achievements_container, "Hunter", 36)
	DrawClassContainer2(achievements_container, "Warlock", 36)
	DrawClassContainer2(achievements_container, "Mage", 36)
	DrawClassContainer2(achievements_container, "Druid", 36)
	DrawClassContainer2(achievements_container, "Paladin", 36)
	DrawClassContainer2(achievements_container, "Priest", 36)
	DrawClassContainer2(achievements_container, "Shaman", 36)
	DrawClassContainer2(achievements_container, "Rogue", 36)
end

function achievement_tab_handler:DrawAchievementTab(
	tabcontainer,
	_hardcore_character,
	_mutable,
	_failure_function_executor
)
	local recently_selected_group = "Introduction"
	local tree = {
		{
			value = "Introduction",
			text = "Introduction",
		},
		{
			value = "StartingAchievements",
			text = "Starting Achievements",
		},
		{
			value = "Questing",
			text = "Questing",
		},
		{
			value = "Miscellaneous",
			text = "Miscellaneous",
		},
		{
			value = "Dungeons",
			text = "Dungeons",
		},
		{
			value = "Professions",
			text = "Professions",
		},
	}
	local tree_container = AceGUI:Create("TreeGroup")
	tree_container:SetTree(tree)
	tree_container:EnableButtonTooltips(true)
	tree_container:SetFullWidth(true)
	tree_container:SetHeight(450)
	tree_container:SetLayout("Flow")
	local function chooseTreeChild(_container, group)
		_container:ReleaseChildren()
		local scroll_container = AceGUI:Create("SimpleGroup")
		scroll_container:SetWidth(650)
		scroll_container:SetHeight(375)
		scroll_container:SetLayout("Fill")
		tree_container:AddChild(scroll_container)

		local scroll_frame = AceGUI:Create("ScrollFrame")
		scroll_frame:SetLayout("Flow")
		scroll_container:AddChild(scroll_frame)

		if string.match(group, "Introduction") then
			DrawAchievementIntroductionPage(scroll_frame)
		elseif string.match(group, "StartingAchievements") then
			if row_form then
				DrawStartingAchievementsPage(
					_container,
					scroll_frame,
					_hardcore_character,
					_mutable,
					_failure_function_executor
				)
			else
				DrawStartingAchievementsPageIconForm(
					container,
					scroll_frame,
					_hardcore_character,
					_mutable,
					_failure_function_executor
				)
			end
		elseif string.match(group, "Miscellaneous") then
			if row_form then
				DrawPassiveAchievementsTab3(_container, scroll_frame, "Miscellaneous", exclude_alliance, exclude_horde)
			else
				DrawPassiveAchievementsPageIconForm(
					container,
					scroll_frame,
					"Miscellaneous",
					exclude_alliance,
					exclude_horde
				)
			end
		elseif string.match(group, "Questing") then
			if row_form then
				DrawPassiveAchievementsTab3(_container, scroll_frame, nil, exclude_alliance, exclude_horde)
			else
				DrawPassiveAchievementsPageIconForm(container, scroll_frame, nil, exclude_alliance, exclude_horde)
			end
		elseif string.match(group, "Dungeons") then
			if row_form then
				DrawPassiveAchievementsTab3(_container, scroll_frame, "Dungeons", exclude_alliance, exclude_horde)
			else
				DrawPassiveAchievementsPageIconForm(
					_container,
					scroll_frame,
					"Dungeons",
					exclude_alliance,
					exclude_horde
				)
			end
		elseif string.match(group, "Professions") then
			if row_form then
				DrawPassiveAchievementsTab3(_container, scroll_frame, "Profession", exclude_alliance, exclude_horde)
			else
				DrawPassiveAchievementsPageIconForm(
					_container,
					scroll_frame,
					"Profession",
					exclude_alliance,
					exclude_horde
				)
			end
		end
	end

	tree_container:SetCallback("OnGroupSelected", function(_container, events, group)
		recently_selected_group = group
		chooseTreeChild(_container, group)
	end)

	tabcontainer:AddChild(tree_container)
	chooseTreeChild(tree_container, recently_selected_group)

	local scroll_container = AceGUI:Create("SimpleGroup")
	scroll_container:SetWidth(700)
	scroll_container:SetHeight(10)
	scroll_container:SetLayout("Flow")
	tabcontainer:AddChild(scroll_container)

	local toggle_exclude_horde_form = AceGUI:Create("CheckBox")
	toggle_exclude_horde_form:SetLabel('Exclude "Horde Only"')
	toggle_exclude_horde_form:SetValue(exclude_horde)
	toggle_exclude_horde_form:SetCallback("OnValueChanged", function(args)
		exclude_horde = toggle_exclude_horde_form:GetValue()
		chooseTreeChild(tree_container, recently_selected_group)
	end)
	scroll_container:AddChild(toggle_exclude_horde_form)

	local toggle_exclude_alliance_form = AceGUI:Create("CheckBox")
	toggle_exclude_alliance_form:SetLabel('Exclude "Alliance Only"')
	toggle_exclude_alliance_form:SetValue(exclude_alliance)
	toggle_exclude_alliance_form:SetCallback("OnValueChanged", function(args)
		exclude_alliance = toggle_exclude_alliance_form:GetValue()
		chooseTreeChild(tree_container, recently_selected_group)
	end)
	scroll_container:AddChild(toggle_exclude_alliance_form)

	local toggle_row_form = AceGUI:Create("CheckBox")
	toggle_row_form:SetLabel("Row View")
	toggle_row_form:SetCallback("OnValueChanged", function(args)
		row_form = toggle_row_form:GetValue()
		chooseTreeChild(tree_container, recently_selected_group)
	end)
	scroll_container:AddChild(toggle_row_form)
end
