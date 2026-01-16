from ignis import utils, widgets
from ignis.services.audio import AudioService
from settings import config

audio = AudioService.get_default()
TIMEOUT = config.ui.volume_osd_timeout
_osd_window = None


class VolumeOSD(widgets.Window):
    def __init__(self):
        self._timeout = None
        speaker = audio.speaker
        icon = widgets.Icon(
            pixel_size=26,
            image=speaker.bind("icon_name"),
            css_classes=["vol-icon"],
        )

        slider = widgets.Scale(
            min=0,
            max=100,
            value=speaker.bind("volume", lambda v: 0 if speaker.is_muted else int(v or 0)),
            sensitive=False,
            hexpand=True,
            css_classes=["vol-track", "unset"],
        )

        content = widgets.Box(
            css_classes=["vol-container"],
            spacing=12,
            child=[icon, slider],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            layer="overlay",
            anchor=["top"],
            namespace="ignis_VOLUME_OSD",
            visible=False,
            css_classes=["vol-window", "unset"],
            child=content,
        )

        self.connect("notify::visible", self._on_visible_changed)

    def _on_visible_changed(self, *_):
        if self.get_visible():
            if self._timeout:
                self._timeout.cancel()

            self._timeout = utils.Timeout(TIMEOUT, lambda: self.set_visible(False))
        else:
            if self._timeout:
                self._timeout.cancel()
                self._timeout = None

    def show_osd(self):
        self.set_visible(True)


def show_volume_osd():
    global _osd_window
    if _osd_window is None:
        _osd_window = VolumeOSD()
    _osd_window.show_osd()
