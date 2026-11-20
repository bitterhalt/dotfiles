function shellescape(path)
	return "'" .. path:gsub("'", "'\\''") .. "'"
end

require("functions")
require("gallery")
require("viewer")
require("settings")
