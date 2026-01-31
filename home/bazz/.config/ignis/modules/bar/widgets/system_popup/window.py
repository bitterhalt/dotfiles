import asyncio
from ignis import utils, widgets
from ignis.services.audio import AudioService
from ignis.window_manager import WindowManager
from settings import config
from .audio_section import AudioSection
from .network_section import NetworkSection
from .system_info_section import SystemInfoWidget

wm = WindowManager.get_default()
audio = AudioService.get_default()


def exec_async(cmd: str):
    asyncio.create_task(utils.exec_sh_async(cmd))


class SystemPopup(widgets.RevealerWindow):
    def __init__(self):
        record_btn = widgets.Button(
            css_classes=["sys-top-btn", "unset"],
            on_click=lambda x: (
                wm.open_window("ignis_RECORDING_OVERLAY"),
                self.set_visible(False),
            ),
            child=widgets.Icon(image="camera-photo-symbolic", pixel_size=22),
        )

        lock_btn = widgets.Button(
            css_classes=["sys-top-btn", "unset"],
            on_click=lambda x: (exec_async("hyprlock"), self.set_visible(False)),
            child=widgets.Icon(image="system-lock-screen-symbolic", pixel_size=22),
        )

        power_btn = widgets.Button(
            css_classes=["sys-top-btn", "unset"],
            on_click=lambda x: (
                wm.open_window("ignis_POWER_OVERLAY"),
                self.set_visible(False),
            ),
            child=widgets.Icon(image="system-shutdown-symbolic", pixel_size=22),
        )

        top_row = widgets.Box(
            spacing=8,
            css_classes=["sys-top-row"],
            hexpand=True,
            child=[
                widgets.Box(
                    spacing=8,
                    child=[record_btn],
                ),
                widgets.Box(
                    spacing=8,
                    hexpand=True,
                    halign="end",
                    child=[lock_btn, power_btn],
                ),
            ],
        )

        speaker = AudioSection(stream=audio.speaker, device_type="speaker")
        mic = AudioSection(stream=audio.microphone, device_type="microphone")

        self._audio_sections = [speaker, mic]

        audio_content = widgets.Box(
            vertical=True,
            spacing=10,
            css_classes=["sys-audio-pill"],
            child=[speaker, mic],
        )

        network_section = NetworkSection()
        self._network_section = network_section

        network_content = widgets.Box(
            vertical=True,
            spacing=10,
            css_classes=["sys-network-pill"],
            child=[network_section],
        )

        system_info = SystemInfoWidget()
        self._system_info = system_info

        panel = widgets.Box(
            vertical=True,
            spacing=6,
            css_classes=["system-menu", "unset"],
            child=[
                top_row,
                audio_content,
                network_content,
                system_info,
            ],
        )

        revealer = widgets.Revealer(
            child=panel,
            reveal_child=False,
            transition_type="slide_down",
            transition_duration=config.animations.revealer_duration,
        )

        overlay_btn = widgets.Button(
            vexpand=True,
            hexpand=True,
            can_focus=False,
            css_classes=["system-menu-overlay", "unset"],
            on_click=lambda x: wm.close_window("ignis_SYSTEM_MENU"),
        )

        container = widgets.Box(
            valign="start",
            halign="end",
            css_classes=["system-menu-container"],
            child=[revealer],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            visible=False,
            anchor=["top", "right"],
            namespace="ignis_SYSTEM_MENU",
            layer="top",
            popup=True,
            css_classes=["system-menu-window", "unset"],
            kb_mode="on_demand",
            child=widgets.Box(
                child=[
                    overlay_btn,
                    container,
                ]
            ),
            revealer=revealer,
        )

        self.connect("notify::visible", self._on_visible_change)

    def _reset_expandables(self):
        for section in self._audio_sections:
            if section._device_list.visible:
                section._device_list.visible = False
                section._arrow.rotated = False

        if self._network_section._list_visible:
            self._network_section._list_visible = False
            self._network_section._device_list.visible = False
            self._network_section._arrow.set_css_classes(["expand-arrow"])

        if self._system_info._details_box.visible:
            self._system_info._details_box.visible = False
            self._system_info._arrow.set_css_classes(["expand-arrow"])

    def _on_visible_change(self, *_):
        if not self.visible:
            self._reset_expandables()

    def toggle(self):
        self.visible = not self.visible
