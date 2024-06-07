local frame = CreateFrame("Frame", nil, UIParent)

frame:SetParent(UIParent)
frame:SetSize(300, 115)
frame:SetPoint("TOP", 0, -150)
frame:Hide()

frame.texture = frame:CreateTexture(nil, "OVERLAY")
frame.texture:SetAllPoints()
frame.texture:SetDrawLayer("OVERLAY", 6)
frame.texture:SetTexture("Interface\\LootFrame\\LegendaryToast")
frame.texture:SetTexCoord(0.35, 1, 0, 0.24)
frame.texture:SetVertexColor(1000, 10, 1, 1)
frame.texture:SetAlpha(1)
frame.texture:Show()

frame.loottoast = frame:CreateTexture(nil, "OVERLAY")
frame.loottoast:SetPoint("Center", 20, 0)
frame.loottoast:SetWidth(frame:GetWidth() * 0.85)
frame.loottoast:SetHeight(frame:GetHeight() * 0.9)
frame.loottoast:SetDrawLayer("OVERLAY", 7)
frame.loottoast:SetTexture("Interface\\LootFrame\\LootToast")
frame.loottoast:SetTexCoord(0, 0.28, 0, 0.42)
frame.loottoast:SetBlendMode("ADD")
frame.loottoast:SetVertexColor(1, 1, 1, 0.5)
frame.loottoast:Show()

frame.icon = frame:CreateTexture(nil, "OVERLAY")
frame.icon:SetPoint("LEFT", 65, 5)
frame.icon:SetHeight(frame:GetHeight() * 0.44)
frame.icon:SetWidth(frame:GetHeight() * 0.44)
frame.icon:SetDrawLayer("OVERLAY", 5)
frame.icon:SetTexture("Interface\\ICONS\\ClassIcon_Warrior")
frame.icon:Show()

frame.iconback = frame:CreateTexture(nil, "OVERLAY")
frame.iconback:SetPoint("CENTER", frame.icon, -13, 10)
frame.iconback:SetHeight(frame:GetHeight() * 2)
frame.iconback:SetWidth(frame:GetHeight() * 2)
frame.iconback:SetDrawLayer("OVERLAY", 4)
frame.iconback:SetTexture("Interface\\LootFrame\\LegendaryToast")
frame.iconback:SetTexCoord(0, 0.35, 0, 0.35)
frame.iconback:Show()

frame.swipe = frame:CreateTexture(nil, "OVERLAY")
frame.swipe:SetPoint("LEFT", frame, 50, 0)
frame.swipe:SetHeight(frame:GetHeight() * 0.6)
frame.swipe:SetWidth(frame:GetHeight() * 1.4)
frame.swipe:SetDrawLayer("OVERLAY", 7)
frame.swipe:SetTexture("Interface\\LootFrame\\LootToast")
frame.swipe:SetTexCoord(0.58, 0.73, 0.58, 0.87)
frame.swipe:SetBlendMode("ADD")
frame.swipe:Show()

frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.title:SetPoint("TOPLEFT", 120, -45)
frame.title:SetTextColor(255 / 255, 128 / 255, 0, 1)
frame.title:SetJustifyH("LEFT")
frame.title:SetFont("Fonts\\blei00d.TTF", 28, "OUTLINE")

frame.desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.desc:SetPoint("TOP", 10, -30)
frame.desc:SetTextColor(1, 0.8, 0, 1)
frame.desc:SetJustifyH("LEFT")
frame.desc:SetFont("Fonts\\blei00d.TTF", 14, "")
frame.desc:SetText("New level 60!")

local ticker_handler = nil
local main_alpha = 0
local glow_alpha = 0
local swipe_glow = 0
local icon_back_alpha = 0
local icon_back_scale = 1
local flip = 1
local flip2 = 1
local start_time = nil
local swipe_x = 0
function HC_showLegendaryFrame(name, class, level)
	frame.desc:SetText("New level " .. tostring(level) .. "!")
	if class then
		frame.icon:SetTexture("Interface\\ICONS\\ClassIcon_" .. class)
	end
	start_time = time()

	if #name < 11 then
		frame.title:SetFont("Fonts\\blei00d.TTF", 28, "OUTLINE")
	else
		frame.title:SetFont("Fonts\\blei00d.TTF", 24, "OUTLINE")
	end
	frame.title:SetText(name)
	frame:Show()
	main_alpha = 0
	glow_alpha = 0
	swipe_glow = 0
	icon_back_alpha = 0
	icon_back_scale = 1
	flip = 1
	flip2 = 1
	swipe_x = 0
	PlaySound(623)
	if ticker_handler then
		ticker_handler:Cancel()
	end

	frame.iconback:SetHeight(frame:GetHeight() * 2)
	frame.iconback:SetWidth(frame:GetHeight() * 2)

	ticker_handler = C_Timer.NewTicker(0.01, function()
		main_alpha = main_alpha + 0.05
		if main_alpha > 1 then
			main_alpha = 1
		end

		glow_alpha = glow_alpha + flip * 0.05
		if glow_alpha > 1 then
			glow_alpha = 1
			flip = -1
		end
		if flip == -1 then
			swipe_glow = swipe_glow + 0.05
			icon_back_alpha = icon_back_alpha + flip2 * 0.05
			if icon_back_alpha > 1 then
				flip2 = -0.35
				icon_back_scale = 0.995
			end

			if flip2 < 0 then
				swipe_x = swipe_x + 5
				swipe_glow = swipe_glow - 0.09
			end
		end
		frame.icon:SetAlpha(main_alpha)
		frame.texture:SetAlpha(main_alpha)
		frame.swipe:SetAlpha(max(min(swipe_glow / 3.0, 1.0), 0.0))
		frame.swipe:SetPoint("LEFT", frame, 50 + swipe_x, 0)
		frame.loottoast:SetAlpha(max(min(glow_alpha, 1.0), 0.0))
		frame.iconback:SetAlpha(max(min(icon_back_alpha, 1.0), 0.0))
		frame.iconback:SetWidth(frame.iconback:GetWidth() * icon_back_scale)
		frame.iconback:SetHeight(frame.iconback:GetHeight() * icon_back_scale)
		if time() - start_time > 8 then
			frame:Hide()
			ticker_handler:Cancel()
		end
	end)
end
