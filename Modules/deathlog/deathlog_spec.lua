local deathlog = require('Modules/deathlog/deathlog')
local ui_mock = require('Modules.deathlog.ui_mock')

_G.hardcore_settings = {}
_G.hc_peer_guilds = {}
_G.date = os.date
_G.bit = require("bit32")
_G.GetChannelName = function(name) return 1 end
_G.CTL = {}

local testPlayer = {
	name = "Zunter",
	guild = "Hardcore Academy",
	source_id = "435",
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
	nil)

describe('Deathlog', function()
	before_each(function()
		deathlog.ui = ui_mock
	end)

	after_each(function()
		hardcore_settings["death_log_entries"] = {}
	end)

	it('should encodeMessage and decodeMessage correct data', function()
		local params = testPlayer
		local message = deathlog.encodeMessage(params)
		local playerData = deathlog.decodeMessage(message)

		assert.are.equal(params.name, playerData["name"])
		assert.are.equal(params.guild, playerData["guild"])
		assert.are.equal(params.source_id, tostring(playerData["source_id"]))
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

	it('should send the next message in the queue', function()
		stub(_G.CTL, "SendChatMessage")

		local checksum = "Zunter-17652"
		table.insert(deathlog.broadcast_death_ping_queue, checksum)
		deathlog:sendNextInQueue()
		assert.stub(_G.CTL.SendChatMessage).was_called()
		assert.are.equal(0, #deathlog.broadcast_death_ping_queue)
	end)
end)