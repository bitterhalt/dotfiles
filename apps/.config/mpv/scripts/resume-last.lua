-- Opens the last played file when mpv starts empty AND --script-opts-append=resume=yes is given.
-- The file opens paused.
if mp.get_opt("resume") ~= "yes" then
	return
end

local done = false

mp.observe_property("idle-active", "bool", function(_, idle)
	if done or not idle then
		return
	end
	mp.add_timeout(0.5, function()
		if done then
			return
		end
		done = true
		if mp.get_property_bool("idle-active") then
			-- pause once the file has loaded (after the saved position is restored)
			local function pause_on_load()
				mp.unregister_event(pause_on_load)
				mp.set_property_bool("pause", true)
			end
			mp.register_event("file-loaded", pause_on_load)
			mp.commandv("script-binding", "memo/memo-last")
		end
	end)
end)
