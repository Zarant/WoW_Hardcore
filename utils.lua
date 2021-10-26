function Hardcore_stringToUnicode(str)
	local unicode = ""
	for i = 1, #str do
		local char = str:sub(i, i)
		unicode = unicode..string.byte(char)..Hardcore_generateRandomString(generateRandomIntegerInRange(2, 3))
	end
	return unicode
end

function Hardcore_generateRandomString(character_count)
	local str = ""
	for i = 1, character_count do
		str = str..Hardcore_generateRandomLetter()
	end
	return str
end

function Hardcore_generateRandomLetter()
	local validLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	local randomIndex = math.floor(math.random() * #validLetters)
	return validLetters:sub(randomIndex, randomIndex)
end

function generateRandomIntegerInRange(min, max)
    return math.floor(math.random() * (max - min + 1)) + min;
end
