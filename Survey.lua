-- Survey.lua
-- Survey functionality for Guild Masters for the WOW Hardcore addon
-- Written by Frank de Jong

local guild_master = ""

-- Some local variables defined in Hardcore.lua -- Make sure these are the same as in Hardcore.lua!!
local CTL = _G.ChatThrottleLib
local COMM_NAME = "HardcoreAddon" 				-- Overwritten in SurveyInitiate()
local COMM_COMMAND_DELIM = "$" 					-- Overwritten in SurveyInitiate()
local COMM_FIELD_DELIM = "|" 					-- Overwritten in SurveyInitiate()
local SURVEY_REQ_CMD = "SURVEY_REQ" 			-- Overwritten in SurveyInitiate()
local SURVEY_ACK_CMD = "SURVEY_ACK" 			-- Overwritten in SurveyInitiate()



----- LOCAL FUNCTIONS ----------

local function SurveyDetermineGuildMaster()

    local num_members = GetNumGuildMembers()
    local name,rank_index
    for i = 1, num_members do
        name, _, rank_index = GetGuildRosterInfo(i)
        if rank_index == 0 then
            return name
        end
    end
    return "(unknown)"
end

local function SurveyGetLongName()

    local short_name, realm_name

    short_name, realm_name = UnitFullName("player")
    return short_name .. "-" .. realm_name

end


----- GLOBAL FUNCTIONS ----------


-- SurveyReceiveRequest( args )
--
-- Receives a survey request, and if sent by a guild master, sends the requested info
-- Called from Hardcore.lua

function SurveyReceiveRequest(data, sender)

    -- Fool proofing
    if Hardcore_Character == nil then
        return
    end

    -- Check if this came from the GM
    if guild_master == "" then
        guild_master = SurveyDetermineGuildMaster()
    end
    if sender ~= guild_master then
        Hardcore:Debug( "Received a survey request from someone (" .. sender .. ") who is not the GM" )
        return
    end

    -- Unpack the request
    local id, wait_time, variable = string.split(COMM_FIELD_DELIM, data)
	-- Handle malformed requests
	if id == nil or (tonumber( id ) == nil) or wait_time == nil or (tonumber( wait_time ) == nil) or variable == nil or variable == "" then
        Hardcore:Debug( "Received a malformed survey request" )
		return
	end
    local wait_time_max = max( 5, tonumber( wait_time ) )
    local survey_id = tonumber( id )
    if survey_id <= 0 then
        return
    end

    -- Look up the variable
    local value_to_send
    if variable == "guid" then
        value_to_send = "(secret)"
    elseif variable == "money" then
        value_to_send = GetMoney()
    else
        if type( Hardcore_Character[ variable ] ) == "table" then
            value_to_send = #Hardcore_Character[ variable ]
        else
            value_to_send = Hardcore_Character[ variable ]
        end
    end
    if value_to_send == nil then
        Hardcore:Debug( "Received a survey request for unknown variable " .. variable )
        return
    end

    -- Now generate the reply
    math.random(); math.random();
    local my_wait_time = math.floor( math.random(wait_time_max))
    Hardcore:Debug( "Waiting for " .. my_wait_time .. " seconds")

    C_Timer.After(my_wait_time, function()
        local mytag = "(unknown)"
        if Hardcore_Settings.hardcore_player_name ~= nil and Hardcore_Settings.hardcore_player_name ~= "" then
            mytag = Hardcore_Settings.hardcore_player_name
        end
        local comm_msg = SURVEY_ACK_CMD .. COMM_COMMAND_DELIM .. survey_id .. COMM_FIELD_DELIM .. mytag .. COMM_FIELD_DELIM .. value_to_send
        CTL:SendAddonMessage("BULK", COMM_NAME, comm_msg, "WHISPER", sender)
        Hardcore:Debug("Sending out reply:" .. comm_msg)
    end)

end


-- SurveyReceiveResponse( args )
--
-- Receives a survey response, and if sent by a guild member, stores the response
-- Called from Hardcore.lua

function SurveyReceiveResponse(data, sender)

    -- Foolproofing
    if Hardcore_Settings.surveys == nil then
        Hardcore:Debug( "Received a survey response, but you have not sent one out" )
        return
    end

    -- Check if you are the GM
    if guild_master == "" then
        guild_master = SurveyDetermineGuildMaster()
    end
    if SurveyGetLongName() ~= guild_master then
        Hardcore:Debug( "Received a survey response, but you are not the GM; " .. guild_master .. " is, and you are " .. SurveyGetLongName())
        return
    end

    -- Unpack the request
    local id, hctag, value = string.split(COMM_FIELD_DELIM, data)

	-- Handle malformed requests
	if id == nil or hctag == nil or value == nil then
        Hardcore:Debug("Received a malformed survey response from " .. sender )
		return
	end
    local survey_id = tonumber( id )
    if (survey_id <= 0) or (survey_id > #Hardcore_Settings.surveys) or (Hardcore_Settings.surveys[ survey_id ] == nil) then
        Hardcore:Debug( "Received a survey response for an unknown survey ID: " .. survey_id )
        return
    end

    -- Make sure this one didn't already pass the deadline (would need one reply out of time to have this flag, or flag could be set manually)
    if Hardcore_Settings.surveys[ survey_id ].closed ~= nil and Hardcore_Settings.surveys[ survey_id ].closed == true then
        Hardcore:Debug( "Received a survey response from " .. sender .. " for a closed survey ID: " .. survey_id )
        return
    end
    if Hardcore_Settings.surveys[ survey_id ].end_time < GetServerTime() then
        Hardcore:Debug( "Received a survey response from " .. sender .. " for a timed-out survey ID: " .. survey_id )
        Hardcore_Settings.surveys[ survey_id ].closed = true
        return
    end

    -- Store it
    if Hardcore_Settings.surveys[ survey_id ].replies ~= nil then
        local RESPONSE = {}
        RESPONSE.sender = sender
        RESPONSE.tag = hctag
        RESPONSE.value = value
        table.insert( Hardcore_Settings.surveys[ survey_id ].replies, RESPONSE )
        Hardcore:Print( "Stored survey response from " .. sender .. ", value = " .. value )
    end

end


-- SurveyHandleCommand( args )
--
-- Called by /hc Survey command, to initiate a survey

function SurveyHandleCommand( args )

	local usage = "Usage: /hc Survey <number> <var>\nwhere <number> = max reply time, and <var> is a HC variable"
	local max_wait = nil
	local var = nil

    -- Check if you are the GM
    if guild_master == "" then
        guild_master = SurveyDetermineGuildMaster()
    end
    if SurveyGetLongName() ~= guild_master then
        Hardcore:Print( "You are not the GM; " .. guild_master .. " is, and you are " .. SurveyGetLongName() )
        return
    end

	-- Check and retrieve number and variable
	for substring in args:gmatch("%S+") do
		if max_wait == nil then
			max_wait = substring
		elseif var == nil then
			var = substring
		end
	end
    if max_wait == "reset" then
		Hardcore:Print("All survey data reset from settings file")
        Hardcore_Settings.surveys = nil
        return
    end

	if max_wait == nil or tonumber( max_wait ) == nil then
		Hardcore:Print("Wrong syntax: Missing or ill-formed <number> argument")
		Hardcore:Print(usage)
		return
	end
	if var == nil then
		Hardcore:Print("Wrong syntax: Missing <var> argument")
		Hardcore:Print(usage)
		return
	end

    -- Make sure that the max_wait time isn't too low (would spam the GM)
    local _, num_online = GetNumGuildMembers()
    if tonumber(max_wait) < num_online then
        max_wait = num_online
        Hardcore:Print( "Adjusted the maximum wait time for your survey to " .. max_wait )
    end

    -- Initialise the place to receive survey requests
    if Hardcore_Settings ~= nil and Hardcore_Settings.surveys == nil then
        Hardcore_Settings.surveys = {}
    end

    -- Create a new survey
    local SURVEY = {}
    SURVEY.created_date = date("%m/%d/%y %H:%M:%S")
    SURVEY.end_time = GetServerTime() + max_wait + 10
    SURVEY.closed = false
    SURVEY.created_by = guild_master
    SURVEY.replies = {}
    SURVEY.id = #Hardcore_Settings.surveys + 1
    SURVEY.request = SURVEY.id .. COMM_FIELD_DELIM .. max_wait .. COMM_FIELD_DELIM .. var
    table.insert( Hardcore_Settings.surveys, SURVEY )

    -- Compile the request and send it
    local comm_msg = SURVEY_REQ_CMD .. COMM_COMMAND_DELIM .. SURVEY.request
    CTL:SendAddonMessage("NORMAL", COMM_NAME, comm_msg, "GUILD")
    Hardcore:Print( "Sent out survey command: " .. SURVEY_REQ_CMD .. "$" .. SURVEY.id .. "/" .. max_wait .. "/" .. var )

end


-- SurveyInitiate()
--
-- Function to set up the survey subsystem
-- Called from Hardcore.lua as follows:
--		SurveyInitiate(COMM_NAME, COMM_COMMANDS[15], COMM_COMMAND_DELIM, COMM_FIELD_DELIM )

function SurveyInitiate(comm_name, req_cmd, ack_cmd, cmd_delim, field_delim)

    -- Copy over Hardcore.lua locals needed for communication
	COMM_NAME = comm_name
	SURVEY_REQ_CMD = req_cmd
	SURVEY_ACK_CMD = ack_cmd
	COMM_COMMAND_DELIM = cmd_delim
	COMM_FIELD_DELIM = field_delim

end

