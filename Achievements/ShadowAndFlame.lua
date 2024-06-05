local _G = _G
local _achievement = CreateFrame("Frame")
_G.achievements.ShadowAndFlame = _achievement

_achievement.name = "ShadowAndFlame"
_achievement.title = "Shadow and Flame"
_achievement.class = "Warlock"
_achievement.pts = 10
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_shadow_and_flame.blp"
_achievement.bl_text = "Starting Achievement"
_achievement.description =
	"Complete the Hardcore challenge without at any point casting two shadow or two flame spells in a row during combat."

_achievement.restricted_game_versions = {
	["Cata"] = 1,			-- SetPropagateKeyboardInput function is protected in Cataclysm, can't call it from within combat
}

local shadow_and_flame_frame = nil
local frame_textures = {}

local action_bar_frames = {}


local flame_spells = {
  [348] = 1,
  [11684] = 1,
  [17924] = 1,
  [5740] = 1,
  [6353] = 1,
  [11678] = 1,
  [1949] = 1,
  [25309] = 1,
  [1254] = 1,
  [11683] = 1,
  [5676] = 1,
  [13699] = 1,
  [13701] = 1,
  [11677] = 1,
  [707] = 1,
  [6219] = 1,
  [11668] = 1,
  [17919] = 1,
  [13700] = 1,
  [2941] = 1,
  [17921] = 1,
  [11665] = 1,
  [17920] = 1,
  [17922] = 1,
  [1094] = 1,
  [11667] = 1,
}

local shadow_spells = {
}

local ach_keybinds = {
  ["shadow"] = {},
  ["flame"] = {},
}

local ach_action_slots = {
  ["shadow"] = {},
  ["flame"] = {},
}

local unactive_element = nil

local function updateClickBlocker()
      if unactive_element == nil then 
	for k,_ in pairs(ach_action_slots["flame"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end

	for k,_ in pairs(ach_action_slots["shadow"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end
	return 
      end

      if unactive_element == "shadow" then
	for k,_ in pairs(ach_action_slots["flame"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end

	for k,_ in pairs(ach_action_slots["shadow"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Show()
	  end
	end
      else
	for k,_ in pairs(ach_action_slots["shadow"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end

	for k,_ in pairs(ach_action_slots["flame"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Show()
	  end
	end
      end
end

local function switchElement(spell_id)
  if shadow_spells[spell_id] then
    unactive_element = "shadow"
    frame_textures["shadow"]:Hide()
    frame_textures["flameshadow"]:Hide()
    frame_textures["flame"]:Show()
  elseif flame_spells[spell_id] then
    unactive_element = "flame"
    frame_textures["shadow"]:Show()
    frame_textures["flameshadow"]:Hide()
    frame_textures["flame"]:Hide()
  end
  updateClickBlocker()
end


local function suppressKey(self, key)
   if unactive_element == nil then self:SetPropagateKeyboardInput(true) return end
   if IsShiftKeyDown() then
     key = "s-"..key
   end
   if IsControlKeyDown() then
     key = "c-"..key
   end
   if IsAltKeyDown() then
     key = "a-"..key
   end
   if ach_keybinds[unactive_element][key] then 
     self:SetPropagateKeyboardInput(false)
      if not UIErrorsFrame:TryFlashingExistingMessage(LE_GAME_ERR_SYSTEM, "You cannot cast a "..unactive_element.." yet.") then
	      UIErrorsFrame:AddMessage("You cannot cast a " ..unactive_element.. " spell yet.", 1.0, 0.0, 0, 1.0, LE_GAME_ERR_SYSTEM);
      end
     return
   end

  self:SetPropagateKeyboardInput(true)
end
local f2 = nil 
-- Registers
function _achievement:Register(fail_function_executor)

	shadow_and_flame_frame = CreateFrame("frame")
	shadow_and_flame_frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
	shadow_and_flame_frame:SetSize(40,40)
	shadow_and_flame_frame:SetMovable(true)
	shadow_and_flame_frame:EnableMouse(true)
	shadow_and_flame_frame:Show()
	shadow_and_flame_frame:RegisterForDrag("LeftButton")

	shadow_and_flame_frame:SetScript("OnDragStart", function(self, button)
		self:StartMoving()
	end)
	shadow_and_flame_frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	frame_textures["shadow"] = shadow_and_flame_frame:CreateTexture(nil, "OVERLAY")
	frame_textures["shadow"]:SetPoint("CENTER", shadow_and_flame_frame, "CENTER", -5,4)
	frame_textures["shadow"]:SetDrawLayer("OVERLAY",2)
	frame_textures["shadow"]:SetHeight(40)
	frame_textures["shadow"]:SetWidth(40)
	frame_textures["shadow"]:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_shadow_ele.blp")
	frame_textures["shadow"]:Hide()

	frame_textures["flame"] = shadow_and_flame_frame:CreateTexture(nil, "OVERLAY")
	frame_textures["flame"]:SetPoint("CENTER", shadow_and_flame_frame, "CENTER", -5,4)
	frame_textures["flame"]:SetDrawLayer("OVERLAY",2)
	frame_textures["flame"]:SetHeight(40)
	frame_textures["flame"]:SetWidth(40)
	frame_textures["flame"]:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_flame_ele.blp")
	frame_textures["flame"]:Hide()

	frame_textures["flameshadow"] = shadow_and_flame_frame:CreateTexture(nil, "OVERLAY")
	frame_textures["flameshadow"]:SetPoint("CENTER", shadow_and_flame_frame, "CENTER", -5,4)
	frame_textures["flameshadow"]:SetDrawLayer("OVERLAY",2)
	frame_textures["flameshadow"]:SetHeight(40)
	frame_textures["flameshadow"]:SetWidth(40)
	frame_textures["flameshadow"]:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_shadow_and_flame.blp")
	frame_textures["flameshadow"]:Show()

	for i=1,72 do
	  local button_name = nil 
	  if i < 25 then
	     button_name = "ActionButton"..i
	  elseif i < 37 then
	     button_name = "MultiBarRightButton"..i-24
	  elseif i < 49 then
	     button_name = "MultiBarLeftButton"..i-36
	  elseif i < 61 then
	     button_name = "MultiBarBottomRightButton"..i-48
	  elseif i < 73 then
	     button_name = "MultiBarBottomLeftButton"..i-60
	  end
	  if _G[button_name] ~= nil then
	    action_bar_frames[button_name] = CreateFrame("frame")
	    action_bar_frames[button_name]:SetPoint("CENTER", _G[button_name], "CENTER", 0, 0)
	    action_bar_frames[button_name]:SetSize(_G[button_name]:GetSize())
	    action_bar_frames[button_name]:EnableMouse(false)
	    action_bar_frames[button_name]:SetFrameStrata("HIGH")
	    action_bar_frames[button_name]:SetFrameLevel(_G["ActionButton1"]:GetFrameLevel()+1)
	    action_bar_frames[button_name]:Hide()

	    action_bar_frames[button_name].tex = action_bar_frames[button_name]:CreateTexture(nil, "OVERLAY")
	    action_bar_frames[button_name].tex:SetPoint("CENTER", action_bar_frames[button_name], "CENTER", 0,0)
	    action_bar_frames[button_name].tex:SetDrawLayer("OVERLAY",7)
	    action_bar_frames[button_name].tex:SetHeight(action_bar_frames[button_name]:GetHeight()-7)
	    action_bar_frames[button_name].tex:SetWidth(action_bar_frames[button_name]:GetWidth()-7)
	    action_bar_frames[button_name].tex:SetColorTexture(.25, 0, 0, .8)

	    action_bar_frames[button_name].tex:Show()
	  end
	end



	_achievement:RegisterEvent("SPELLS_CHANGED")
	_achievement:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	_achievement:RegisterEvent("UNIT_SPELLCAST_START")
	_achievement:RegisterEvent("UNIT_SPELLCAST_STOP")
	_achievement:RegisterEvent("PLAYER_REGEN_DISABLED")
	_achievement:RegisterEvent("PLAYER_REGEN_ENABLED")
	_achievement:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	_achievement:GatherSpellList()
	_achievement.fail_function_executor = fail_function_executor

	f2 = CreateFrame("Frame", "Test2", UIParent)
	f2:SetScript("OnKeyDown", suppressKey)

	switchElement()
end

function _achievement:Unregister()
	_achievement:UnregisterEvent("SPELLS_CHANGED")
	_achievement:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function _achievement:GatherSpellList()
	shadow_spells = {}

	ach_keybinds = {
	  ["shadow"] = {},
	  ["flame"] = {},
	}

	ach_action_slots = {
	  ["shadow"] = {},
	  ["flame"] = {},
	}

	local function insertActionSlot(v, element)
	    if v < 25 then 
	      local page_num = GetActionBarPage()
	      if page_num == 1 then
		if GetBindingKey("ACTIONBUTTON"..v) then ach_keybinds[element][GetBindingKey("ACTIONBUTTON"..v)] = 1 end
		ach_action_slots[element]["ActionButton"..v] = 1
	      elseif page_num == 2 then
		if GetBindingKey("ACTIONBUTTON"..v-12) then ach_keybinds[element][GetBindingKey("ACTIONBUTTON"..v-12)] = 1 end
		ach_action_slots[element]["ActionButton"..v-12] = 1
	      end
	    elseif v < 37 then
		if _G["MultiBarRightButton"..v-24].HotKey:GetText() then ach_keybinds[element][_G["MultiBarRightButton"..v-24].HotKey:GetText()] = 1 end
		ach_action_slots[element]["MultiBarRightButton"..v-24] = 1
	    elseif v < 49 then
		if _G["MultiBarLeftButton"..v-36].HotKey:GetText() then ach_keybinds[element][_G["MultiBarLeftButton"..v-36].HotKey:GetText()] = 1 end
		ach_action_slots[element]["MultiBarLeftButton"..v-36] = 1
	    elseif v < 61 then
		if _G["MultiBarBottomRightButton"..v-48].HotKey:GetText() then ach_keybinds[element][_G["MultiBarBottomRightButton"..v-48].HotKey:GetText()] = 1 end
		ach_action_slots[element]["MultiBarBottomRightButton"..v-48] = 1
	    elseif v < 73 then
		if _G["MultiBarBottomLeftButton"..v-60].HotKey:GetText() then ach_keybinds[element][_G["MultiBarBottomLeftButton"..v-60].HotKey:GetText()] = 1 end
		ach_action_slots[element]["MultiBarBottomLeftButton"..v-60] = 1
	    end
	end


	for i = 2, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		for j = offset + 1, offset + numSlots do
			local _,_,_,_,_,_,id = GetSpellInfo(j, "")
			if id == nil then goto next_spell end
			if flame_spells[id] == nil then
			  shadow_spells[id] = 1
			  local action_slots = C_ActionBar.FindSpellActionButtons(id)
			  if action_slots then
			    for _,v in ipairs(action_slots) do
			      insertActionSlot(v, "shadow")
			    end
			  end
			else
			  local action_slots = C_ActionBar.FindSpellActionButtons(id)
			  if action_slots then
			    for _,v in ipairs(action_slots) do
			      insertActionSlot(v, "flame")
			    end
			  end
			end
			::next_spell::
		end
	end
end

local combat_check_timer = nil
local casting_timer = nil

-- Register Definitions
_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "SPELLS_CHANGED" then
		_achievement:GatherSpellList()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
	  local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(arg[3])
	  switchElement(spellID)

	  if combat_check_timer then combat_check_timer:Cancel() end
	  combat_check_timer = C_Timer.NewTimer(3, function()
	    if UnitAffectingCombat("player") ~= true then
	      unactive_element = nil
	      frame_textures["shadow"]:Hide()
	      frame_textures["flameshadow"]:Show()
	      frame_textures["flame"]:Hide()
	      updateClickBlocker()
	    end
	  end)

	elseif event == "UNIT_SPELLCAST_START" then
	  if arg[1] ~= "player" then return end
	  local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(arg[3])
	  if casting_timer then casting_timer:Cancel() end
	  if castTime then
	    casting_timer = C_Timer.NewTimer(max(.5, castTime/1000 - .5), function()
	      switchElement(spellID)
	      casting_timer = nil
	    end)
	  end

	  if combat_check_timer then combat_check_timer:Cancel() end
	  combat_check_timer = C_Timer.NewTimer(3, function()
	    if UnitAffectingCombat("player") ~= true then
	      unactive_element = nil
	      frame_textures["shadow"]:Hide()
	      frame_textures["flameshadow"]:Show()
	      frame_textures["flame"]:Hide()
	      updateClickBlocker()
	    end
	  end)

	elseif event == "UNIT_SPELLCAST_STOP" then
	  casting_timer = nil
	elseif event == "PLAYER_REGEN_ENABLED" then
	  for _,v in pairs(action_bar_frames) do
	    v:EnableMouse(false)
	  end
	  if casting_timer then casting_timer:Cancel() end
	  unactive_element = nil
	  frame_textures["shadow"]:Hide()
	  frame_textures["flameshadow"]:Show()
	  frame_textures["flame"]:Hide()
	  updateClickBlocker()
	elseif event == "PLAYER_REGEN_DISABLED" then
	  for _,v in pairs(action_bar_frames) do
	    v:EnableMouse(true)
	  end
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
	  for k,_ in pairs(ach_action_slots["shadow"]) do
	    if action_bar_frames[k] then
	      action_bar_frames[k]:Hide()
	    end
	  end

	  for k,_ in pairs(ach_action_slots["flame"]) do
	    if action_bar_frames[k] then
	      action_bar_frames[k]:Hide()
	    end
	  end
	  _achievement:GatherSpellList()
	  updateClickBlocker()
	end
end)
