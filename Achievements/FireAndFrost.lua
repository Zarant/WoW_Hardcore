local _G = _G
local _achievement = CreateFrame("Frame")
_G.achievements.ElementalBalance = _achievement

_achievement.name = "ElementalBalance"
_achievement.title = "Elemental Balance"
_achievement.class = "Mage"
_achievement.pts = 10
_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_fireandfrost.blp"
_achievement.bl_text = "Starting Achievement"
_achievement.description =
	"Complete the Hardcore challenge without at any point casting two elemental damage spells of the same element (fire or ice) in a row. Arcane spells that deal damage are not allowed to be cast."

_achievement.restricted_game_versions = {
	["Cata"] = 1,			-- SetPropagateKeyboardInput function is protected in Cataclysm, can't call it from within combat
}

local fire_and_frost_frame = nil
local frame_textures = {}

local action_bar_frames = {}


local frost_spells = {
}

local fire_spells = {
}

local arcane_spells = {
  [5143] = 1,
  [5144] = 1,
  [5145] = 1,
  [8416] = 1,
  [8417] = 1,
  [10211] = 1,
  [10212] = 1,
  [25345] = 1,
  [1449] = 1,
  [8437] = 1,
  [8438] = 1,
  [8439] = 1,
  [10201] = 1,
  [10202] = 1,
}

local ach_keybinds = {
  ["fire"] = {},
  ["frost"] = {},
  ["arcane"] = {},
}

local ach_action_slots = {
  ["fire"] = {},
  ["frost"] = {},
  ["arcane"] = {},
}

local unactive_element = nil

local function updateClickBlocker()
      for k,_ in pairs(ach_action_slots["arcane"]) do
	if action_bar_frames[k] then
	  action_bar_frames[k]:Show()
	end
      end

      if unactive_element == nil then 
	for k,_ in pairs(ach_action_slots["frost"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end

	for k,_ in pairs(ach_action_slots["fire"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end
	return 
      end

      if unactive_element == "fire" then
	for k,_ in pairs(ach_action_slots["frost"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end

	for k,_ in pairs(ach_action_slots["fire"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Show()
	  end
	end
      else
	for k,_ in pairs(ach_action_slots["fire"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Hide()
	  end
	end

	for k,_ in pairs(ach_action_slots["frost"]) do
	  if action_bar_frames[k] then
	    action_bar_frames[k]:Show()
	  end
	end
      end
end

local function switchElement(spell_id)
  if fire_spells[spell_id] then
    unactive_element = "fire"
    frame_textures["fire"]:Hide()
    frame_textures["frostfire"]:Hide()
    frame_textures["frost"]:Show()
  elseif frost_spells[spell_id] then
    unactive_element = "frost"
    frame_textures["fire"]:Show()
    frame_textures["frostfire"]:Hide()
    frame_textures["frost"]:Hide()
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

   if ach_keybinds["arcane"][key] then 
     self:SetPropagateKeyboardInput(false)
      if not UIErrorsFrame:TryFlashingExistingMessage(LE_GAME_ERR_SYSTEM, "You cannot cast an arcane spell which deals damage.") then
	      UIErrorsFrame:AddMessage("You cannot cast an arcane spell which deals damage.", 1.0, 0.0, 0, 1.0, LE_GAME_ERR_SYSTEM);
      end
     return
   end

  self:SetPropagateKeyboardInput(true)
end
local f2 = nil 
-- Registers
function _achievement:Register(fail_function_executor)

	fire_and_frost_frame = CreateFrame("frame")
	fire_and_frost_frame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
	fire_and_frost_frame:SetSize(40,40)
	fire_and_frost_frame:SetMovable(true)
	fire_and_frost_frame:EnableMouse(true)
	fire_and_frost_frame:Show()
	fire_and_frost_frame:RegisterForDrag("LeftButton")

	fire_and_frost_frame:SetScript("OnDragStart", function(self, button)
		self:StartMoving()
	end)
	fire_and_frost_frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	frame_textures["fire"] = fire_and_frost_frame:CreateTexture(nil, "OVERLAY")
	frame_textures["fire"]:SetPoint("CENTER", fire_and_frost_frame, "CENTER", -5,4)
	frame_textures["fire"]:SetDrawLayer("OVERLAY",2)
	frame_textures["fire"]:SetHeight(40)
	frame_textures["fire"]:SetWidth(40)
	frame_textures["fire"]:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_fireball.blp")
	frame_textures["fire"]:Hide()

	frame_textures["frost"] = fire_and_frost_frame:CreateTexture(nil, "OVERLAY")
	frame_textures["frost"]:SetPoint("CENTER", fire_and_frost_frame, "CENTER", -5,4)
	frame_textures["frost"]:SetDrawLayer("OVERLAY",2)
	frame_textures["frost"]:SetHeight(40)
	frame_textures["frost"]:SetWidth(40)
	frame_textures["frost"]:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_frost.blp")
	frame_textures["frost"]:Hide()

	frame_textures["frostfire"] = fire_and_frost_frame:CreateTexture(nil, "OVERLAY")
	frame_textures["frostfire"]:SetPoint("CENTER", fire_and_frost_frame, "CENTER", -5,4)
	frame_textures["frostfire"]:SetDrawLayer("OVERLAY",2)
	frame_textures["frostfire"]:SetHeight(40)
	frame_textures["frostfire"]:SetWidth(40)
	frame_textures["frostfire"]:SetTexture("Interface\\Addons\\Hardcore\\Media\\icon_fireandfrost.blp")
	frame_textures["frostfire"]:Show()

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
	frost_spells = {}
	fire_spells = {}

	ach_keybinds = {
	  ["fire"] = {},
	  ["frost"] = {},
	  ["arcane"] = {},
	}

	ach_action_slots = {
	  ["fire"] = {},
	  ["frost"] = {},
	  ["arcane"] = {},
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


	for i = 1, 4 do
		local name, texture, offset, numSlots, isGuild, offspecID = GetSpellTabInfo(i)
		if name == "Fire" then 
			for j = offset + 1, offset + numSlots do
				local _,_,_,_,_,_,id = GetSpellInfo(j, "")
				fire_spells[id] = 1
				local action_slots = C_ActionBar.FindSpellActionButtons(id)
				if action_slots then
				  for _,v in ipairs(action_slots) do
				    insertActionSlot(v, "fire")
				  end
				end
			end
		end

		if name == "Frost" then 
			for j = offset + 1, offset + numSlots do
				local _,_,_,_,_,_,id = GetSpellInfo(j, "")
				frost_spells[id] = 1
				local action_slots = C_ActionBar.FindSpellActionButtons(id)
				if action_slots then
				  for _,v in ipairs(action_slots) do
				    insertActionSlot(v, "frost")
				  end
				end
			end
		end
	end


	-- Arcane missiles and arcane explosion
	for id,_ in pairs(arcane_spells) do
		local action_slots = C_ActionBar.FindSpellActionButtons(id)
		if action_slots then
		  for _,v in ipairs(action_slots) do
		    if GetBindingKey("ACTIONBUTTON"..v) then ach_keybinds["arcane"][GetBindingKey("ACTIONBUTTON"..v)] = 1 end
		    ach_action_slots["arcane"]["ActionButton"..v] = 1
		  end
		end
	end
end

local casting_timer = nil
local combat_check_timer = nil

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
	      frame_textures["fire"]:Hide()
	      frame_textures["frostfire"]:Show()
	      frame_textures["frost"]:Hide()
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
	      frame_textures["fire"]:Hide()
	      frame_textures["frostfire"]:Show()
	      frame_textures["frost"]:Hide()
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
	  frame_textures["fire"]:Hide()
	  frame_textures["frostfire"]:Show()
	  frame_textures["frost"]:Hide()
	  updateClickBlocker()
	elseif event == "PLAYER_REGEN_DISABLED" then
	  for _,v in pairs(action_bar_frames) do
	    v:EnableMouse(true)
	  end
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
	  for k,_ in pairs(ach_action_slots["fire"]) do
	    if action_bar_frames[k] then
	      action_bar_frames[k]:Hide()
	    end
	  end

	  for k,_ in pairs(ach_action_slots["frost"]) do
	    if action_bar_frames[k] then
	      action_bar_frames[k]:Hide()
	    end
	  end

	  for k,_ in pairs(ach_action_slots["arcane"]) do
	    if action_bar_frames[k] then
	      action_bar_frames[k]:Hide()
	    end
	  end
	  _achievement:GatherSpellList()
	  updateClickBlocker()
	end
end)
