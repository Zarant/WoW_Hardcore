local CLASS_COLOR_BY_NAME = {
	["DRUID"] = "FF7C0A",
	["WARLOCK"] = "8788EE",
	["WARRIOR"] = "C69B6D",
	["MAGE"] = "3FC7EB",
	["HUNTER"] = "AAD372",
	["PRIEST"] = "FFFFFF",
	["SHAMAN"] = "0070DD",
	["PALADIN"] = "F48CBA",
	["ROGUE"] = "FFF468",
	["DEATHKNIGHT"] = "C41E3A",
	["GENERAL"] = "FFFFFF",
}
local AceGUI = LibStub("AceGUI-3.0")
local ICON_SIZE = 39
local TabName = "DummyHCTab"
local TabID = CharacterFrame.numTabs + 1
local Tab = CreateFrame("Button", "$parentTab" .. TabID, CharacterFrame, "CharacterFrameTabButtonTemplate", TabID)
Tab:SetPoint("LEFT", "$parentTab" .. (TabID - 1), "RIGHT", -50000, 0) -- Offscreen; we need to have this tab as a dummy
Tab:SetText(TabName)
Tab:Show()
_G["CharacterFrameTab3Text"]:SetText("Rep.")

local Panel = CreateFrame("Frame", nil, CharacterFrame)
Panel:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", -50, -200)
Panel:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -200, 0)
local f = CreateFrame("Frame", "YourFrameName", Panel)
f:SetSize(400, 400)
f:SetPoint("CENTER")
f:Hide()

local t = f:CreateTexture(nil, "BACKGROUND")
t:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
t:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 2, -1)
t:SetWidth(256)
t:SetHeight(256)

local tr = f:CreateTexture(nil, "BACKGROUND")
tr:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
tr:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 258, -1)
tr:SetWidth(128)
tr:SetHeight(256)

local bl = f:CreateTexture(nil, "BACKGROUND")
bl:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomLeft")
bl:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 2, -257)
bl:SetWidth(256)
bl:SetHeight(256)

local br = f:CreateTexture(nil, "BACKGROUND")
br:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-BottomRight")
br:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 258, -257)
br:SetWidth(128)
br:SetHeight(256)

local title_text = f:CreateFontString(nil, "ARTWORK")
title_text:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 22, "")
title_text:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 150, -45)
title_text:SetTextColor(1, 0.82, 0)
title_text:SetText("Hardcore")

Panel:SetPoint("CENTER", 0, 0)
Panel:Hide()

local f2 = AceGUI:Create("HardcoreFrameEmpty")
f2:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 8, -38)
f2:SetWidth(360)
f2:SetHeight(350)
f2:Hide()

hooksecurefunc(CharacterFrame, "Hide", function(self, button)
	HideCharacterHC()
end)

local game_version_offset = 0
if _G["HardcoreBuildLabel"] == "WotLK" then
	game_version_offset = -72
end
local TabGUI = CreateFrame("Button", "nwtab" .. TabID, CharacterFrame)
_G["HardcoreCharacterTab"] = TabGUI
TabGUI:SetPoint("LEFT", "CharacterFrameTab5", "RIGHT", -16 + game_version_offset, 0)
C_Timer.After(1.0, function() -- Check to see if the currency tab is active, then offset the new tab if it is
	if
		_G["TokenFrame"] ~= nil
		and _G["CharacterFrameTab5Text"] ~= nil
		and _G["CharacterFrameTab5Text"]:GetText() == "Currency"
		and _G["CharacterFrameTab5Text"]:IsShown()
	then
		for index = 1, GetCurrencyListSize() do
			name, isHeader, isExpanded, isUnused, isWatched, count, icon = GetCurrencyListInfo(index)
			if not isHeader and count ~= nil and (count > 0) then
				TabGUI:SetPoint("LEFT", "CharacterFrameTab5", "RIGHT", 56 + game_version_offset, 0)
				_G["CharacterFrameTab5Text"]:SetText("Curr.")
			end
		end
	end
end)

TabGUI.text = TabGUI:CreateFontString(nil, "OVERLAY")
TabGUI.text:SetDrawLayer("ARTWORK", 8)
TabGUI.text:SetFontObject(GameFontNormalSmall)
TabGUI.text:SetPoint("CENTER", 0, 1)
TabGUI.text:SetText("HC")
local tab_gui_left = TabGUI:CreateTexture()
tab_gui_left:SetDrawLayer("ARTWORK", 1)
tab_gui_left:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
tab_gui_left:SetSize(25, 32)
tab_gui_left:SetRotation(3.14)
tab_gui_left:SetTexCoord(0.8, 1.0, 1.0, 0.0)
tab_gui_left:SetPoint("TOPLEFT", 0, -5)
local tab_gui_middle = TabGUI:CreateTexture(nil, "ARTWORK")
tab_gui_middle:SetDrawLayer("ARTWORK", 1)
tab_gui_middle:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
tab_gui_middle:SetSize(25, 32)
tab_gui_middle:SetRotation(3.14)
tab_gui_middle:SetTexCoord(0.8, 0.20, 1.0, 0.0)
tab_gui_middle:SetPoint("TOP", 0, -5)
local tab_gui_right = TabGUI:CreateTexture(nil, "ARTWORK")
tab_gui_right:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
tab_gui_right:SetSize(25, 32)
tab_gui_right:SetRotation(3.14)
tab_gui_right:SetTexCoord(0.0, 0.20, 1.0, 0.0)
tab_gui_right:SetPoint("TOPRIGHT", 0, -5)
tab_gui_left:Hide()
tab_gui_middle:Hide()
tab_gui_right:Hide()

local inactive_tab_gui_left = TabGUI:CreateTexture(nil, "ARTWORK")
inactive_tab_gui_left:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab")
inactive_tab_gui_left:SetSize(25, 32)
inactive_tab_gui_left:SetRotation(3.14)
inactive_tab_gui_left:SetTexCoord(0.8, 1.0, 1.0, 0.0)
inactive_tab_gui_left:SetPoint("TOPLEFT", 0, -9)
local inactive_tab_gui_middle = TabGUI:CreateTexture(nil, "ARTWORK")
inactive_tab_gui_middle:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab")
inactive_tab_gui_middle:SetSize(25, 32)
inactive_tab_gui_middle:SetRotation(3.14)
inactive_tab_gui_middle:SetTexCoord(0.8, 0.20, 1.0, 0.0)
inactive_tab_gui_middle:SetPoint("TOP", 0, -9)
local inactive_tab_gui_right = TabGUI:CreateTexture(nil, "ARTWORK")
inactive_tab_gui_right:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InactiveTab")
inactive_tab_gui_right:SetSize(25, 32)
inactive_tab_gui_right:SetRotation(3.14)
inactive_tab_gui_right:SetTexCoord(0.0, 0.20, 1.0, 0.0)
inactive_tab_gui_right:SetPoint("TOPRIGHT", 0, -9)

local tab_higlight = TabGUI:CreateTexture(nil, "OVERLAY")
tab_higlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-RealHighlight")
tab_higlight:SetSize(46, 43)
tab_higlight:SetRotation(3.14)
tab_higlight:SetTexCoord(1.0, 0.0, 1.0, 0.0)
tab_higlight:SetPoint("TOP", 0, 0)
TabGUI:SetHighlightTexture(tab_higlight, "ADD")

TabGUI:SetScript("OnClick", function(self, arg1)
	print(arg1)
end)

TabGUI:SetWidth(60)
TabGUI:SetHeight(50)
TabGUI:Show()

hooksecurefunc(CharacterFrame, "Show", function(self, button)
	TabGUI:Show()
end)

hooksecurefunc(CharacterFrame, "Hide", function(self, button)
	TabGUI:Hide()
end)

function extractDetails(str, ignoreKeys)
	if str == nil then return {} end
	str = str:gsub("^%s*%((.+)%)%s*$", "%1")
	local details_table = {}
	for key, value in str:gmatch("(%S+)=(%S+)") do
		Hardcore:Print("extractDetails: " .. key .. " = " .. value)
	  -- Check if the current key is in the ignoreKeys array
		local ignore = false
		for _, ignoreKey in ipairs(ignoreKeys or {}) do
			if key == ignoreKey then
				ignore = true
				break
			end
		end
		-- Store the key-value pair in the details table if it's not being ignored
		if not ignore then
		details_table[key] = value
		end
	end
  
	return details_table
end

function formatDetails(details_table)
	local str = ""
	for key, value in pairs(details_table) do
	  str = str .. key .. " = " .. value .. ", "
	end
	return str:sub(1, -3) -- Remove the trailing space before returning
  end

function UpdateCharacterHC(
	_hardcore_character,
	_player_name,
	_version,
	frame_to_update,
	_player_class,
	_player_class_en,
	_player_level
)
	frame_to_update:ReleaseChildren()
	if _hardcore_character == nil then
		return
	end

	local character_meta_data_container = AceGUI:Create("SimpleGroup")
	character_meta_data_container:SetRelativeWidth(1.0)
	character_meta_data_container:SetHeight(200)
	character_meta_data_container:SetLayout("List")
	frame_to_update:AddChild(character_meta_data_container)

	local character_name = AceGUI:Create("HardcoreClassTitleLabel")
	character_name:SetRelativeWidth(1.0)
	character_name:SetHeight(60)
	character_name:SetText("\n" .. _player_name .. "\n\n")
	character_name:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	character_meta_data_container:AddChild(character_name)

	local team_title = AceGUI:Create("HardcoreClassTitleLabel")
	team_title:SetRelativeWidth(1.0)
	team_title:SetHeight(60)
	local mode_type_str = "unknown"
	local teammate_1 = "missing_team"
	local teammate_2 = "unknown"

	if _hardcore_character.team ~= nil then
		teammate_1 = _hardcore_character.team[1] or "unknown"
		teammate_2 = _hardcore_character.team[2] or "unknown"
	end
	if _hardcore_character.party_mode ~= nil then
		if _hardcore_character.party_mode == "Solo" then
			mode_type_str = "Solo"
		elseif _hardcore_character.party_mode == "Duo" then
			mode_type_str = "Duo with " .. teammate_1
		elseif _hardcore_character.party_mode == "Trio" then
			mode_type_str = "Trio with " .. teammate_1 .. " and " .. teammate_2
		else
			mode_type_str = "|c00FF0000" .. _hardcore_character.party_mode .. "|r"
		end
	end
	team_title:SetText(mode_type_str)
	team_title:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(team_title)

	local level_title_text = AceGUI:Create("HardcoreClassTitleLabel")
	level_title_text:SetRelativeWidth(1.0)
	level_title_text:SetHeight(60)
	local level_text = _player_level or "?"
	local class_text
	if _player_class_en ~= nil and _player_class ~= nil then
		class_text = "|c00" .. CLASS_COLOR_BY_NAME[_player_class_en] .. _player_class .. "|r"
	else
		class_text = "?"
	end
	level_title_text:SetText("Level " .. level_text .. " " .. class_text)
	level_title_text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(level_title_text)

	local creation_date_label = AceGUI:Create("HardcoreClassTitleLabel")
	creation_date_label:SetRelativeWidth(1.0)
	creation_date_label:SetHeight(60)
	local start_date = "(unknown - data loss / previous version)"
	if _hardcore_character.first_recorded ~= nil and _hardcore_character.first_recorded ~= -1 then
		start_date = date("%m/%d/%y", _hardcore_character.first_recorded)
		if start_date == nil then
			start_date = "(unknown - data loss / previous version)"
		end
	end
	creation_date_label:SetText("Started on " .. start_date)
	creation_date_label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(creation_date_label)

	local version_name = AceGUI:Create("HardcoreClassTitleLabel")
	version_name:SetRelativeWidth(1.0)
	version_name:SetHeight(60)
	local version = _version
	local game_version = _hardcore_character.game_version or _G["HardcoreBuildLabel"]
	version_name:SetText("Addon version: " .. version .. ", " .. game_version)
	version_name:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(version_name)

	local endgame_label = AceGUI:Create("HardcoreClassTitleLabel")
	endgame_label:SetRelativeWidth(1.0)
	endgame_label:SetHeight(60)
	local endgame_status = "(unknown - previous version)"
	if _hardcore_character.endgame ~= nil then
		if _hardcore_character.endgame then
			endgame_status = "TRUE"
		else
			endgame_status = "FALSE"
		end
	end
	endgame_label:SetText("Endgame status: " .. endgame_status)
	endgame_label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(endgame_label)

	-- SET UP FILTERING
	local filtered_status = _hardcore_character.verification_status
	local filtered_details = _hardcore_character.verification_details

	--Hardcore:Print("Status: ".. _hardcore_character.verification_status)

	if _player_name ~= UnitName("player") then
		-- Remove tracked_time and deaths entries
		local ignoreKeys = {"tracked_time", "deaths", "appeals", "repeat_dung", "overlvl_dung"}
		local details_table = extractDetails(_hardcore_character.verification_details, ignoreKeys)
		filtered_details = formatDetails(details_table)

		-- filtered details now only contains offenses that aren't tracked time or deaths, or is empty
		if filtered_details == "" and _hardcore_character.verification_status == "PASS" then
			filtered_status = "|cff1eff0cPASS|r"
		elseif filtered_details == "" and _hardcore_character.verification_status == "FAIL" then
			filtered_status = "|cffff8000PENDING|r"
		elseif _hardcore_character.verification_status == "FAIL" then
			filtered_status = "|cffff3f40FAIL|r"
		else
			filtered_status = "|cff99ff99UNKNOWN|r\n(previous addon version)"
		end
	end

	if _hardcore_character.hardcore_player_name ~= nil and _hardcore_character.hardcore_player_name ~= "" then
		local hc_tag_f = AceGUI:Create("HardcoreClassTitleLabel")
		hc_tag_f:SetRelativeWidth(1.0)
		hc_tag_f:SetHeight(60)
		local hc_tag_string = _hardcore_character.hardcore_player_name
		hc_tag_f:SetText("HC Tag: " .. hc_tag_string)
		hc_tag_f:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
		character_meta_data_container:AddChild(hc_tag_f)
	end

	local verif_msg = "\n\nVerification status: \n\n"
	if _hardcore_character.verification_status == nil then
		verif_msg = verif_msg .. "(unknown - version not supported)"
	else
		verif_msg = verif_msg .. filtered_status
	end

	local hc_tag_g = AceGUI:Create("HardcoreClassTitleLabel")
	hc_tag_g:SetRelativeWidth(1.0)
	hc_tag_g:SetHeight(60)
	hc_tag_g:SetText(verif_msg)
	hc_tag_g:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(hc_tag_g)

	local verif_msg2 = ""
	if _hardcore_character.verification_details == nil then
		verif_msg2 = verif_msg2 .. "(unknown - version not supported)"
	else
		verif_msg2 = verif_msg2 .. filtered_details
	end

	local hc_tag_h = AceGUI:Create("HardcoreClassTitleLabel")
	hc_tag_h:SetRelativeWidth(1.0)
	hc_tag_h:SetHeight(60)
	hc_tag_h:SetText(verif_msg2)
	hc_tag_h:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(hc_tag_h)
	
	local explanatory_key_msg = ""
	.. "\n\nWhat does this mean?\n"
	.. "|cff1eff0cPASS|r - Valid HC Character, Dungeon-legal\n"
	.. "|cffff8000PENDING|r - Death or data appeal in progress\n"
	.. "|cffff3f40FAIL|r - Has failed the challenge - INVALID CHARACTER\n"
	
	local hc_tag_g = AceGUI:Create("HardcoreClassTitleLabel")
	hc_tag_g:SetRelativeWidth(1.0)
	hc_tag_g:SetHeight(60)
	hc_tag_g:SetText(explanatory_key_msg)
	hc_tag_g:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
	character_meta_data_container:AddChild(hc_tag_g)

	local v_buffer = AceGUI:Create("Label")
	v_buffer:SetRelativeWidth(1.0)
	v_buffer:SetHeight(50)
	v_buffer:SetText("\n")
	frame_to_update:AddChild(v_buffer)

	local achievements_container = AceGUI:Create("SimpleGroup")
	achievements_container:SetRelativeWidth(1.0)
	achievements_container:SetHeight(50)
	achievements_container:SetLayout("CenteredFlow")
	frame_to_update:AddChild(achievements_container)

	local _acheivement_pts = CalculateHCAchievementPts(_hardcore_character)
	local achievements_title = AceGUI:Create("HardcoreClassTitleLabel")
	achievements_title:SetRelativeWidth(1.0)
	achievements_title:SetHeight(40)
	achievements_title:SetText("Achievements - " .. _acheivement_pts .. "pts")
	achievements_title:SetFont("Interface\\Addons\\Hardcore\\Media\\BreatheFire.ttf", 16, "")
	achievements_container:AddChild(achievements_title)
	if _hardcore_character.achievements ~= nil then
		for i, v in ipairs(_hardcore_character.achievements) do
			if _G.achievements[v] ~= nil then
				local achievement_icon = AceGUI:Create("Icon")
				achievement_icon:SetWidth(ICON_SIZE)
				achievement_icon:SetHeight(ICON_SIZE)
				achievement_icon:SetImage(_G.achievements[v].icon_path)
				achievement_icon:SetImageSize(ICON_SIZE, ICON_SIZE)
				achievement_icon.image:SetVertexColor(1, 1, 1)
				SetAchievementTooltip(achievement_icon, _G.achievements[v], _player_name)
				achievements_container:AddChild(achievement_icon)
			end
		end
	end

	if _hardcore_character.passive_achievements ~= nil then
		for i, v in ipairs(_hardcore_character.passive_achievements) do
			if _G.passive_achievements[v] ~= nil then
				local achievement_icon = AceGUI:Create("Icon")
				achievement_icon:SetWidth(ICON_SIZE)
				achievement_icon:SetHeight(ICON_SIZE)
				achievement_icon:SetImage(_G.passive_achievements[v].icon_path)
				achievement_icon:SetImageSize(ICON_SIZE, ICON_SIZE)
				achievement_icon.image:SetVertexColor(1, 1, 1)
				SetAchievementTooltip(achievement_icon, _G.passive_achievements[v], _player_name)
				achievements_container:AddChild(achievement_icon)
			end
		end
	end
end

function ShowCharacterHC(_hardcore_character)
	tab_gui_left:Show()
	tab_gui_middle:Show()
	tab_gui_right:Show()
	inactive_tab_gui_left:Hide()
	inactive_tab_gui_middle:Hide()
	inactive_tab_gui_right:Hide()
	TabGUI.text:SetFontObject(GameFontHighlightSmall)
	TabGUI.text:SetPoint("CENTER", 0, 3)
	TabGUI:SetFrameStrata("HIGH")

	f2:ReleaseChildren()

	local class, class_en, _ = UnitClass("player")
	UpdateCharacterHC(
		_hardcore_character,
		UnitName("player"),
		GetAddOnMetadata("Hardcore", "Version"),
		f2,
		class,
		class_en,
		UnitLevel("player")
	)
	Panel:Show()
	f:Show()
	f2:Show()
end

function HideCharacterHC()
	tab_gui_left:Hide()
	tab_gui_middle:Hide()
	tab_gui_right:Hide()
	inactive_tab_gui_left:Show()
	inactive_tab_gui_middle:Show()
	inactive_tab_gui_right:Show()
	TabGUI.text:SetFontObject(GameFontNormalSmall)
	TabGUI.text:SetPoint("CENTER", 0, 1)
	TabGUI:SetFrameStrata("HIGH")
	Panel:Hide()
	f:Hide()
	f2:Hide()
	f2:ReleaseChildren()
end

TabGUI:RegisterEvent("PLAYER_ENTER_COMBAT")
TabGUI:RegisterEvent("PLAYER_LEAVE_COMBAT")

_G["HardcoreCharacterTab"]:SetScript("OnClick", function(self, arg1)
	PanelTemplates_SetTab(CharacterFrame, 6)
	if _G["HonorFrame"] ~= nil then
		_G["HonorFrame"]:Hide()
	end
	if _G["PaperDollFrame"] ~= nil then
		_G["PaperDollFrame"]:Hide()
	end
	if _G["PetPaperDollFrame"] ~= nil then
		_G["PetPaperDollFrame"]:Hide()
	end
	if _G["HonorFrame"] ~= nil then
		_G["HonorFrame"]:Hide()
	end
	if _G["SkillFrame"] ~= nil then
		_G["SkillFrame"]:Hide()
	end
	if _G["ReputationFrame"] ~= nil then
		_G["ReputationFrame"]:Hide()
	end
	if _G["TokenFrame"] ~= nil then
		_G["TokenFrame"]:Hide()
	end
	ShowCharacterHC(Hardcore_Character)
end)

TabGUI:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "PLAYER_ENTER_COMBAT" then
		TabGUI.text:SetText("|c00808080HC|r")
		HideCharacterHC()
		_G["HardcoreCharacterTab"]:SetScript("OnClick", function(self, arg1) end)
	elseif event == "PLAYER_LEAVE_COMBAT" then
		TabGUI.text:SetText("HC")
		_G["HardcoreCharacterTab"]:SetScript("OnClick", function(self, arg1)
			PanelTemplates_SetTab(CharacterFrame, 6)
			if _G["HonorFrame"] ~= nil then
				_G["HonorFrame"]:Hide()
			end
			if _G["PaperDollFrame"] ~= nil then
				_G["PaperDollFrame"]:Hide()
			end
			if _G["PetPaperDollFrame"] ~= nil then
				_G["PetPaperDollFrame"]:Hide()
			end
			if _G["HonorFrame"] ~= nil then
				_G["HonorFrame"]:Hide()
			end
			if _G["SkillFrame"] ~= nil then
				_G["SkillFrame"]:Hide()
			end
			if _G["ReputationFrame"] ~= nil then
				_G["ReputationFrame"]:Hide()
			end
			if _G["TokenFrame"] ~= nil then
				_G["TokenFrame"]:Hide()
			end
			ShowCharacterHC(Hardcore_Character)
		end)
	end
end)
