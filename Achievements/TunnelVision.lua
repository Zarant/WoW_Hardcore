local _G = _G
local tunnel_vision_achievement = CreateFrame("Frame")
_G.achievements.TunnelVision = tunnel_vision_achievement

-- General info
tunnel_vision_achievement.name = "TunnelVision"
tunnel_vision_achievement.title = "Tunnel Vision"
tunnel_vision_achievement.class = "All"
tunnel_vision_achievement.pts = 20
tunnel_vision_achievement.icon_path = "Interface\\Addons\\Hardcore\\Media\\icon_tunnel_vision.blp"
tunnel_vision_achievement.description =
	"Complete the Hardcore challenge entirely in first person view. Upon logging in, zoom your camera into first person and never zoom out again."

-- Registers
function tunnel_vision_achievement:Register(fail_function_executor)
	tunnel_vision_achievement.timer_handle = C_Timer.NewTicker(1.0, function()
		CameraZoomIn(50)
	end)
	tunnel_vision_achievement.fail_function_executor = fail_function_executor
end

function tunnel_vision_achievement:Unregister()
	tunnel_vision_achievement.timer_handle:Cancel()
end

-- Register Definitions
tunnel_vision_achievement:SetScript("OnEvent", function(self, event, ...)
	local arg = { ... }
end)
