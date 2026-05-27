--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.set_default_position("center")
swayimg.viewer.enable_centering(true)
swayimg.viewer.enable_loop(true)
swayimg.viewer.limit_preload(1)

swayimg.viewer.set_text("topleft", {
	"File: {name}",
	"Format: {format}",
	"File size: {sizehr}",
	"Size: {frame.width}x{frame.height}",
	"{meta.Exif.Photo.DateTimeOriginal}",
	"{meta.Exif.Image.Model}",
})
swayimg.viewer.set_text("topright", {
	"Image: {list.index} of {list.total}",
	"Frame: {frame.index} of {frame.total}",
	"Scale: {scale}",
})
swayimg.viewer.set_text("bottomleft", {})
swayimg.viewer.set_text("bottomright", {})

swayimg.on_window_resize(function()
	if swayimg.get_mode() == "viewer" then
		swayimg.viewer.set_fix_scale("optimal")
	end
end)
