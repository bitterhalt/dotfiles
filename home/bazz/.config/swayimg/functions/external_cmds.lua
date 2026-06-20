local function register_external_cmds(mode)
	mode.on_key("b", function()
		local image = mode.get_image()
		if not image then
			return
		end
		local ret = os.execute("setbg -w " .. image.path .. " & disown")
	end)

	mode.on_key("p", function()
		local image = mode.get_image()
		if not image then
			return
		end
		local ret = os.execute("setbg -p " .. image.path .. " & disown")
	end)

	mode.on_key("Shift+p", function()
		local image = mode.get_image()
		if not image then
			return
		end
		local ret = os.execute("setbg -pf " .. image.path .. " & disown")
	end)

	mode.on_key("e", function()
		local image = mode.get_image()
		if not image then
			return
		end
		os.execute("gimp " .. image.path .. " & disown")
	end)

	mode.on_key("y", function()
		local image = mode.get_image()
		if not image then
			return
		end
		os.execute("wl-copy -t image/png <" .. image.path)
		swayimg.text.set_status("Copied to clipboard: " .. image.path)
	end)
end

return register_external_cmds
