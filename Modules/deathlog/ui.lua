local ui = {}

local _, addon = ...
-- check if we are running in wow
if type(addon) == "table" then
	addon.deathlog.ui = ui
end

local AceGUI = LibStub("AceGUI-3.0")

-- Death log icon
local death_log_icon_frame = CreateFrame("frame")
death_log_icon_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
death_log_icon_frame:SetSize(40, 40)
death_log_icon_frame:SetMovable(true)
death_log_icon_frame:EnableMouse(true)
death_log_icon_frame:Show()

local black_round_tex = death_log_icon_frame:CreateTexture(nil, "OVERLAY")
black_round_tex:SetPoint("CENTER", death_log_icon_frame, "CENTER", -5, 4)
black_round_tex:SetDrawLayer("OVERLAY", 2)
black_round_tex:SetHeight(40)
black_round_tex:SetWidth(40)
black_round_tex:SetTexture("Interface\\PVPFrame\\PVP-Separation-Circle-Cooldown-overlay")

local hc_fire_tex = death_log_icon_frame:CreateTexture(nil, "OVERLAY")
hc_fire_tex:SetPoint("CENTER", death_log_icon_frame, "CENTER", -6, 4)
hc_fire_tex:SetDrawLayer("OVERLAY", 3)
hc_fire_tex:SetHeight(25)
hc_fire_tex:SetWidth(25)
hc_fire_tex:SetTexture("Interface\\AddOns\\Hardcore\\Media\\wowhc-emblem-white-red.blp")

local gold_ring_tex = death_log_icon_frame:CreateTexture(nil, "OVERLAY")
gold_ring_tex:SetPoint("CENTER", death_log_icon_frame, "CENTER", 0, 0)
gold_ring_tex:SetDrawLayer("OVERLAY", 2)
gold_ring_tex:SetHeight(50)
gold_ring_tex:SetWidth(50)
gold_ring_tex:SetTexture("Interface\\COMMON\\BlueMenuRing")

-- Death log frame
local death_log_frame = AceGUI:Create("Deathlog")

death_log_frame.frame:SetMovable(false)
death_log_frame.frame:EnableMouse(false)
death_log_frame:SetTitle("Hardcore Death Log")
local subtitle_data = {
	{ "Name", 70, function(_entry) return _entry.player_data["name"] or "" end },
	{ "Class", 60, function(_entry)
		local class_str, _, _ = GetClassInfo(_entry.player_data["class_id"])
		if RAID_CLASS_COLORS[class_str:upper()] then
			return "|c" .. RAID_CLASS_COLORS[class_str:upper()].colorStr .. class_str .. "|r"
		end
		return class_str or ""
	end },
	{ "Race", 60, function(_entry)
		local race_info = C_CreatureInfo.GetRaceInfo(_entry.player_data["race_id"])
		return race_info.raceName or ""
	end },
	{ "Lvl",  30, function(_entry) return _entry.player_data["level"] or "" end },
}
death_log_frame:SetSubTitle(subtitle_data)
death_log_frame:SetLayout("Fill")
death_log_frame.frame:SetSize(255, 125)
death_log_frame:Show()

local scroll_frame = AceGUI:Create("ScrollFrame")
scroll_frame:SetLayout("List")
death_log_frame:AddChild(scroll_frame)

death_log_icon_frame:RegisterForDrag("LeftButton")
death_log_icon_frame:SetScript("OnDragStart", function(self, button)
	self:StartMoving()
end)
death_log_icon_frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local x, y = self:GetCenter()
	local px = (GetScreenWidth() * UIParent:GetEffectiveScale()) / 2
	local py = (GetScreenHeight() * UIParent:GetEffectiveScale()) / 2
	if hardcore_settings['death_log_pos'] == nil then
		hardcore_settings['death_log_pos'] = {}
	end
	hardcore_settings['death_log_pos']['x'] = x - px
	hardcore_settings['death_log_pos']['y'] = y - py
end)

local WorldMapButton = WorldMapFrame:GetCanvas()
local death_tomb_frame = CreateFrame('frame', nil, WorldMapButton)
death_tomb_frame:SetAllPoints()
death_tomb_frame:SetFrameLevel(15000)

local death_tomb_frame_tex = death_tomb_frame:CreateTexture(nil, 'OVERLAY')
death_tomb_frame_tex:SetTexture("Interface\\TARGETINGFRAME\\UI-TargetingFrame-Skull")
death_tomb_frame_tex:SetDrawLayer("OVERLAY", 4)
death_tomb_frame_tex:SetHeight(25)
death_tomb_frame_tex:SetWidth(25)
death_tomb_frame_tex:Hide()

local death_tomb_frame_tex_glow = death_tomb_frame:CreateTexture(nil, 'OVERLAY')
death_tomb_frame_tex_glow:SetTexture("Interface\\Glues/Models/UI_HUMAN/GenericGlow64")
death_tomb_frame_tex_glow:SetDrawLayer("OVERLAY", 3)
death_tomb_frame_tex_glow:SetHeight(55)
death_tomb_frame_tex_glow:SetWidth(55)
death_tomb_frame_tex_glow:Hide()

local function deathFrameDropdown(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	local function minimize()
		death_log_frame:Minimize()
	end

	local function maximize()
		death_log_frame:Maximize()
	end

	local function hide()
		death_log_frame.frame:Hide()
		death_log_icon_frame:Hide()
		hardcore_settings["death_log_show"] = false
	end

	local function openSettings()
		InterfaceOptionsFrame_Show()
		InterfaceOptionsFrame_OpenToCategory("Hardcore")
	end

	if level == 1 then
		if death_log_frame:IsMinimized() then
			info.text, info.hasArrow, info.func = "Maximize", false, maximize
			UIDropDownMenu_AddButton(info)
		else
			info.text, info.hasArrow, info.func = "Minimize", false, minimize
			UIDropDownMenu_AddButton(info)
		end

		info.text, info.hasArrow, info.func = "Settings", false, openSettings
		UIDropDownMenu_AddButton(info)

		info.text, info.hasArrow, info.func = "Hide", false, hide
		UIDropDownMenu_AddButton(info)
	end
end

death_log_icon_frame:SetScript("OnMouseDown", function(self, button)
	if button == 'RightButton' then
		local dropDown = CreateFrame("Frame", "death_frame_dropdown_menu", UIParent, "UIDropDownMenuTemplate")
		UIDropDownMenu_Initialize(dropDown, deathFrameDropdown, "MENU")
		ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
	end
end)

local function setEntry(player_data, _entry)
	_entry.player_data = player_data
	for _, v in ipairs(subtitle_data) do
		_entry.font_strings[v[1]]:SetText(v[3](_entry))
	end
end

local function shiftEntry(_entry_from, _entry_to)
	setEntry(_entry_from.player_data, _entry_to)
end

local selected = nil
local row_entry = {}
function WPDropDownDemo_Menu(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	local function openWorldMap()
		if not (death_tomb_frame.map_id and death_tomb_frame.coordinates) then return end
		if C_Map.GetMapInfo(death_tomb_frame["map_id"]) == nil then return end
		if tonumber(death_tomb_frame.coordinates[1]) == nil or tonumber(death_tomb_frame.coordinates[2]) == nil then return end

		WorldMapFrame:SetShown(not WorldMapFrame:IsShown())
		WorldMapFrame:SetMapID(death_tomb_frame.map_id)
		WorldMapFrame:GetCanvas()
		local mWidth, mHeight = WorldMapFrame:GetCanvas():GetSize()
		death_tomb_frame_tex:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', mWidth * death_tomb_frame.coordinates[1],
			-mHeight * death_tomb_frame.coordinates[2])
		death_tomb_frame_tex:Show()

		death_tomb_frame_tex_glow:SetPoint('CENTER', WorldMapButton, 'TOPLEFT', mWidth * death_tomb_frame.coordinates[1],
			-mHeight * death_tomb_frame.coordinates[2])
		death_tomb_frame_tex_glow:Show()
		death_tomb_frame:Show()
	end


	if level == 1 then
		info.text, info.hasArrow, info.func, info.disabled = "Show death location (WIP)", false, openWorldMap, false
		UIDropDownMenu_AddButton(info)
		info.text, info.hasArrow, info.func, info.disabled = "Block user", false, openWorldMap, true
		UIDropDownMenu_AddButton(info)
		info.text, info.hasArrow, info.func, info.disabled = "Block user's guild", false, openWorldMap, true
		UIDropDownMenu_AddButton(info)
	end
end

for i = 1, 20 do
	local idx = 21 - i
	row_entry[idx] = AceGUI:Create("InteractiveLabel")
	local _entry = row_entry[idx]
	_entry:SetHighlight("Interface\\Glues\\CharacterSelect\\Glues-CharacterSelect-Highlight")
	_entry.font_strings = {}
	local current_column_offset = 15
	for idx, v in ipairs(subtitle_data) do
		_entry.font_strings[v[1]] = _entry.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		_entry.font_strings[v[1]]:SetPoint("LEFT", _entry.frame, "LEFT", current_column_offset, 0)
		current_column_offset = current_column_offset + v[2]
		_entry.font_strings[v[1]]:SetJustifyH("LEFT")

		if idx + 1 <= #subtitle_data then
			_entry.font_strings[v[1]]:SetWidth(v[2])
		end
		_entry.font_strings[v[1]]:SetTextColor(1, 1, 1)
		_entry.font_strings[v[1]]:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
	end

	_entry.background = _entry.frame:CreateTexture(nil, "OVERLAY")
	_entry.background:SetPoint("CENTER", _entry.frame, "CENTER", 0, 0)
	_entry.background:SetDrawLayer("OVERLAY", 2)
	_entry.background:SetVertexColor(.5, .5, .5, (i % 2) / 10)
	_entry.background:SetHeight(16)
	_entry.background:SetWidth(500)
	_entry.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

	_entry:SetHeight(40)
	_entry:SetFont("Fonts\\FRIZQT__.TTF", 16, "")
	_entry:SetColor(1, 1, 1)
	_entry:SetText(" ")

	function _entry:deselect()
		for _, v in pairs(_entry.font_strings) do
			v:SetTextColor(1, 1, 1)
		end
	end

	function _entry:select()
		selected = idx
		for _, v in pairs(_entry.font_strings) do
			v:SetTextColor(1, 1, 0)
		end
	end

	_entry:SetCallback("OnLeave", function(widget)
		if _entry.player_data == nil then return end
		GameTooltip:Hide()
	end)

	_entry:SetCallback("OnClick", function()
		if _entry.player_data == nil then return end
		local click_type = GetMouseButtonClicked()

		if click_type == "LeftButton" then
			if selected then row_entry[selected]:deselect() end
			_entry:select()
		elseif click_type == "RightButton" then
			local dropDown = CreateFrame("Frame", "WPDemoContextMenu", UIParent, "UIDropDownMenuTemplate")
			-- Bind an initializer function to the dropdown; see previous sections for initializer function examples.
			UIDropDownMenu_Initialize(dropDown, WPDropDownDemo_Menu, "MENU")
			ToggleDropDownMenu(1, nil, dropDown, "cursor", 3, -3)
			if _entry["player_data"]["map_id"] and _entry["player_data"]["map_pos"] then
				death_tomb_frame.map_id = _entry["player_data"]["map_id"]
				local x, y = strsplit(",", _entry["player_data"]["map_pos"], 2)
				death_tomb_frame.coordinates = { x, y }
			end
		end
	end)

	_entry:SetCallback("OnEnter", function(widget)
		if _entry.player_data == nil then return end
		GameTooltip_SetDefaultAnchor(GameTooltip, WorldFrame)

		if string.sub(_entry.player_data["name"], #_entry.player_data["name"]) == "s" then
			GameTooltip:AddDoubleLine(_entry.player_data["name"] .. "' Death", "Lvl. " .. _entry.player_data["level"], 1,
				1, 1, .5, .5, .5);
		else
			GameTooltip:AddDoubleLine(_entry.player_data["name"] .. "'s Death", "Lvl. " .. _entry.player_data["level"], 1,
				1, 1, .5, .5, .5);
		end
		GameTooltip:AddLine("Name: " .. _entry.player_data["name"], 1, 1, 1)
		GameTooltip:AddLine("Guild: " .. _entry.player_data["guild"], 1, 1, 1)

		local race_info = C_CreatureInfo.GetRaceInfo(_entry.player_data["race_id"])
		if race_info then GameTooltip:AddLine("Race: " .. race_info.raceName, 1, 1, 1) end

		if _entry.player_data["class_id"] then
			local class_str, _, _ = GetClassInfo(_entry.player_data["class_id"])
			if class_str then GameTooltip:AddLine("Class: " .. class_str, 1, 1, 1) end
		end

		if _entry.player_data["source_id"] then
			local source_id = id_to_npc[_entry.player_data["source_id"]]
			if source_id then
				GameTooltip:AddLine("Killed by: " .. source_id, 1, 1, 1, true)
			elseif environment_damage[_entry.player_data["source_id"]] then
				GameTooltip:AddLine("Died from: " .. environment_damage[_entry.player_data["source_id"]], 1, 1, 1, true)
			end
		end

		if race_name then GameTooltip:AddLine("Race: " .. race_name, 1, 1, 1) end

		if _entry.player_data["map_id"] then
			local map_info = C_Map.GetMapInfo(_entry.player_data["map_id"])
			if map_info then GameTooltip:AddLine("Zone: " .. map_info.name, 1, 1, 1, true) end
		end

		if _entry.player_data["map_pos"] then
			GameTooltip:AddLine("Loc: " .. _entry.player_data["map_pos"], 1, 1, 1, true)
		end

		if _entry.player_data["date"] then
			GameTooltip:AddLine("Date: " .. _entry.player_data["date"], 1, 1, 1, true)
		end

		if _entry.player_data["last_words"] then
			GameTooltip:AddLine("Last words: " .. _entry.player_data["last_words"], 1, 1, 0, true)
		end
		GameTooltip:Show()
	end)

	scroll_frame:SetScroll(0)
	scroll_frame.scrollbar:Hide()
	scroll_frame:AddChild(_entry)
end

function ui.Show()
	death_log_frame.frame:Show()
	death_log_icon_frame:Show()
end

function ui.Hide()
	death_log_frame.frame:Hide()
	death_log_icon_frame:Hide()
end

function ui.Refresh()
	death_log_icon_frame:ClearAllPoints()
	death_log_frame.frame:ClearAllPoints()
	if death_log_frame.frame and hardcore_settings["death_log_pos"] then
		death_log_icon_frame:SetPoint("CENTER", UIParent, "CENTER", hardcore_settings["death_log_pos"]['x'],
			hardcore_settings["death_log_pos"]['y'])
	else
		death_log_icon_frame:SetPoint("CENTER", UIParent, "CENTER", 470, -100)
	end
	death_log_frame.frame:SetPoint("TOPLEFT", death_log_icon_frame, "TOPLEFT", 10, -10)
	death_log_frame.frame:SetFrameStrata("BACKGROUND")
	death_log_frame.frame:Lower()
end

function ui.InsertEntry(player_data)
	for i = 1, 19 do
		if row_entry[i + 1].player_data ~= nil then
			shiftEntry(row_entry[i + 1], row_entry[i])
			if selected and selected == i + 1 then
				row_entry[i + 1]:deselect()
				row_entry[i]:select()
			end
		end
	end
	setEntry(player_data, row_entry[20])
end
