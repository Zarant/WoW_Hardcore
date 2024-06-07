-- ReloadReminder.lua
-- Reload reminder for the WOW Hardcore addon
-- Written by Frank de Jong

----- LOCAL VARIABLES ----------

local AceGUI = LibStub("AceGUI-3.0")

local rr_last_reload = 0               -- Last time of a reload (basically, last time since ReloadReminderInitiate())
local rr_last_warning = 0              -- Last time of an actually output warning
local rr_last_played_heartbeat = 0     -- Last time of a PLAYED_TIME_MSG in Hardcore.lua
local rr_last_track_heartbeat = 0      -- Last time of a tracked time ticker in Hardcore.lua
local rr_last_dung_heartbeat = 0       -- Last time of a dungeon ticker in Hardcore.lua
local rr_frame
local rr_num_times_closed = 0

-- These variables correspond to the HC options
local rr_show_warning = true
local rr_set_interval = 0               -- 0 indicates automatic

-- Definitions
local RR_TIME_STEP = 1                  -- How often our timer is called
local RR_WARN_SUPPRESS = 300            -- How long to wait before another warning is output, to prevent spamming the user
local RR_LOST_VS_AUTO_INTERVAL = {
    { 3600, 3600 },         -- With less than 1 hour of lost time, warn every hour
    { 7200, 2700 },         -- With 1-2 hours of lost time, warn every 45m
    {10800, 1800 },         -- With 2-3 hours of lost time, warn every 30m
    {   -1,  900 }          -- All other cases: warn every 15m
}

-- debug values
if false then
    RR_WARN_SUPPRESS = 5
    RR_LOST_VS_AUTO_INTERVAL = {
        { 3600, 30 },
        { 7200, 20 },
        {10800, 10 },
        {   -1,  5 }
    }
end

----- LOCAL FUNCTIONS ----------

-- ReloadReminderGetInterval()
--
-- Returns the option-set interval or an automatically determined value from RR_LOST_VS_AUTO_INTERVAL if option-set is 0

local function ReloadReminderGetInterval( rr_lost_time )

    -- If set to automatic, we calculate a value
    if rr_set_interval <= 0 then
        for _, v in ipairs( RR_LOST_VS_AUTO_INTERVAL ) do
            if v[1] == -1 then
                return v[2]             -- Last value in the array, always return this
            end
            if rr_lost_time <= v[1] then
                return v[2]
            end
        end
    end

    -- If set to some specific value, that's what we do
    return rr_set_interval

end

local function ReloadReminderSavePosition()

    local _hc_settings = _G["Hardcore_Settings"]
    if _hc_settings == nil or rr_frame == nil then
        return
    end

    -- Create the settings if it doesn't exist already
	if _hc_settings['reload_reminder_pos'] == nil then
	  _hc_settings['reload_reminder_pos'] = {}
	end

	local point, _, _, x, y = rr_frame:GetPoint()

	_hc_settings['reload_reminder_pos']['x'] = x
	_hc_settings['reload_reminder_pos']['y'] = y
    _hc_settings['reload_reminder_pos']['ref'] = point

end

local function ReloadReminderRestorePosition()

    -- Fool proofing
    if rr_frame == nil then
        return
    end

    -- Set previous window position
    local _hc_settings = _G["Hardcore_Settings"]
    rr_frame:ClearAllPoints()
    if _hc_settings["reload_reminder_pos"]
        and _hc_settings["reload_reminder_pos"]["x"]
        and _hc_settings["reload_reminder_pos"]["y"]
        and _hc_settings["reload_reminder_pos"]['ref'] then
        rr_frame:SetPoint(_hc_settings["reload_reminder_pos"]['ref'], _hc_settings["reload_reminder_pos"]['x'], _hc_settings["reload_reminder_pos"]['y'])
    else
        rr_frame:SetPoint("CENTER", 0, 0)
    end

end


local function ReloadReminderDoReload()

    ReloadReminderSavePosition()
    Hardcore:Print("Attempting reload")
    ReloadUI()
    Hardcore:Print("Reload failed")

end


local function ReloadReminderCleanup(widget)

    -- Store the postion where the window is at
    ReloadReminderSavePosition()

    AceGUI:Release(widget)
    rr_frame = nil
    rr_last_warning = GetServerTime()           -- Suppress warnings for maximum time from now

    -- Tell the user that he can disable the reloader if he closes three times without reloading
    rr_num_times_closed = rr_num_times_closed + 1
    if rr_num_times_closed == 3 then
        Hardcore:Print("You can customize and disable the reload reminder in the Hardcore options.")
        Hardcore:Print("Using the reload reminder will mitigate data loss in case of DCs and crashes.")
    end


end

local function ReloadReminderCreateWindow()

    -- Create the window if it isn't simply hidden
    if rr_frame == nil then
        rr_frame = AceGUI:Create("Frame")
        rr_frame:SetTitle("Reload Reminder")
        rr_frame:SetStatusText("Reload when safe!")
        rr_frame:SetCallback("OnClose", function(widget) ReloadReminderCleanup(widget) end )
        rr_frame:SetLayout("Flow")
        rr_frame:SetWidth(300)
        rr_frame:SetHeight(125)

        ReloadReminderRestorePosition()

        local button = AceGUI:Create("Button")
        button:SetText("Reload now")
        button:SetWidth(250)
        button:SetCallback("OnClick", function() ReloadReminderDoReload() end)
        rr_frame:AddChild(button)
    end

    rr_frame:Show()

end

local function ReloadReminderGetIntervalString( interval )

    local time_str = ""
    local num_hours = 0
    local num_mins = 0

    if interval >= 3600 then
        num_hours = math.floor( interval / 3600 )
        time_str = time_str .. num_hours .. " Hr"
        if num_hours > 1 then
            time_str = time_str .. "s"
        end
        interval = interval - (num_hours * 3600)
    end
    if interval >= 60 then
        num_mins = math.floor( interval / 60 )
        if num_hours > 0 then
            time_str = time_str .. " "
        end
        time_str = time_str .. num_mins .. " Min"
        if num_mins > 1 then
            time_str = time_str .. "s"
        end
        interval = interval - (num_mins * 60)
    end
    if interval > 0 then
        if num_hours > 0 or num_mins > 0 then
            time_str = time_str .. " "
        end
        time_str = time_str .. interval .. " Sec"
        if interval > 1 then
            time_str = time_str .. "s"
        end
    end
    return time_str

end


----- GLOBAL FUNCTIONS ----------


-- ReloadReminderPlayedTimeUpdate()
-- ReloadReminderTrackedTimeUpdate()
-- ReloadReminderDungeonTrackerUpdate()
--
-- Watchdog functions that track if the three vital tickers for tracked, played and dungeon tracking
-- are still operational

function ReloadReminderPlayedTimeUpdate()
    rr_last_played_heartbeat = GetServerTime()
end

function ReloadReminderTrackedTimeUpdate()
    rr_last_track_heartbeat = GetServerTime()
end

function ReloadReminderDungeonTrackerUpdate()
    rr_last_dung_heartbeat = GetServerTime()
end


-- ReloadReminderCheck()
--
-- Timer function that gets called every second to check the conditions for
-- advising a reload are met and putting out the advice

function ReloadReminderCheck()

    local rr_warn_interval = 0              -- Automatic or option-set time between a reload and a warning

    if rr_show_warning == false then
        return
    end

    -- Check if in combat, suppress the warning if so
    if InCombatLockdown() == true then
        return
    end

    -- Do some fool proofing now so we don't have to keep doing that later
    if _G.Hardcore_Character == nil or _G.Hardcore_Character.time_played == nil or _G.Hardcore_Character.time_tracked == nil then
        return
    end

    -- Find out current time, so we can compare against the stored times
    local now = GetServerTime()

    -- Don't warn more often than once per minute
    if now - rr_last_warning < RR_WARN_SUPPRESS then
        return
    end

    -- Check if any of the tickers are falling behind; if so, warn immediately
    if (now - rr_last_played_heartbeat > 180) or
       (now - rr_last_track_heartbeat > 180) or
       (now - rr_last_dung_heartbeat > 180) then
        Hardcore:Print( "Detected a missing heartbeat -- a /reload is advised!")
        rr_last_warning = now
        ReloadReminderCreateWindow()
        return
    end

    -- Determine what is a good time to advise a reload;
    -- First determine how much tracked time was lost already
    local rr_lost_time = _G.Hardcore_Character.time_played - _G.Hardcore_Character.time_tracked
    if rr_lost_time < 0 then
        rr_lost_time = 0
    end

    -- Now derive a good warning interval; 
    rr_warn_interval = ReloadReminderGetInterval(rr_lost_time)

    -- Now see if the interval has passed already
    if now - rr_last_reload > rr_warn_interval then
        -- Okay, let's output the warning
        Hardcore:Print( "Time for a /reload, interval = " .. ReloadReminderGetIntervalString( rr_warn_interval) )
        rr_last_warning = now
        ReloadReminderCreateWindow()
    end

end

-- ReloadReminderEnableWarning( should_show )
-- ReloadReminderSetInterval( interval )
--
-- Functions called to enable or disable the reload warning and set the interval

function ReloadReminderEnableWarning( should_show )
    rr_show_warning = should_show
    Hardcore:Debug( "Reload reminder warning show is now " .. (rr_show_warning and 'true' or 'false') )
end

function ReloadReminderSetInterval( interval )
    rr_set_interval = interval * 60
    Hardcore:Debug( "Reload reminder warning interval is now " .. rr_set_interval .. " seconds")
end


-- ReloadReminderInitiate()
--
-- Function to set up the reload reminder subsystem
-- Called from Hardcore.lua as follows:

function ReloadReminderInitiate()

    -- Initiate our local variables
    local now = GetServerTime()
    rr_last_reload = now
    rr_last_warning = now

    -- Copy over the global setting, or initialise them if they are not set
    if _G.Hardcore_Settings ~= nil then
        if _G.Hardcore_Settings.reload_reminder_show == nil then
            _G.Hardcore_Settings.reload_reminder_show = true
        end
        if _G.Hardcore_Settings.reload_reminder_interval == nil then
            _G.Hardcore_Settings.reload_reminder_interval = 0
        end
        ReloadReminderEnableWarning( _G.Hardcore_Settings.reload_reminder_show )
        ReloadReminderSetInterval( _G.Hardcore_Settings.reload_reminder_interval )
    end

    -- Start our timer
	C_Timer.NewTicker(RR_TIME_STEP, function()
		ReloadReminderCheck()
	end)

end

