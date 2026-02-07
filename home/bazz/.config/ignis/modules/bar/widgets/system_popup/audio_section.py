from ignis import widgets
from ignis.services.audio import AudioService
from modules.utils.signal_manager import SignalManager

audio = AudioService.get_default()


class AudioDeviceItem(widgets.Button):
    def __init__(self, stream, device_type: str):
        super().__init__(
            css_classes=["audio-device-item", "unset"],
            on_click=lambda *_: setattr(audio, device_type, stream),
            child=widgets.Box(
                spacing=4,
                child=[
                    widgets.Label(
                        label=stream.description,
                        ellipsize="end",
                        max_width_chars=30,
                        halign="start",
                    ),
                    widgets.Icon(
                        image="object-select-symbolic",
                        halign="end",
                        pixel_size=16,
                        visible=stream.bind("is_default"),
                        hexpand=True,
                    ),
                ],
            ),
        )


class AudioSection(widgets.Box):
    def __init__(self, stream, device_type: str):
        super().__init__(vertical=True, spacing=10)

        self.stream = stream
        self.device_type = device_type
        self._signals = SignalManager()

        mute_icon = widgets.Icon(
            image=stream.bind(
                "is_muted",
                lambda m: (
                    (
                        "microphone-sensitivity-muted-symbolic"
                        if device_type == "microphone"
                        else "audio-volume-muted-symbolic"
                    )
                    if m
                    else self._volume_icon(stream.volume)
                ),
            ),
            pixel_size=22,
        )

        mute_btn = widgets.Button(
            css_classes=["pill-audio-mute-btn", "unset"],
            child=mute_icon,
            on_click=lambda *_: setattr(stream, "is_muted", not stream.is_muted),
        )

        slider = widgets.Scale(
            min=0,
            max=100,
            value=stream.bind("volume", lambda v: int(v or 0)),
            on_change=lambda w: setattr(stream, "volume", w.value),
            sensitive=stream.bind("is_muted", lambda m: not m),
            can_focus=False,
            hexpand=True,
            css_classes=["pill-audio-scale"],
        )

        self._signals.connect(stream, "notify::volume", lambda *_: self._update_icon(mute_icon))

        self._arrow = widgets.Arrow(
            pixel_size=16,
            rotated=False,
            css_classes=["pill-audio-arrow"],
        )

        arrow_btn = widgets.Button(
            css_classes=["pill-audio-expand-btn", "unset"],
            child=self._arrow,
            on_click=lambda *_: self._toggle_list(),
        )

        row = widgets.Box(
            child=[mute_btn, slider, arrow_btn],
        )

        self._device_list = widgets.Box(
            vertical=True,
            spacing=8,
            visible=False,
            css_classes=["sys-audio-details"],
        )

        self.child = [row, self._device_list]
        self._populate_devices()
        self._signals.connect(audio, f"{device_type}-added", lambda *_: self._populate_devices())
        self._signals.connect(audio, f"notify::{device_type}", lambda *_: self._populate_devices())
        self.connect("destroy", lambda *_: self._signals.disconnect_all())

    def _volume_icon(self, vol: int):
        if self.device_type == "microphone":
            return "microphone-sensitivity-high-symbolic"

        if vol <= 25:
            return "audio-volume-low-symbolic"
        elif vol <= 75:
            return "audio-volume-medium-symbolic"
        else:
            return "audio-volume-high-symbolic"

    def _update_icon(self, icon_widget):
        if self.stream.is_muted:
            icon_widget.image = (
                "microphone-sensitivity-muted-symbolic"
                if self.device_type == "microphone"
                else "audio-volume-muted-symbolic"
            )
        else:
            icon_widget.image = self._volume_icon(self.stream.volume)

    def _toggle_list(self):
        new_state = not self._device_list.visible
        self._arrow.rotated = new_state
        self._device_list.visible = new_state

    def _populate_devices(self):
        self._device_list.child = []
        streams = getattr(audio, f"{self.device_type}s", [])
        current = getattr(audio, self.device_type)
        streams = sorted(streams, key=lambda s: (0 if s == current else 1, s.description.lower()))

        for s in streams:
            item = AudioDeviceItem(s, self.device_type)
            self._device_list.append(item)
