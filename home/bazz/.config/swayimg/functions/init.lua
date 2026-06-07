function shellescape(path)
	return "'" .. path:gsub("'", "'\\''") .. "'"
end
