import asyncio

from gi.repository import Gdk
from ignis import utils, widgets
from ignis.window_manager import WindowManager

wm = WindowManager.get_default()


def exec_async(cmd: str):
    asyncio.create_task(utils.exec_sh_async(cmd))


class ConfirmDialog(widgets.Window):
    def __init__(self, title: str, message: str, on_confirm=None, on_cancel=None):
        self.on_confirm_callback = on_confirm
        self.on_cancel_callback = on_cancel

        title_label = widgets.Label(
            label=title,
            css_classes=["confirm-dialog-title"],
        )

        message_label = widgets.Label(
            label=message,
            css_classes=["confirm-dialog-message"],
        )

        cancel_btn = widgets.Button(
            label="Cancel",
            css_classes=["confirm-dialog-btn", "confirm-dialog-cancel"],
            on_click=lambda x: self._cancel(),
            can_focus=True,
        )

        confirm_btn = widgets.Button(
            label="Confirm",
            css_classes=["confirm-dialog-btn", "confirm-dialog-confirm"],
            on_click=lambda x: self._confirm(),
            can_focus=True,
        )

        buttons_box = widgets.Box(
            spacing=12,
            halign="center",
            child=[cancel_btn, confirm_btn],
        )

        content_box = widgets.Box(
            vertical=True,
            spacing=24,
            css_classes=["confirm-dialog-content"],
            child=[
                title_label,
                message_label,
                buttons_box,
            ],
        )

        centered = widgets.Box(
            valign="center",
            halign="center",
            child=[content_box],
        )

        background_btn = widgets.Button(
            vexpand=True,
            hexpand=True,
            can_focus=False,
            css_classes=["confirm-dialog-background"],
            on_click=lambda x: self._cancel(),
        )

        root = widgets.Overlay(
            child=background_btn,
            overlays=[centered],
        )

        super().__init__(
            visible=True,
            anchor=["top", "bottom", "left", "right"],
            namespace="ignis_CONFIRM_DIALOG",
            exclusivity="ignore",
            layer="overlay",
            popup=True,
            css_classes=["confirm-dialog-window"],
            child=root,
            kb_mode="exclusive",
        )

        self._setup_keyboard_controller()

        confirm_btn.grab_focus()

    def _setup_keyboard_controller(self):
        from gi.repository import Gtk

        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self._on_key_pressed)
        self.add_controller(key_controller)

    def _on_key_pressed(self, controller, keyval, keycode, state):
        keyname = Gdk.keyval_name(keyval)

        if keyname == "Escape":
            self._cancel()
            return True
        elif keyname in ["Return", "KP_Enter"]:
            self._confirm()
            return True
        elif keyname.lower() == "y":
            self._confirm()
            return True
        elif keyname.lower() == "n":
            self._cancel()
            return True

        return False

    def _confirm(self):
        if self.on_confirm_callback:
            self.on_confirm_callback()
        self.close()

    def _cancel(self):
        if self.on_cancel_callback:
            self.on_cancel_callback()
        self.close()


def confirm_dialog(title: str, message: str, on_confirm=None, on_cancel=None):
    return ConfirmDialog(title, message, on_confirm, on_cancel)


class PowerOverlay(widgets.Window):
    def __init__(self):
        lock_btn = widgets.Button(
            css_classes=["power-overlay-btn"],
            on_click=lambda *_: self._lock(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[
                    widgets.Icon(
                        image="system-lock-screen-symbolic",
                        pixel_size=48,
                    ),
                    widgets.Label(
                        label="[L]ock",
                        css_classes=["power-overlay-label"],
                    ),
                ],
            ),
        )

        logout_btn = widgets.Button(
            css_classes=["power-overlay-btn"],
            on_click=lambda x: self._logout(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[
                    widgets.Icon(
                        image="system-log-out-symbolic",
                        pixel_size=48,
                    ),
                    widgets.Label(
                        label="[E]xit",
                        css_classes=["power-overlay-label"],
                    ),
                ],
            ),
        )

        suspend_btn = widgets.Button(
            css_classes=["power-overlay-btn"],
            on_click=lambda x: self._suspend(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[
                    widgets.Icon(
                        image="media-playback-pause-symbolic",
                        pixel_size=48,
                    ),
                    widgets.Label(
                        label="z[Z]zz",
                        css_classes=["power-overlay-label"],
                    ),
                ],
            ),
        )

        reboot_btn = widgets.Button(
            css_classes=["power-overlay-btn", "power-overlay-btn-danger"],
            on_click=lambda x: self._reboot(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[
                    widgets.Icon(
                        image="system-reboot-symbolic",
                        css_classes=["power-warning-icon"],
                        pixel_size=48,
                    ),
                    widgets.Label(
                        label="[R]eboot",
                        css_classes=["power-overlay-label"],
                    ),
                ],
            ),
        )

        shutdown_btn = widgets.Button(
            css_classes=["power-overlay-btn", "power-overlay-btn-danger"],
            on_click=lambda x: self._shutdown(),
            can_focus=True,
            child=widgets.Box(
                vertical=True,
                spacing=8,
                child=[
                    widgets.Icon(
                        image="system-shutdown-symbolic",
                        css_classes=["power-warning-icon"],
                        pixel_size=48,
                    ),
                    widgets.Label(
                        label="[S]hutdown",
                        css_classes=["power-overlay-label"],
                    ),
                ],
            ),
        )

        buttons_container = widgets.Box(
            vertical=True,
            valign="center",
            halign="center",
            css_classes=["power-overlay"],
            child=[
                widgets.Box(
                    spacing=24,
                    halign="center",
                    css_classes=["power-overlay-buttons"],
                    child=[
                        lock_btn,
                        logout_btn,
                        suspend_btn,
                        reboot_btn,
                        shutdown_btn,
                    ],
                )
            ],
        )

        overlay_btn = widgets.Button(
            vexpand=True,
            hexpand=True,
            can_focus=False,
            css_classes=["power-overlay-background"],
            on_click=lambda x: self.toggle(),
        )

        root_overlay = widgets.Overlay(
            child=overlay_btn,
            overlays=[buttons_container],
        )

        super().__init__(
            visible=False,
            anchor=["top", "bottom", "left", "right"],
            namespace="ignis_POWER_OVERLAY",
            exclusivity="ignore",
            layer="overlay",
            popup=True,
            css_classes=["power-overlay-window"],
            child=root_overlay,
            kb_mode="exclusive",
        )

        self._setup_keyboard_controller()

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

        elif keyname.lower() == "l":
            self._lock()
            return True

        elif keyname.lower() == "e":
            self._logout()
            return True

        elif keyname.lower() == "z":
            self._suspend()
            return True

        elif keyname.lower() == "r":
            self._reboot()
            return True

        elif keyname.lower() == "s":
            self._shutdown()
            return True

        return False

    def toggle(self):
        self.visible = not self.visible

    def _lock(self):
        exec_async("hyprlock")
        self.toggle()

    def _logout(self):
        self.toggle()
        confirm_dialog(
            "Logout",
            "Are you sure you want to log out?",
            on_confirm=lambda: exec_async("loginctl terminate-user $USER"),
        )

    def _suspend(self):
        exec_async("systemctl suspend")
        self.toggle()

    def _reboot(self):
        self.toggle()
        confirm_dialog(
            "Reboot System",
            "Are you sure you want to reboot?",
            on_confirm=lambda: exec_async("systemctl reboot"),
        )

    def _shutdown(self):
        self.toggle()
        confirm_dialog(
            "Power Off",
            "Are you sure you want to shut down?",
            on_confirm=lambda: exec_async("systemctl poweroff"),
        )
