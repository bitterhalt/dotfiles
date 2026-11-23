function shellescape(path)
	return "'" .. path:gsub("'", "'\\''") .. "'"
end

require("functions")
require("gallery")
require("viewer")
require("settings")

-- Startup hint: show the F1 tip for 5 seconds (the status timer is armed when
-- the message is set, so restoring the normal timeout afterwards is safe).
swayimg.on_initialized(function()
	local timeout = swayimg.text.status_timeout
	swayimg.text.status_timeout = 5
	swayimg.text.status = "F1: key tips"
	swayimg.text.status_timeout = timeout
end)
