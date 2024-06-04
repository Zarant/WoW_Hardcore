local _G = _G
local scavenger_achievement = CreateFrame("Frame")
_G.achievements.Scavenger = scavenger_achievement

-- General info
scavenger_achievement.name = "Scavenger"
scavenger_achievement.title = "Scavenger"
scavenger_achievement.class = "All"
scavenger_achievement.pts = 20
scavenger_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_scavenger.blp"
scavenger_achievement.description =
	"Complete the Hardcore challenge without at any point using, consuming, or equipping an item that you have not looted from a mob, chest, or loot container, or crafted or conjured yourself. You are not allowed to ever buy any items from vendors, nor use, consume, or equip items rewarded by a quest (items provided for a quest can be used, consumed, or equipped). This includes consumables, projectiles, trade goods, and containers. All items you start with can be used, consumed, and equipped, including Hearthstone."
-- Disable achievemnt until the problems with a /reload after vendor purchase and quest completion are fixed
scavenger_achievement.restricted_game_versions = {
	["Classic"] = 1,
	["TBC"] = 1,
	["WotLK"] = 1,
	["Cata"] = 1,
}
scavenger_achievement.blacklist = {}

-- Internal states
scavenger_achievement.item_pushed = false
scavenger_achievement.merchant_updated = false
scavenger_achievement.active = false

local merchant_item_cache_ = {}
local received_item = nil

-- Registers
function scavenger_achievement:Register(fail_function_executor)
	scavenger_achievement:RegisterEvent("MERCHANT_SHOW")
	scavenger_achievement:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	scavenger_achievement:RegisterEvent("MERCHANT_UPDATE")
	scavenger_achievement:RegisterEvent("ITEM_PUSH")
	scavenger_achievement:GenerateBlacklist()
	scavenger_achievement.fail_function_executor = fail_function_executor

	scavenger_achievement.item_pushed = false
	scavenger_achievement.merchant_updated = false
	scavenger_achievement.active = true
end

function scavenger_achievement:Unregister()
	scavenger_achievement:UnregisterEvent("MERCHANT_SHOW")
	scavenger_achievement:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	scavenger_achievement:UnregisterEvent("MERCHANT_UPDATE")
	scavenger_achievement:UnregisterEvent("ITEM_PUSH")

	scavenger_achievement.item_pushed = false
	scavenger_achievement.merchant_updated = false
	scavenger_achievement.active = false
end

function scavenger_achievement:GenerateBlacklist()
	local completed = GetQuestsCompleted()
	for i, v in pairs(completed) do
		for g = 1, 10 do
			local itemName, itemTexture, numItems, quality, isUsable, itemID = GetQuestLogRewardInfo(g, i)
			if itemName then
				scavenger_achievement.blacklist[itemName] = 1
			end
		end
	end
end

local function CheckPurchase()
	if
		scavenger_achievement.item_pushed
		and scavenger_achievement.merchant_updated
		and scavenger_achievement.active
		and received_item
		and merchant_item_cache_[tostring(received_item)]
	then
		scavenger_achievement.fail_function_executor.Fail(scavenger_achievement.name)
	end
end

-- Register Definitions
scavenger_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
	if event == "MERCHANT_SHOW" then
		for i = 1, 12 do
			if _G["MerchantItem" .. i] then
				_G["MerchantItem" .. i]:Hide()
			end
		end
	elseif event == "MERCHANT_UPDATE" then
		scavenger_achievement.merchant_updated = true
		for i = 1, 12 do
			if _G["MerchantItem" .. i] then
				_, texture_path = GetMerchantItemInfo(i)
				if texture_path then
					merchant_item_cache_[tostring(texture_path)] = 1
				end
			end
		end
		C_Timer.After(1.0, function()
			CheckPurchase()
			scavenger_achievement.merchant_updated = false
			merchant_item_cache_ = {}
		end)
	elseif event == "ITEM_PUSH" then
		scavenger_achievement.item_pushed = true
		received_item = arg[2]
		C_Timer.After(1.0, function()
			CheckPurchase()
			scavenger_achievement.item_pushed = false
			received_item = nil
		end)
	elseif event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then
			return
		end
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, _, _, _, item_type, item_subtype, _, _, _, _ = GetItemInfo(item_id)
		if scavenger_achievement.blacklist[item_name] ~= nil then
			Hardcore:Print("Equiped quest reward " .. item_name .. ".")
			scavenger_achievement.fail_function_executor.Fail(scavenger_achievement.name)
		end
	end
end)
