--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.set_default_scale("optimal")
swayimg.viewer.set_default_position("center")
swayimg.viewer.set_window_background(0xff100F0F)
swayimg.viewer.set_image_chessboard(20, 0xff333333, 0xff4c4c4c)
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
