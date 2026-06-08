local function register_external_cmds(mode)
	mode.on_key("b", function()
		local image = mode.get_image()
		local ret = os.execute("setbg -w " .. shellescape(image.path) .. " & disown")
		if ret ~= 0 then
			swayimg.text.set_status("setbg failed for: " .. image.path)
		else
			swayimg.text.set_status("Wallpaper set!")
		end
	end)

	mode.on_key("p", function()
		local image = mode.get_image()
		local ret = os.execute("setbg -p " .. shellescape(image.path) .. " & disown")
		if ret ~= 0 then
			swayimg.text.set_status("setbg failed for: " .. image.path)
		else
			swayimg.text.set_status("Pywal theme generated and Wallpaper set!")
		end
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
