local cfg = os.getenv("HOME") .. "/.config/swayimg/"

dofile(cfg .. "settings.lua")
dofile(cfg .. "modes/gallery.lua")
dofile(cfg .. "modes/viewer.lua")
dofile(cfg .. "modes/slideshow.lua")
dofile(cfg .. "binds/viewer.lua")
dofile(cfg .. "binds/gallery.lua")
setbg = dofile(cfg .. "functions/setbg.lua")
