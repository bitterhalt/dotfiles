setbg = require("functions/setbg")

function shellescape(path)
	return "'" .. path:gsub("'", "'\\''") .. "'"
end
