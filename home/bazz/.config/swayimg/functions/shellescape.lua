local function shellescape(path)
	return "'" .. path:gsub("'", "'\\''") .. "'"
end

return shellescape
