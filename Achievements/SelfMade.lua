local _G = _G
local self_made_achievement = CreateFrame("Frame")
_G.achievements.SelfMade = self_made_achievement
local player = UnitName("Player")

-- General info
self_made_achievement.name = "SelfMade"
self_made_achievement.title = "Self-Made"
self_made_achievement.class = "All"
self_made_achievement.pts = 25
self_made_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_self_made.blp"
self_made_achievement.description =
	"Complete the Hardcore challenge without at any point equipping an item that you have not crafted yourself. Items your character has conjured (e.g. Firestones) are considered crafted. No items bought, dropped, or rewarded by quests are allowed to be equipped, fishing poles MAY be equipped. The items your character starts with are allowed to be equipped. Bags are equipped items."
local Combine = {
	35,
	36,
	38,
	39,
	40,
	43,
	44,
	45,
	47,
	48,
	49,
	51,
	52,
	53,
	55,
	56,
	57,
	59,
	120,
	121,
	127,
	129,
	139,
	140,
	147,
	148,
	153,
	154,
	1395,
	1396,
	2092,
	2101,		-- Light quiver (starting equipment)
	2102,		-- Small ammo pouch (starting equipment)
	2105,
	2361,
	2362,
	2504,
	2508,
	2512,
	2516,
	2947,
	3111,
	3661,
	6096,
	6097,
	6098,
	6117,
	6118,
	6119,
	6120,
	6121,
	6122,
	6123,
	6124,
	6125,
	6126,
	6127,
	6129,
	6134,
	6135,
	6136,
	6137,
	6138,
	6139,
	6140,
	6144,
	6256,		-- Fishing Pole
	6365,		-- Strong Fishing pole
	6366,		-- Darkwood Fishing pole
	6367,		-- Big Iron Fishing pole
	12225,		-- Blump Family Fishing pole
	19970,		-- Arcanite Fishing pole
	19002,		-- Nat Pagle's Extreme Angler
	12282,
	20891,
	20892,
	20893,
	20894,
	20895,
	20896,
	20897,
	20898,
	20899,
	20900,
	20901,
	20978,
	20982,
	23322,
	23344,
	23345,
	23346,
	23347,
	23348,
	23473,
	23474,
	23475,
	23476,
	23477,
	23478,
	23479,
	24143,
	24145,
	24146,
	25861,
	28979,
	49778,
	50055,
	50057,
	34652,
	34656,
	34651,
	34655,
	34648,
	34650,
	34653,
	34659,
	34649,
	34657,
	34658,
	38147,
	38707,
	52021,
	41165,
	52020,
	41164,
	10512,
	15997,
	23772,
	10513,
	8067,
	8069,
	8068,
}

-- Registers
function self_made_achievement:Register(fail_function_executor)
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("ITEM_UNLOCKED")
	self.fail_function_executor = fail_function_executor
end

function self_made_achievement:Unregister()
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:UnregisterEvent("ITEM_UNLOCKED")
end

-- Efficiency improvement -- don't go through a long list, but use a hash table
local combine_hash = nil
local function GenerateCombineHash()
	if combine_hash == nil then
		combine_hash = {}
		for _, value in ipairs(Combine) do
			combine_hash[ value ] = 1
		end
	end
end
local function IsWhitelisted( item_id )
	GenerateCombineHash()
	if combine_hash[ item_id ] ~= nil then
		return true
	else
		return false
	end
end


-- Check Starting gear function
local function Start(a)
	local item_id = GetInventoryItemID("player", a)
	GameTooltip:Hide() --prevents a hung empty tooltip window
	if IsWhitelisted( item_id ) then
		return true
	end
	return false
end

--Check if the item is selfMade
local function isSelfCreated(...)
	for i = 1, select("#", GameTooltip:GetRegions()) do
		local region = select(i, GameTooltip:GetRegions())
		if region and region:GetObjectType() == "FontString" then
			local text = region:GetText() -- string or nil
			if text ~= nil then
				if string.match(text, player) then
					GameTooltip:Hide() --prevents a hung empty tooltip window
					return true
				end
			end
		end
	end
	GameTooltip:Hide() --prevents a hung empty tooltip window
	return false
end

-- Register Definitions
self_made_achievement:SetScript("OnEvent", function(self, event, ...)
	GameTooltip:SetOwner(WorldFrame, "ANCHOR_CURSOR") -- Anchors the cursor so it ensure we check the right tooltip
	local arg = { ... }
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		if arg[2] == true then -- this arg[2] is checking if the equippable spot is nil
			return
		end
		if arg[1] == 19 then -- This is checking if what you have equipped is a tabard, we cant make those :D
			print("You put on a tabard! You're Stylish.")
			return
		end
		if GetInventoryItemID("player", 0) ~= nil then
			local item_id = GetInventoryItemID("player", 0)
			local item_name, _, _, _, _, _, item_subtype = GetItemInfo(item_id)
			if IsWhitelisted( item_id ) then
				return
			end
			Hardcore:Print("Equipped ammo " .. item_name .. " which isn't self created.")
			self_made_achievement.fail_function_executor.Fail(self_made_achievement.name)
		end
	elseif event == "ITEM_UNLOCKED" and arg[2] == nil and arg[1] ~= 19 then -- checking for nil as it will be that way for gear swap and bag swap, checking for slot 19 as that is the tabard.
		local item_id = GetInventoryItemID("player", arg[1])
		local item_name, _, _, _, _, _, item_subtype = GetItemInfo(item_id)
		GameTooltip:SetInventoryItem("player", arg[1]) -- this arg[1] passes the invSlot to  be checked.
		-- Should these checks fail, the player fails the achievement.
		if isSelfCreated(GameTooltip:GetRegions()) == false then
			if item_subtype == "Fishing Poles" or item_subtype == "Fishing Pole" then
				return
			else
				if Start(arg[1]) == false then
					Hardcore:Print("Equipped " .. item_name .. " which isn't self created.")
					self_made_achievement.fail_function_executor.Fail(self_made_achievement.name)
				end
			end
		end
	end
end)
