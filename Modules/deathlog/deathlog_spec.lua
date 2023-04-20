_G.hardcore_settings = {}
_G.Recorded_Deaths = {}
_G.hc_peer_guilds = {}
_G.date = os.date
_G.bit = require("bit32")
_G.ChatThrottleLib = {}
_G.C_Map = {}
_G.C_Timer = {
	After = function(_, f) f() end
}

local deathlog = require('Modules.deathlog.deathlog')
local ui_mock = require('Modules.deathlog.ui_mock')
deathlog.ui = ui_mock
require('npc_to_id_classic')

local last_attack_source = "Blackrock Champion"
local testPlayer = {
	name = "Zunter",
	guild = "Hardcore Academy",
	source_id = npc_to_id[last_attack_source],
	race_id = "1",
	class_id = 9,
	level = "17",
	instance_id = nil,
	map_id = 1433,
	map_pos = {
		x = 0.3122,
		y = 0.1521
	},
	loc_str = "",
	guid = "Player-5139-020C481D"
}

local testPlayerData = deathlog.PlayerData(
	testPlayer.name,
	testPlayer.guild,
	testPlayer.source_id,
	testPlayer.race_id,
	testPlayer.class_id,
	testPlayer.level,
	testPlayer.instance_id,
	testPlayer.map_id,
	deathlog.mapPosToString(testPlayer.map_pos),
	nil,
	nil,
	testPlayer.guid)

_G.GetChannelName = function(name) return 1 end
_G.GetServerTime = function() return 1681863205 end
_G.C_Map.GetBestMapForUnit = function(_) return testPlayer.map_id end
_G.C_Map.GetPlayerMapPosition = function(_, _) return testPlayer.map_pos end
_G.GetGuildInfo = function(_) return testPlayer.guild end
_G.UnitRace = function(_) return _, _, testPlayer.race_id end
_G.UnitClass = function(_) return _, _, testPlayer.class_id end
_G.UnitName = function(_) return testPlayer.name end
_G.UnitLevel = function(_) return testPlayer.level end
_G.UnitGUID = function(_) return testPlayer.guid end
_G.GetNormalizedRealmName = function() return "BloodsailBuccaneers" end
_G.GetNumGuildMembers = function() return 10 end
_G.GetGuildRosterInfo = function(_) return testPlayer.name .. "-BloodsailBuccaneers", _, _, tonumber(testPlayer.level), _, _, _, _, _, _, _ end

describe('Deathlog', function()
	before_each(function()
		stub(deathlog, "isValidEntry")
	end)
	after_each(function()
		hardcore_settings["death_log_entries"] = {}
		deathlog.death_ping_lru_cache_tbl = {}
		deathlog.last_attack_source = ""
		deathlog.last_words = ""
		deathlog.broadcast_death_ping_queue = {}
		deathlog.last_words_queue = {}
		deathlog.death_alert_out_queue = {}
		deathlog.death_reports_this_session = {}
	end)

	it('should decodeMessage with a previous version data (no guid)', function()
		local message = "Zunter~Hardcore Academy~435~1~9~17~~1433~0.3122,0.1521~"
		local playerData = deathlog.decodeMessage(message)

		assert.are.equal("Zunter", playerData["name"])
		assert.are.equal("Hardcore Academy", playerData["guild"])
		assert.are.equal("435", tostring(playerData["source_id"]))
		assert.are.equal("1", tostring(playerData["race_id"]))
		assert.are.equal(9, playerData["class_id"])
		assert.are.equal("17", tostring(playerData["level"]))
		assert.are.equal(nil, playerData["instance_id"])
		assert.are.equal(1433, playerData["map_id"])
		assert.are.equal("0.3122,0.1521", playerData["map_pos"])
	end)

	it('should encodeMessage and decodeMessage correct data', function()
		local params = testPlayer
		local message = deathlog.encodeMessage(params)
		local playerData = deathlog.decodeMessage(message)

		assert.are.equal(params.name, playerData["name"])
		assert.are.equal(params.guild, playerData["guild"])
		assert.are.equal(params.source_id, playerData["source_id"])
		assert.are.equal(params.race_id, tostring(playerData["race_id"]))
		assert.are.equal(params.class_id, playerData["class_id"])
		assert.are.equal(params.level, tostring(playerData["level"]))
		assert.are.equal(params.instance_id, playerData["instance_id"])
		assert.are.equal(params.map_id, playerData["map_id"])
		assert.are.equal(deathlog.mapPosToString(params.map_pos), playerData["map_pos"])
	end)

	it('should generate a valid fletcher16 checksum', function()
		local expectedChecksum = "Zunter-17652"

		local params = testPlayer
		local checksum = fletcher16(params.name, params.guild, params.level)

		assert.are.equal(expectedChecksum, checksum)
	end)

	it('should create a death entry', function()
		local checksum = "Zunter-17652"
		deathlog.death_ping_lru_cache_tbl[checksum] = {}
		deathlog.death_ping_lru_cache_tbl[checksum]["player_data"] = testPlayerData
		deathlog.createEntry(checksum)

		assert.are.equal(1, #hardcore_settings["death_log_entries"])
	end)

	it('should alert a player death if faction_wide is enabled', function()
		hardcore_settings.alert_subset = "faction_wide"
		stub(deathlog, "alertIfValid")

		local checksum = "Zunter-17652"
		deathlog.death_ping_lru_cache_tbl[checksum] = {}
		deathlog.death_ping_lru_cache_tbl[checksum]["player_data"] = testPlayerData
		deathlog.createEntry(checksum)

		assert.are.equal(1, #hardcore_settings["death_log_entries"])
		assert.stub(deathlog.alertIfValid).was_called_with(testPlayerData)
	end)

	it('should drain the 3 outbox queues, one message sent per action, pioritizing death ping', function()
		stub(_G.ChatThrottleLib, "SendChatMessage")

		local message = "foo" -- the message on the queues is irrelevant for this test
		table.insert(deathlog.broadcast_death_ping_queue, message)
		table.insert(deathlog.broadcast_death_ping_queue, message)
		table.insert(deathlog.death_alert_out_queue, message)
		table.insert(deathlog.last_words_queue, message)

		-- check that each time we call checkQueuesAndSend the number of chat messages sent only goes up by 1
		-- first 2 calls will drain death_ping_queue
		deathlog:checkQueuesAndSend()
		assert.stub(_G.ChatThrottleLib.SendChatMessage).was.called(1)
		deathlog:checkQueuesAndSend()
		assert.stub(_G.ChatThrottleLib.SendChatMessage).was.called(2)
		assert.are.equal(0, #deathlog.broadcast_death_ping_queue)

		deathlog:checkQueuesAndSend()
		assert.stub(_G.ChatThrottleLib.SendChatMessage).was.called(3)
		assert.are.equal(0, #deathlog.death_alert_out_queue)

		deathlog:checkQueuesAndSend()
		assert.stub(_G.ChatThrottleLib.SendChatMessage).was.called(4)
		assert.are.equal(0, #deathlog.last_words_queue)
	end)

	it('should store the player guid if a valid death message is received', function()
		_G.hardcore_settings["record_other_deaths"] = true
		
		local message = deathlog.encodeMessage(testPlayer)
		deathlog.receiveChannelMessage(testPlayer.name, message)

		assert.are.equal(1, #Recorded_Deaths)
		local recordedDeath = Recorded_Deaths[1]
		assert.are.equal(testPlayer.name, recordedDeath.sender)
		assert.are.equal(testPlayer.guid, recordedDeath.guid)
		assert.are.equal(testPlayer.source_id, recordedDeath.source_id)
		assert.are.equal(_G.GetServerTime(), recordedDeath.time)
		assert.are.equal(_G.GetServerTime(), deathlog.sender_reported_death_timestamp[testPlayer.name])

		-- check that receiving the same message again within 5 mins does not record another entry
		deathlog.receiveChannelMessage(testPlayer.name, message)
		assert.are.equal(1, #Recorded_Deaths)
	end)

	it('should broadcast a death ping when receiving a death message', function()
		local message = deathlog.encodeMessage(testPlayer)
		deathlog.receiveChannelMessage(testPlayer.name, message)
		
		local expectedChecksum = fletcher16(testPlayer.name, testPlayer.guild, testPlayer.level)
		assert.are.equal(1, #deathlog.broadcast_death_ping_queue)
		assert.are.equal(expectedChecksum, deathlog.broadcast_death_ping_queue[1])
	end)

	it('should emit a death message on PLAYER_DEAD event', function()
		local expectedDeathMsg = deathlog.encodeMessage(testPlayer)
		local lastWords = "foobar"
		local expectedLastWordsMsg = fletcher16(testPlayer.name, testPlayer.guild, testPlayer.level) .. "~" .. lastWords .. "~"

		deathlog.last_attack_source = last_attack_source
		deathlog.last_words = lastWords
		deathlog:PLAYER_DEAD()

		assert.are.equal(1, #deathlog.death_alert_out_queue)
		assert.are.equal(expectedDeathMsg, deathlog.death_alert_out_queue[1])

		assert.are.equal(1, #deathlog.last_words_queue)
		assert.are.equal(expectedLastWordsMsg, deathlog.last_words_queue[1])
	end)
end)
