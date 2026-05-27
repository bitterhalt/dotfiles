local shellescape = require("functions/shellescape")

local function register_external_cmds(mode)
	mode.on_key("b", function()
		local image = mode.get_image()
		setbg(image.path)
	end)
	mode.on_key("e", function()
		local image = mode.get_image()
		os.execute("gimp " .. shellescape(image.path) .. " & disown")
	end)
	mode.on_key("y", function()
		local image = mode.get_image()
		os.execute("wl-copy -t image/png <" .. shellescape(image.path))
		swayimg.text.set_status("Copied to clipboard: " .. image.path)
	end)
end

return register_external_cmds
