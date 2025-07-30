--[[-----------------------------------------------------------------------------
Deathlog Container
-------------------------------------------------------------------------------]]
local Type, Version = "Deathlog", 30
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, type = pairs, assert, type
local wipe = table.wipe

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Button_OnClick(frame)
	PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
	frame.obj:Hide()
end

local function Frame_OnShow(frame)
	frame.obj:Fire("OnShow")
end

local function Frame_OnClose(frame)
	frame.obj:Fire("OnClose")
end

local function Frame_OnMouseDown(frame)
	AceGUI:ClearFocus()
end

local function Title_OnMouseDown(frame)
	AceGUI:ClearFocus()
end

local function MoverSizer_OnMouseUp(mover)
	local frame = mover:GetParent()
	frame:StopMovingOrSizing()
	local self = frame.obj
	local status = self.status or self.localstatus
	status.width = frame:GetWidth()
	status.height = frame:GetHeight()
	status.top = frame:GetTop()
	status.left = frame:GetLeft()
end

local function SizerSE_OnMouseDown(frame)
	frame:GetParent():StartSizing("BOTTOMRIGHT")
	AceGUI:ClearFocus()
end

local function SizerS_OnMouseDown(frame)
	frame:GetParent():StartSizing("BOTTOM")
	AceGUI:ClearFocus()
end

local function SizerE_OnMouseDown(frame)
	frame:GetParent():StartSizing("RIGHT")
	AceGUI:ClearFocus()
end

local function StatusBar_OnEnter(frame)
	frame.obj:Fire("OnEnterStatusBar")
end

local function StatusBar_OnLeave(frame)
	frame.obj:Fire("OnLeaveStatusBar")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self.frame:SetParent(UIParent)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		self.frame:SetFrameLevel(100) -- Lots of room to draw under it
		self:SetTitle()
		self:SetSubTitle()
		self:SetStatusText()
		self:ApplyStatus()
		self:Show()
        self:EnableResize(true)
	end,

	["OnRelease"] = function(self)
		self.status = nil
		wipe(self.localstatus)
	end,

	["OnWidthSet"] = function(self, width)
		local content = self.content
		local contentwidth = width - 34
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
		self.titlebg:SetWidth(contentwidth - 35)
	end,

	["OnHeightSet"] = function(self, height)
		local content = self.content
		local contentheight = height
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end,

	["SetTitle"] = function(self, title)
		self.titletext:SetText(title)
		-- self.titlebg:SetWidth(contentwidth)
	end,

	["SetSubTitle"] = function (self, subtitle_data)
		local column_offset = 17
		if subtitle_data == nil then return end
		for _,v in ipairs(subtitle_data) do
			self.subtitletext_tbl[v[1]]:SetText(v[1])
			self.subtitletext_tbl[v[1]]:SetPoint("LEFT", self.frame, "TOPLEFT", column_offset, -26)
			column_offset = column_offset + v[2]
		end
	end,

	["SetStatusText"] = function(self, text)
		self.statustext:SetText(text)
	end,

	["Hide"] = function(self)
		self.frame:Hide()
	end,

	["Minimize"] = function(self)
		self.frame:Hide()
		is_minimized = true
	end,

	["IsMinimized"] = function(self)
	  return is_minimized
	end,

	["Maximize"] = function(self)
		self.frame:Show()
		is_minimized = false
	end,

	["Show"] = function(self)
		self.frame:Show()
	end,

	["EnableResize"] = function(self, state)
		local func = state and "Show" or "Hide"
		self.sizer_se[func](self.sizer_se)
		self.sizer_s[func](self.sizer_s)
		self.sizer_e[func](self.sizer_e)
	end,

	-- called to set an external table to store status in
	["SetStatusTable"] = function(self, status)
		assert(type(status) == "table")
		self.status = status
		self:ApplyStatus()
	end,

	["ApplyStatus"] = function(self)
		local status = self.status or self.localstatus
		local frame = self.frame
		self:SetWidth(status.width or 700)
		self:SetHeight(status.height or 500)
		frame:ClearAllPoints()
		if status.top and status.left then
			frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
			frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
		else
			frame:SetPoint("CENTER")
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local FrameBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\CHATFRAME\\ChatFrameBorder",
	tile = false, tileSize = 32, edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 }
}

local PaneBackdrop  = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Glues\\COMMON\\TextPanel-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(100) -- Lots of room to draw under it
	frame:SetBackdrop(PaneBackdrop)
	frame:SetBackdropColor(0, 0, 0, .6)
	frame:SetBackdropBorderColor(1,1,1,1)
	frame:SetSize(250,150)

	if frame.SetResizeBounds then -- WoW 10.0
		frame:SetResizeBounds(400, 200)
	else
		frame:SetMinResize(150, 100)
	end
	frame:SetToplevel(true)
	frame:SetScript("OnShow", Frame_OnShow)
	frame:SetScript("OnHide", Frame_OnClose)
	frame:SetScript("OnMouseDown", Frame_OnMouseDown)

	local closebutton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	closebutton:SetScript("OnClick", Button_OnClick)
	closebutton:SetPoint("BOTTOMRIGHT", -27, 17)
	closebutton:SetHeight(0)
	closebutton:SetWidth(100)
	closebutton:SetText(CLOSE)
	closebutton:Hide()


	local statusbg = CreateFrame("Button", nil, frame, "BackdropTemplate")
	statusbg:SetPoint("BOTTOMLEFT", 15, 15)
	statusbg:SetPoint("BOTTOMRIGHT", -132, 15)
	statusbg:SetHeight(0)
	statusbg:SetBackdrop(PaneBackdrop)
	statusbg:SetBackdropColor(0.1,0.1,0.1)
	statusbg:SetBackdropBorderColor(0.4,0.4,0.4)
	statusbg:SetScript("OnEnter", StatusBar_OnEnter)
	statusbg:SetScript("OnLeave", StatusBar_OnLeave)
	statusbg:Hide()

	local statustext = statusbg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	statustext:SetPoint("TOPLEFT", 7, -2)
	statustext:SetPoint("BOTTOMRIGHT", -7, 2)
	statustext:SetHeight(0)
	statustext:SetJustifyH("LEFT")
	statustext:SetText("")
	statustext:Hide()

	local titlebg = frame:CreateTexture(nil, "OVERLAY")
	titlebg:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-DetailHeaderLeft") 
	titlebg:SetTexCoord(0, 1, 0, 1)
	titlebg:SetPoint("TOP", 0, 12)
	titlebg:SetWidth(100)
	titlebg:SetHeight(40)
	titlebg:Hide()

	local title = CreateFrame("Frame", nil, frame)
	title:EnableMouse(true)
	title:SetScript("OnMouseDown", Title_OnMouseDown)
	title:SetScript("OnMouseUp", MoverSizer_OnMouseUp)
	title:SetAllPoints(titlebg)

	local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titletext:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
	titletext:SetPoint("LEFT", frame, "TOPLEFT", 25, -10)

	local column_types = {"Name", "Guild", "Lvl", "F's", "Race", "Class"}
	local subtitletext_tbl = {} 
	for _,v in ipairs(column_types) do
		subtitletext_tbl[v] = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		subtitletext_tbl[v]:SetPoint("LEFT", frame, "TOPLEFT", 17, -26)
		subtitletext_tbl[v]:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		subtitletext_tbl[v]:SetTextColor(.5,.5,.5);
	end

	local titlebg_l = frame:CreateTexture(nil, "OVERLAY")
	titlebg_l:SetTexture(131080) -- Interface\\DialogFrame\\UI-DialogBox-Header
	titlebg_l:SetTexCoord(0.21, 0.31, 0, 0.63)
	titlebg_l:SetPoint("RIGHT", titlebg, "LEFT")
	titlebg_l:SetWidth(30)
	titlebg_l:SetHeight(40)
	titlebg_l:Hide()

	local titlebg_r = frame:CreateTexture(nil, "OVERLAY")
	titlebg_r:SetTexture(131080) -- Interface\\DialogFrame\\UI-DialogBox-Header
	titlebg_r:SetTexCoord(0.67, 0.77, 0, 0.63)
	titlebg_r:SetPoint("LEFT", titlebg, "RIGHT")
	titlebg_r:SetWidth(30)
	titlebg_r:SetHeight(40)
	titlebg_r:Hide()

	local sizer_se = CreateFrame("Frame", nil, frame)
	sizer_se:SetPoint("BOTTOMRIGHT")
	sizer_se:SetWidth(25)
	sizer_se:SetHeight(25)
	sizer_se:EnableMouse()
	sizer_se:SetScript("OnMouseDown",SizerSE_OnMouseDown)
	sizer_se:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
	line1:SetWidth(14)
	line1:SetHeight(14)
	line1:SetPoint("BOTTOMRIGHT", -8, 8)
	line1:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
	local x = 0.1 * 14/17
	line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

	local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
	line2:SetWidth(8)
	line2:SetHeight(8)
	line2:SetPoint("BOTTOMRIGHT", -8, 8)
	line2:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
	x = 0.1 * 8/17
	line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

	local sizer_s = CreateFrame("Frame", nil, frame)
	sizer_s:SetPoint("BOTTOMRIGHT", -25, 0)
	sizer_s:SetPoint("BOTTOMLEFT")
	sizer_s:SetHeight(25)
	sizer_s:EnableMouse(true)
	sizer_s:SetScript("OnMouseDown", SizerS_OnMouseDown)
	sizer_s:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	local sizer_e = CreateFrame("Frame", nil, frame)
	sizer_e:SetPoint("BOTTOMRIGHT", 0, 25)
	sizer_e:SetPoint("TOPRIGHT")
	sizer_e:SetWidth(25)
	sizer_e:EnableMouse(true)
	sizer_e:SetScript("OnMouseDown", SizerE_OnMouseDown)
	sizer_e:SetScript("OnMouseUp", MoverSizer_OnMouseUp)

	--Container Support
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 3, -33)
	content:SetPoint("BOTTOMRIGHT", 15, 6)

	local widget = {
		localstatus = {},
		titletext   = titletext,
		subtitletext_tbl   = subtitletext_tbl,
		statustext  = statustext,
		titlebg     = titlebg,
		sizer_se    = sizer_se,
		sizer_s     = sizer_s,
		sizer_e     = sizer_e,
		content     = content,
		frame       = frame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	closebutton.obj, statusbg.obj = widget, widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
