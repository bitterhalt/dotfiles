import asyncio
from gi.repository import Gdk
from ignis import utils, widgets
from ignis.services.recorder import RecorderService
from modules.utils.recorder import is_recording
from ignis.window_manager import WindowManager
from settings import config

wm = WindowManager.get_default()
recorder = RecorderService.get_default()


def exec_async(cmd: str):
    asyncio.create_task(utils.exec_sh_async(cmd))


class RecordingOverlay(widgets.Window):
    def __init__(self):
        self._screenshot_icon = widgets.Icon(
            image="camera-photo-symbolic",
            css_classes=["screenshot-icon"],
            pixel_size=48,
        )

        self._screenshot_label = widgets.Label(
            label="[1] Screenshot",
            css_classes=["overlay-label"],
        )

        self._screenshot_btn = widgets.Button(
            css_classes=["overlay-btn"],
            on_click=lambda x: self._take_screenshot(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[self._screenshot_icon, self._screenshot_label],
            ),
        )

        self._screenshot_region_icon = widgets.Icon(
            image="image-crop-symbolic",
            css_classes=["screenshot-region-icon"],
            pixel_size=48,
        )

        self._screenshot_region_label = widgets.Label(
            label="[2] Screenshot Region",
            css_classes=["overlay-label"],
        )

        self._screenshot_region_btn = widgets.Button(
            css_classes=["overlay-btn"],
            on_click=lambda x: self._screenshot_region(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[self._screenshot_region_icon, self._screenshot_region_label],
            ),
        )

        self._record_screen_icon = widgets.Icon(
            image="media-record-symbolic",
            css_classes=["record-icon"],
            pixel_size=48,
        )

        self._record_screen_label = widgets.Label(
            label="[3] Record",
            css_classes=["overlay-label"],
        )

        self._record_screen_btn = widgets.Button(
            css_classes=["overlay-btn"],
            on_click=lambda x: self._record_screen(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[self._record_screen_icon, self._record_screen_label],
            ),
        )

        self._record_region_icon = widgets.Icon(
            image="edit-select-all-symbolic",
            css_classes=["record-region-icon"],
            pixel_size=48,
        )

        self._record_region_label = widgets.Label(
            label="[4] Record Region",
            css_classes=["overlay-label"],
        )

        self._record_region_btn = widgets.Button(
            css_classes=["overlay-btn"],
            on_click=lambda x: self._record_region(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[self._record_region_icon, self._record_region_label],
            ),
        )

        buttons_box = widgets.Box(
            spacing=24,
            halign="center",
            css_classes=["overlay-buttons"],
            child=[
                self._screenshot_btn,
                self._screenshot_region_btn,
                self._record_screen_btn,
                self._record_region_btn,
            ],
        )

        content = widgets.Box(
            vertical=True,
            valign="center",
            halign="center",
            css_classes=["recording-overlay"],
            child=[buttons_box],
        )

        overlay_btn = widgets.Button(
            vexpand=True,
            hexpand=True,
            can_focus=False,
            css_classes=["overlay-background"],
            on_click=lambda x: self.toggle(),
        )

        root_overlay = widgets.Overlay(
            child=overlay_btn,
            overlays=[content],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            visible=False,
            anchor=["top", "bottom", "left", "right"],
            exclusivity="ignore",
            namespace="ignis_RECORDING_OVERLAY",
            layer="overlay",
            popup=True,
            css_classes=["recording-overlay-window"],
            child=root_overlay,
            kb_mode="exclusive",
        )

        recorder.connect("recording_started", lambda x: self._update_recording_state())
        recorder.connect("recording_stopped", lambda x: self._update_recording_state())

        self._setup_keyboard_controller()
        self._update_recording_state()

    def _setup_keyboard_controller(self):
        from gi.repository import Gtk

        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self._on_key_pressed)
        self.add_controller(key_controller)

    def _on_key_pressed(self, controller, keyval, keycode, state):
        keyname = Gdk.keyval_name(keyval)

        if keyname == "Escape":
            self.toggle()
            return True
        elif keyname in ["1", "KP_1"]:
            self._take_screenshot()
            return True
        elif keyname in ["2", "KP_2"]:
            self._screenshot_region()
            return True
        elif keyname in ["3", "KP_3"]:
            self._record_screen()
            return True
        elif keyname in ["4", "KP_4"]:
            self._record_region()
            return True

        return False

    def _update_recording_state(self):
        is_recording = self._is_recording()

        if is_recording:
            self._record_screen_icon.image = "media-playback-stop-symbolic"
            self._record_screen_label.label = "[3] Stop Recording"
            self._record_screen_btn.remove_css_class("overlay-btn")
            self._record_screen_btn.add_css_class("overlay-btn-stop")
        else:
            self._record_screen_icon.image = "media-record-symbolic"
            self._record_screen_label.label = "[3] Record"
            self._record_screen_btn.remove_css_class("overlay-btn-stop")
            self._record_screen_btn.add_css_class("overlay-btn")

    def _is_recording(self):
        return is_recording()

    def toggle(self):
        self.visible = not self.visible

    def _take_screenshot(self):
        exec_async("wl-shot --fullscreen")
        self.toggle()

    def _screenshot_region(self):
        exec_async("wl-shot --region")
        self.toggle()

    def _record_screen(self):
        from ignis.command_manager import CommandManager

        cmd_manager = CommandManager.get_default()

        if self._is_recording():
            cmd_manager.run_command("recorder-stop")
        else:
            cmd_manager.run_command("recorder-record-screen")

        self.toggle()

    def _record_region(self):
        from ignis.command_manager import CommandManager

        cmd_manager = CommandManager.get_default()
        cmd_manager.run_command("recorder-record-region")
        self.toggle()


def toggle_recording_overlay():
    try:
        wm.toggle_window("ignis_RECORDING_OVERLAY")
    except:
        RecordingOverlay()
        wm.toggle_window("ignis_RECORDING_OVERLAY")
