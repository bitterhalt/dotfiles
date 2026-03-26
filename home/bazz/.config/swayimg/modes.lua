--------------------------------------------------------------------------------
-- Gallery mode
--------------------------------------------------------------------------------
swayimg.gallery.set_thumb_size(180)
swayimg.gallery.set_padding_size(10)
swayimg.gallery.set_border_size(2)
swayimg.gallery.set_border_color(0xffA02F6F)
swayimg.gallery.set_selected_color(0xff403E3C)
swayimg.gallery.set_unselected_color(0xff1C1B1A)
swayimg.gallery.set_window_color(0xAA100F10)
swayimg.gallery.limit_cache(100)
swayimg.gallery.enable_preload(false)
swayimg.gallery.enable_pstore(true)

swayimg.gallery.set_text("topright", { "{list.index} of {list.total}" })
swayimg.gallery.set_text("bottomright", { "{name}" })
swayimg.gallery.set_text("topleft", {})
swayimg.gallery.set_text("bottomleft", {})

--------------------------------------------------------------------------------
-- Viewer mode
--------------------------------------------------------------------------------
swayimg.viewer.set_default_scale("optimal")
swayimg.viewer.set_default_position("center")
swayimg.viewer.set_window_background(0xAA100F10)
swayimg.viewer.set_image_chessboard(20, 0xff333333, 0xff4c4c4c)
swayimg.viewer.enable_centering(true)
swayimg.viewer.enable_loop(true)
swayimg.viewer.limit_preload(1)

swayimg.viewer.set_text("topleft", {
	"File: {name}",
	"Format: {format}",
	"File size: {sizehr}",
	"Size: {frame.width}x{frame.height}",
	"EXIF date: {meta.Exif.Photo.DateTimeOriginal}",
	"EXIF camera: {meta.Exif.Image.Model}",
})
swayimg.viewer.set_text("topright", {
	"Image: {list.index} of {list.total}",
	"Frame: {frame.index} of {frame.total}",
	"Scale: {scale}",
})
swayimg.viewer.set_text("bottomleft", {})
swayimg.viewer.set_text("bottomright", {})

--------------------------------------------------------------------------------
-- Slideshow mode
--------------------------------------------------------------------------------
swayimg.slideshow.set_timeout(3)
swayimg.slideshow.set_default_scale("fit")
swayimg.slideshow.set_window_background("auto")

swayimg.slideshow.set_text("bottomright", { "{path}", "{status}" })
swayimg.slideshow.set_text("topleft", {})
swayimg.slideshow.set_text("topright", {})
swayimg.slideshow.set_text("bottomleft", {})
