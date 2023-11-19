_G["HardcoreBuildLabel"] = nil
local build_num = select(4, GetBuildInfo())
if build_num > 29999 then
	_G["HardcoreBuildLabel"] = "WotLK"
elseif build_num > 19999 then
	_G["HardcoreBuildLabel"] = "TBC"
else
	_G["HardcoreBuildLabel"] = "Classic"
end
function Hardcore_stringOrNumberToUnicode(val)
	local str
	if Hardcore_IsNumber(val) then
		str = tostring(val)
	else
		str = val
	end

	local unicode = ""
	for i = 1, #str do
		local char = str:sub(i, i)
		unicode = unicode
			.. string.byte(char)
			.. Hardcore_generateRandomString(Hardcore_generateRandomIntegerInRange(2, 3))
	end
	return unicode
end

function Hardcore_tableToUnicode(tbl)
	local unicode = ""
	for i, _ in ipairs(tbl) do
		for k, v in pairs(tbl[i]) do
			unicode = unicode .. Hardcore_stringOrNumberToUnicode(v) .. "%"
		end
		unicode = strsub(unicode, 0, #unicode - 1) .. "?"
	end
	return strsub(unicode, 0, #unicode - 1)
end

function Hardcore_generateRandomString(character_count)
	local str = ""
	for i = 1, character_count do
		str = str .. Hardcore_generateRandomLetter()
	end
	return str
end

function Hardcore_generateRandomLetter()
	local validLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	local randomIndex = math.random(1, #validLetters)  -- Generates a number between 1 and 52
	return validLetters:sub(randomIndex, randomIndex)
end

function Hardcore_generateRandomIntegerInRange(min, max)
	return math.floor(math.random() * (max - min + 1)) + min
end

function Hardcore_map(tbl, f)
	local t = {}
	for k, v in pairs(tbl) do
		t[k] = f(v)
	end
	return t
end

function Hardcore_join(tbl, separator)
	local str = ""
	for k, v in pairs(tbl) do
		if str == "" then
			str = v
		else
			str = str .. separator .. v
		end
	end
	return str
end

-- function borrowed from Questie
function Hardcore_GetAddonVersionInfo(version_string)
	local name = GetAddOnInfo("Hardcore")
	local version

	if version_string then
		version = version_string
	else
		version = GetAddOnMetadata(name, "Version")
	end

	local major, minor, patch = string.match(version, "(%d+)%p(%d+)%p(%d+)")
	local hash = "nil"

	local buildType

	return tonumber(major), tonumber(minor), tonumber(patch), tostring(hash), tostring(buildType)
end

local versionToValue = {}

function Hardcore_GetVersionParts(version_string)
	local cached = versionToValue[version_string]
	if cached then
		return cached.major, cached.minor, cached.patch
	end

	local major, minor, patch = string.match(version_string, "(%d+)%p(%d+)%p(%d+)")
	major = major or 0
	minor = minor or 0
	patch = patch or 0

	versionToValue[version_string] = {
		major = tonumber(major),
		minor = tonumber(minor),
		patch = tonumber(patch),
	}
	local thisVersionParts = versionToValue[version_string]

	return thisVersionParts.major, thisVersionParts.minor, thisVersionParts.patch
end

function Hardcore_GetGreaterVersion(version_stringA, version_stringB)
	local majorA, minorA, patchA = Hardcore_GetVersionParts(version_stringA)
	local majorB, minorB, patchB = Hardcore_GetVersionParts(version_stringB)

	-- Compare Majors
	if majorA > majorB then
		return version_stringA
	elseif majorA < majorB then
		return version_stringB
	else
		-- Compare Minors
		if minorA > minorB then
			return version_stringA
		elseif minorA < minorB then
			return version_stringB
		else
			-- Compare Patches
			if patchA > patchB then
				return version_stringA
			elseif patchA < patchB then
				return version_stringB
			else
				return version_stringA
			end
		end
	end
end

-- Useful for getting full player name
-- Same format as CHAT_MSG_ADDON
function Hardcore_GetPlayerPlusRealmName()
	local longName, serverName = UnitFullName("player")
	local FULL_PLAYER_NAME = longName .. "-" .. serverName

	return FULL_PLAYER_NAME
end

function Hardcore_IsNumber(val)
	return type(val) == "number"
end

function Hardcore_FilterUnique(tbl)
	local hash = {}
	local res = {}

	for _, v in ipairs(tbl) do
		if not hash[v] then
			res[#res + 1] = v
			hash[v] = true
		end
	end

	return res
end


--- Base64 encoding decoding functions START

local dict64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz?!"
local rdict64 = nil

local function Hardcore_Base64EncodeError( zero_padding_len )
  local pad_to = 1
  local rv = ""
  if zero_padding_len ~= nil then
    pad_to = tonumber( zero_padding_len )
  end
  for j=1,pad_to do
    rv = rv .. "$"
  end
  return rv
end  

-- EncodePosIntegerBase64( val, zero_padding_len )
--
-- Encodes a positive value (integer or a string representing a positive integer) into base64 with 0-9,A-Z,a-z,? and ! as characters
-- zero_padding_len can be used to force a specific output string length
-- Negative values and values that do not fit in zero_padding_len characters are represented with 1 or more "$" signs

function Hardcore_EncodePosIntegerBase64( val, zero_padding_len )
  local rv = ""
  local i
  val = tonumber(val)
  if( val == 0 ) then return "0" end
  if( val < 0 ) then return Hardcore_Base64EncodeError( zero_padding_len ) end  
  while val > 0 do
    i = val % 64
    rv = dict64:sub(i+1,i+1) .. rv
    val = tonumber( math.floor( val / 64 ) )
  end
  if zero_padding_len ~= nil then
    pad_to = tonumber( zero_padding_len )
    while rv:len() < pad_to do
      rv = "0" .. rv
    end
    if rv:len() > pad_to then
      return Hardcore_Base64EncodeError( zero_padding_len )  
    end
  end  
  return rv
end

-- Hardcore_DecodePosIntegerBase64( str )
--
-- Decodes a base64 string made with Hardcore_EncodePosIntegerBase64()
-- Error strings with "$" are all decoded as -1

function Hardcore_DecodePosIntegerBase64( str )
  -- Initialize the reverse hash if not already done
  if rdict64 == nil then
    rdict64 = {}
    for i=1, 64 do
      rdict64[dict64:sub(i,i)]=i-1
    end
  end
  -- Check for "invalid code (encoding padding failure)"
  if str == nil or str == "" or str:sub(1,1) == "$" then
    return -1
  end
  -- Decode
  local rv = 0
  for i=1,#str do
    rv = rv * 64
    rv = rv + rdict64[str:sub(i,i)]
  end
  return rv
end

--- Base64 encoding decoding functions END


local _h
function Hardcore_CalcRequiredBits(data)
	local s1 = 0
	local s2 = 0
	for i=1,#data do
		s1 = (s1 + string.byte(string.sub(data,i,i))) % 255;
		s2 = (s2 + s1) % 255;
	end
	return bit.bor(bit.lshift(s2,8), s1)
end

function Hardcore_CalculateResolutionChange()
	-- Determine the necessary resolution change based on the number of bits
	local ds = Hardcore_Character
	local data = ds.time_played .. ds.time_tracked .. #ds.deaths .. #ds.trade_partners .. #ds.bubble_hearth_incidents .. #ds.achievements .. #ds.passive_achievements .. (ds.checksum or "")
	return Hardcore_CalcRequiredBits(data) / 65536		-- Need to touch the lower bit as well!
end

function Hardcore_RecalculateTrackedPercentage()
	-- Recalculate the tracked percentage with improved resolution
	local old_pct = Hardcore_CalculateResolutionChange()
	local new_pct = Hardcore_Character.time_tracked / Hardcore_Character.time_played * 10000.0	-- Upgrade to more visibly appealing value
	return (math.floor(new_pct) + old_pct) / 100.0		-- Clean up
end

function Hardcore_ReadjustTimeResolutions()
	if Hardcore_Character ~= nil then
		-- Improve resolution on these times
		Hardcore_Character.tracked_played_percentage = Hardcore_RecalculateTrackedPercentage()
		Hardcore_Character.last_segment_start_time = Hardcore_Character.last_segment_start_time * 10 + _h
		Hardcore_Character.last_segment_end_time = Hardcore_Character.last_segment_end_time * 10 + (9-_h)
		Hardcore_Character.last_segment_time_res = nil			-- Fix bad habit of shortening variable names
		Hardcore_Character.last_segment_time_resolution = 10
	end
end

function Hardcore_AdjustTimeResolutions()
	if Hardcore_Character ~= nil then
		local i = 0
		local k = 0
		_h = 0
		if Hardcore_Character.last_segment_time_resolution == nil or Hardcore_Character.tracked_played_percentage == nil or Hardcore_Character.tracked_played_percentage == 0 then
			Hardcore_Character.last_segment_time_resolution = 0			-- Fix bad habit of shortening variable names
			return
		end
		if (Hardcore_Character.last_segment_start_time ~= nil and Hardcore_Character.last_segment_start_time >= 9999999999) then
			-- Undo time resolution increase
			_h = Hardcore_Character.last_segment_start_time % 10
			Hardcore_Character.last_segment_start_time = Hardcore_Character.last_segment_start_time / 10
			i = i + 1
		end
		if (Hardcore_Character.last_segment_end_time ~= nil and Hardcore_Character.last_segment_end_time >= 9999999999) then
			-- Undo time resolution increase
			k = Hardcore_Character.last_segment_end_time % 10
			Hardcore_Character.last_segment_end_time = Hardcore_Character.last_segment_end_time / 10
			i = i + 1
		end
		if i == 0 then return end

		local new_tracked = Hardcore_RecalculateTrackedPercentage()
		if (math.abs(new_tracked - Hardcore_Character.tracked_played_percentage) > 1e-8) or (_h ~= (9-k)) then
			if _h < 9 then _h = _h + 1 end
		end
		Hardcore_Character.last_segment_time_resolution = _h
	end
end
