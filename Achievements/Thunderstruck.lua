local _G = _G
local thunderstruck_achievement = CreateFrame("Frame")
_G.achievements.Thunderstruck = thunderstruck_achievement

--[[
	The list below can be obtained by entering the following lines in the chat, for each language.
/run LocaleMap = { ["enUS"]="English", ["koKR"]="Korean", ["frFR"]="French", ["deDE"]="German", ["zhCN"]="Chinese (Simplified)", ["esES"]="Spanish", ["zhTW"]="Chinese (Traditional)", ["esMX"]="Spanish", ["ruRU"]="Russian", ["ptBR"]="Portuguese" }
/run f=CreateFrame("Frame") f:SetPoint("TOPLEFT",200,-200) f:SetWidth(256) f:SetHeight(128) f.t=f:CreateTexture() f.t:SetColorTexture(0,0,0.5); f.t:SetAllPoints()
/run CBT = function(b,icon) b[icon]=b:CreateTexture() b[icon]:SetTexture("Interface/Buttons/UI-Panel-MinimizeButton-"..icon) b[icon]:SetAllPoints() b[icon]:SetTexCoord(0.08,0.9,0.1,0.9) return b[icon] end
/run b=CreateFrame("Button",nil,f) b:SetPoint("TOPRIGHT",0,0) b:SetWidth(14) b:SetHeight(14) b:SetScript("OnClick", function() f:Hide() end) b:SetNormalTexture(CBT(b,"Up")) b:SetPushedTexture(CBT(b,"Down")) b:SetHighlightTexture(CBT(b,"Highlight"))
/run s="\t-- Spell names, in "..LocaleMap[GetLocale()].."\n" AddText = function(x) if type(x) == "string" then s=s.."\t-- Forbidden "..x.." spells\n" else n=GetSpellInfo(x) if n then s=s.."\t[\""..n.."\"] = 1,\n" end end end
/run g=CreateFrame("EditBox", nil, f) g:SetMultiLine(true) g:SetAutoFocus(false) g:SetAllPoints() g:SetFontObject(GameTooltipTextSmall) for _,x in ipairs({"fire",1535,8050,8227,8024,8190,3599,2894,51505,"frost",8056,8033}) do AddText(x) end g:SetText(s)

	It opens an edit box with preformatted code. Simply copy/paste the contents of the edit box to the source code below.
]]
local blacklist = {
	-- Spell names, in English
	-- Forbidden fire spells
	["Fire Nova Totem"] = 1,
	["Flame Shock"] = 1,
	["Flametongue Totem"] = 1,
	["Flametongue Weapon"] = 1,
	["Magma Totem"] = 1,
	["Searing Totem"] = 1,
	-- Forbidden frost spells
	["Frost Shock"] = 1,
	["Frostbrand Weapon"] = 1,

	-- Spell names, in French
	-- Forbidden fire spells
	["Totem Nova de feu"] = 1,
	["Horion de flammes"] = 1,
	["Totem Langue de feu"] = 1,
	["Arme Langue de feu"] = 1,
	["Totem de Magma"] = 1,
	["Totem incendiaire"] = 1,
	-- Forbidden frost spells
	["Horion de givre"] = 1,
	["Arme de givre"] = 1,

	-- Spell names, in German
	-- Forbidden fire spells
	["Totem der Feuernova"] = 1,
	["Flammenschock"] = 1,
	["Totem der Flammenzunge"] = 1,
	["Waffe der Flammenzunge"] = 1,
	["Totem der glühenden Magma"] = 1,
	["Totem der Verbrennung"] = 1,
	-- Forbidden frost spells
	["Frostschock"] = 1,
	["Waffe des Frostbrands"] = 1,

	-- Spell names, in Spanish
	-- Forbidden fire spells
	["Tótem Nova de Fuego"] = 1,
	["Choque de llamas"] = 1,
	["Tótem lengua de Fuego"] = 1,
	["Arma lengua de Fuego"] = 1,
	["Tótem de magma"] = 1,
	["Tótem abrasador"] = 1,
	-- Forbidden frost spells
	["Choque de Escarcha"] = 1,
	["Arma Estigma de Escarcha"] = 1,

	-- Spell names, in Portuguese
	-- Forbidden fire spells
	["Totem de Nova de Fogo"] = 1,
	["Choque Flamejante"] = 1,
	["Totem de Labaredas"] = 1,
	["Arma de Labaredas"] = 1,
--	["Totem de Magma"] = 1, -- Same as French
	["Totem Calcinante"] = 1,
	-- Forbidden frost spells
	["Choque Gélido"] = 1,
	["Arma da Marca Gélida"] = 1,

	-- Spell names, in Russian
	-- Forbidden fire spells
	["Тотем кольца огня"] = 1,
	["Огненный шок"] = 1,
	["Тотем языка пламени"] = 1,
	["Оружие языка пламени"] = 1,
	["Тотем магмы"] = 1,
	["Опаляющий тотем"] = 1,
	-- Forbidden frost spells
	["Ледяной шок"] = 1,
	["Оружие ледяного клейма"] = 1,

	-- Spell names, in Korean (untested)
	-- Forbidden fire spells
	["불꽃 회오리 토템"] = 1,
	["화염 충격"] = 1,
	["불꽃의 토템"] = 1,
	["불꽃의 무기"] = 1,
	["용암 토템"] = 1,
	["불타는 토템"] = 1,
	-- Forbidden frost spells
	["냉기 충격"] = 1,
	["냉기의 무기"] = 1,

	-- Spell names, in Chinese (untested)
	-- Forbidden fire spells
	["火焰新星图腾"] = 1,
	["烈焰震击"] = 1,
	["火舌图腾"] = 1,
	["火舌武器"] = 1,
	["熔岩图腾"] = 1,
	["灼热图腾"] = 1,
	-- Forbidden frost spells
	["冰霜震击"] = 1,
	["冰封武器"] = 1,
}


-- General info
thunderstruck_achievement.name = "Thunderstruck"
thunderstruck_achievement.title = "Thunderstruck"
thunderstruck_achievement.class = "Shaman"
thunderstruck_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_thunderstruck.blp"
thunderstruck_achievement.pts = 10
thunderstruck_achievement.description =
	"Complete the Hardcore challenge without at any point using an ability that deals damage other than Nature. Spells, weapon enhancements, or totems that deal Fire or Frost damage are not allowed. All items and consumables that deal damage other than Nature are allowed."

-- Registers
function thunderstruck_achievement:Register(fail_function_executor)
	thunderstruck_achievement:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	thunderstruck_achievement.fail_function_executor = fail_function_executor
end

function thunderstruck_achievement:Unregister()
	thunderstruck_achievement:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

-- Register Definitions
thunderstruck_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local combat_log_payload = { CombatLogGetCurrentEventInfo() }
		-- 2: subevent index, 5: source_name, 14: spell school
		if not (combat_log_payload[5] == nil) then
			if combat_log_payload[5] == UnitName("player") then
				if string.find(combat_log_payload[2], "SPELL_CAST_SUCCESS") ~= nil then
					-- 2 holy, 4 fire, 8 nature, 16 frost, 32 shadow, 64 arcane
					if combat_log_payload[14] ~= 8 then
						if combat_log_payload[13] ~= nil and blacklist[combat_log_payload[13]] ~= nil then
							thunderstruck_achievement.fail_function_executor.Fail(thunderstruck_achievement.name)
						end
					end
				end
			end
		end
	end
end)
