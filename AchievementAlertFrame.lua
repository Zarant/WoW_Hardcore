achievement_alert_handler = {}

-- Animated border
local test_frame = CreateFrame("Frame")
test_frame:SetSize(400, 400)
test_frame:SetHeight(400)
test_frame:SetWidth(400)
test_frame:SetPoint("CENTER", UIParent, 0, 0)
local tex = test_frame:CreateTexture()
tex:SetHeight(200)
tex:SetWidth(400)
tex:SetTexture("Interface\\Addons\\Hardcore\\Media\\achievement_animation_spritesheet.blp")
tex:SetDrawLayer("OVERLAY", 4)
tex:SetPoint("CENTER", test_frame, 0, -100)
tex:SetParent(UIParent)

local tex2 = test_frame:CreateTexture()
tex2:SetHeight(200)
tex2:SetWidth(400)
tex2:SetTexture("Interface\\Addons\\Hardcore\\Media\\achievement_animation_spritesheet2.blp")
tex2:SetDrawLayer("OVERLAY", 4)
tex2:SetPoint("CENTER", test_frame, 0, -100)
tex2:SetParent(UIParent)

local hc_ring_tex = test_frame:CreateTexture()
hc_ring_tex:SetTexture("Interface\\Addons\\Hardcore\\Media\\hc-ring.blp")
hc_ring_tex:SetDrawLayer("OVERLAY", 6)

hc_ring_tex:SetHeight(130)
hc_ring_tex:SetWidth(130)
hc_ring_tex:SetPoint("CENTER", test_frame, -112, -99)
hc_ring_tex:SetParent(UIParent)

local achievement_icon_texture = test_frame:CreateTexture()
achievement_icon_texture:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_absent_minded_prospector.blp")
achievement_icon_texture:SetDrawLayer("OVERLAY", 5)
achievement_icon_texture:SetHeight(62)
achievement_icon_texture:SetWidth(62)
achievement_icon_texture:SetPoint("CENTER", test_frame, -107, -104)
achievement_icon_texture:SetParent(UIParent)

local achievement_icon_texture_white_ring = test_frame:CreateTexture()
achievement_icon_texture_white_ring:SetTexture("Interface\\Addons\\Hardcore\\Media\\hcring_white.blp")
achievement_icon_texture_white_ring:SetDrawLayer("OVERLAY", 7)
achievement_icon_texture_white_ring:SetHeight(130)
achievement_icon_texture_white_ring:SetWidth(130)
achievement_icon_texture_white_ring:SetPoint("CENTER", test_frame, -112, -99)
achievement_icon_texture_white_ring:SetParent(UIParent)

local achievement_title_text = test_frame:CreateFontString(nil, "OVERLAY")
achievement_title_text:SetFont("Interface\\AddOns\\Hardcore\\Media\\BreatheFire.ttf", 14, "")
-- achievement_title_text:SetFont("Fonts\\FRIZQT__.TTF", 13)
achievement_title_text:SetTextColor(0.8, 0.8, 0.8, 1)
achievement_title_text:SetPoint("CENTER", 25, -94)
achievement_title_text:SetText("Protect the Prospector")
achievement_title_text:SetWidth(350)

test_frame:Hide()
tex:Hide()
tex2:Hide()
hc_ring_tex:Hide()
achievement_icon_texture:Hide()
achievement_icon_texture_white_ring:Hide()

-- _G.HCTextureUtils:AddToAnimationFrames("TestFrame", tex, _G.HCTextureInfo.TestFrame.test_sprite.AnimationInfo)

function achievement_alert_handler:ShowTimed(_time)
	local counter = 0

	test_frame:Show()
	hc_ring_tex:Show()
	achievement_icon_texture:Show()
	achievement_icon_texture_white_ring:Show()
	C_Timer.NewTicker(1 / 30, function(self)
		if counter < 32 then
			tex:SetTexCoord(counter * 1 / 32, (counter + 1) * 1 / 32, 0, 1)
			tex:Show()
			tex2:Hide()
		else
			tex2:SetTexCoord((counter - 32) * 1 / 32, (counter + 1 - 32) * 1 / 32, 0, 1)
			tex2:Show()
			tex:Hide()
		end
		if counter > 30 then
			achievement_title_text:SetTextColor(0.8, 0.8, 0.8, 1)
			achievement_icon_texture:SetVertexColor(1, 1, 1, min(1, counter * 5 / 30))
			hc_ring_tex:SetVertexColor(1, 1, 1, min(1, counter * 5 / 30))
			achievement_icon_texture_white_ring:SetVertexColor(1, 1, 1, max(0, min(1, (50 - counter) / 30)))
		else
			achievement_title_text:SetTextColor(1, 1, 1, 0)
			achievement_icon_texture:SetVertexColor(1, 1, 1, 0)
			hc_ring_tex:SetVertexColor(1, 1, 1, 0)
			achievement_icon_texture_white_ring:SetVertexColor(1, 1, 1, min(1, (counter * 1.5 / 30)))
		end
		counter = counter + 1
		if counter > 59 then
			self:Cancel()
		end
	end)

	C_Timer.After(_time, function()
		test_frame:Hide()
		tex:Hide()
		tex2:Hide()
		hc_ring_tex:Hide()
		achievement_icon_texture:Hide()
		achievement_icon_texture_white_ring:Hide()
	end)
end

local static_offset_x = 0
local static_offset_y = 0
local modified_offset_x = 0
local modified_offset_y = 0

local achievement_alert_frame = CreateFrame("frame")
achievement_alert_frame:SetHeight(200)
achievement_alert_frame:SetWidth(400)
achievement_alert_frame:SetPoint(
	"CENTER",
	UIParent,
	static_offset_x + modified_offset_x,
	static_offset_y + modified_offset_y
)
local t = achievement_alert_frame:CreateTexture()
local text = achievement_alert_frame:CreateFontString(nil, "OVERLAY")
text:SetFont("Interface\\AddOns\\Hardcore\\Media\\BreatheFire.ttf", 26, "")
text:SetTextColor(0.98, 0.86, 0, 1)
text:SetPoint("CENTER", 0, -55)
text:SetText("long long long long long long long long long long.")
text:SetWidth(350)

local achievement_alert_frame_icon = CreateFrame("frame")
achievement_alert_frame_icon:SetHeight(105)
achievement_alert_frame_icon:SetWidth(105)
achievement_alert_frame_icon:SetPoint("CENTER", achievement_alert_frame, 0, 16)

local t2 = achievement_alert_frame_icon:CreateTexture()

t:SetAllPoints()
t:SetTexture("Interface\\Addons\\Hardcore\\Media\\alert_border_alpha.blp")
t:SetSize(1000, 1000)
t:SetDrawLayer("OVERLAY", 7)
t:SetParent(UIParent)
achievement_alert_frame:Hide()
t:Hide()

t2:SetAllPoints()
t2:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_absent_minded_prospector.blp")
t2:SetSize(1000, 1000)
t2:SetDrawLayer("OVERLAY", 6)
t2:SetParent(UIParent)
achievement_alert_frame_icon:Hide()

function achievement_alert_handler:Hide()
	t:Hide()
	t2:Hide()
	achievement_alert_frame:Hide()
	achievement_alert_frame_icon:Hide()
end

function achievement_alert_handler:Show()
	t:Show()
	t2:Show()
	achievement_alert_frame:Show()
	achievement_alert_frame_icon:Show()
end

function achievement_alert_handler:SetIcon(_icon_path)
	achievement_icon_texture:SetTexture(_icon_path)
end

function achievement_alert_handler:SetMsg(_msg)
	achievement_title_text:SetText(_msg)
end

function achievement_alert_handler:SetScale(_scale)
	achievement_alert_frame:SetHeight(200 * _scale)
	achievement_alert_frame:SetWidth(400 * _scale)
	achievement_alert_frame_icon:SetHeight(105 * _scale)
	achievement_alert_frame_icon:SetWidth(105 * _scale)
	achievement_alert_frame_icon:SetPoint("CENTER", achievement_alert_frame, 0, 16 * _scale)
end

function achievement_alert_handler:ApplySettings(_x_offset, _y_offset, _scale)
	modified_offset_x = _x_offset
	modified_offset_y = _y_offset
	-- achievement_alert_handler:SetScale(_scale)
	test_frame:SetPoint("CENTER", UIParent, static_offset_x + modified_offset_x, static_offset_y + modified_offset_y)
end

achievement_alert_handler:SetScale(1.0)
achievement_alert_handler:Hide()
-- achievement_alert_handler:ShowTimed(5.0)
