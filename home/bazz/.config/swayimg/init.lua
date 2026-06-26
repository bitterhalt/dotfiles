function shellescape(path)
	return "'" .. path:gsub("'", "'\\''") .. "'"
end

require("gallery")
require("viewer")
require("settings")
