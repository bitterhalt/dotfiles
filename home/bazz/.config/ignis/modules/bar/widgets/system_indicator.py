from ignis import widgets
from ignis.services.audio import AudioService
from ignis.services.network import NetworkService
from ignis.services.bluetooth import BluetoothService
from ignis.window_manager import WindowManager
from modules.utils.signal_manager import SignalManager

wm = WindowManager.get_default()
audio = AudioService.get_default()
net = NetworkService.get_default()
wifi = net.wifi
ethernet = net.ethernet
vpn = net.vpn
bluetooth = BluetoothService.get_default()


class SystemIndicatorWidget(widgets.Button):
    def __init__(self):
        self._signals = SignalManager()
        self._speaker_icon = widgets.Icon(
            image=self._get_speaker_icon(),
            pixel_size=22,
        )

        self._mic_icon = widgets.Icon(
            image=self._get_mic_icon(),
            pixel_size=22,
            visible=self._get_mic_visible(),
        )

        self._net_icon = widgets.Icon(
            image=self._get_network_icon(),
            pixel_size=22,
        )

        self._bt_icon = widgets.Icon(
            image=self._get_bluetooth_icon(),
            pixel_size=22,
            visible=self._get_bluetooth_visible(),
        )

        inner = widgets.Box(
            css_classes=["system-indicator"],
            spacing=14,
            child=[self._speaker_icon, self._mic_icon, self._net_icon, self._bt_icon],
        )

        super().__init__(
            css_classes=["system-indicator-button", "unset"],
            child=inner,
            on_click=lambda *_: wm.open_window("ignis_SYSTEM_MENU"),
        )

        self._setup_signals()
        self._refresh()
        self.connect("destroy", lambda *_: self._cleanup())

    def _get_speaker_icon(self):
        if audio.speaker.is_muted:
            return "audio-volume-muted-symbolic"
        return audio.speaker.icon_name

    def _get_mic_visible(self):
        return not audio.microphone.is_muted

    def _get_mic_icon(self):
        return (
            "microphone-sensitivity-muted-symbolic"
            if audio.microphone.is_muted
            else "microphone-sensitivity-high-symbolic"
        )

    def _get_network_icon(self):
        if vpn.is_connected:
            return vpn.icon_name
        if ethernet.is_connected:
            return ethernet.icon_name
        if wifi.is_connected:
            return wifi.icon_name
        return "network-offline-symbolic"

    def _get_bluetooth_icon(self):
        return "bluetooth-symbolic"

    def _get_bluetooth_visible(self):
        try:
            if not bluetooth.powered:
                return False
            devices = getattr(bluetooth, "connected_devices", None)
            return bool(devices)
        except Exception:
            return False

    def _setup_signals(self):
        # Audio signals
        self._signals.connect(audio.speaker, "notify::is-muted", self._refresh)
        self._signals.connect(audio.speaker, "notify::volume", self._refresh)
        self._signals.connect(audio.microphone, "notify::is-muted", self._refresh)

        # Network signals
        self._signals.connect(wifi, "notify::is-connected", self._refresh)
        self._signals.connect(wifi, "notify::icon-name", self._refresh)
        self._signals.connect(ethernet, "notify::is-connected", self._refresh)
        self._signals.connect(vpn, "notify::is-connected", self._refresh)

        # Bluetooth signals
        self._signals.connect(bluetooth, "notify::powered", self._refresh)
        self._signals.connect(bluetooth, "notify::connected-devices", self._refresh)

    def _refresh(self, *_):
        self._speaker_icon.image = self._get_speaker_icon()
        self._mic_icon.image = self._get_mic_icon()
        self._mic_icon.visible = self._get_mic_visible()
        self._net_icon.image = self._get_network_icon()
        self._bt_icon.image = self._get_bluetooth_icon()
        self._bt_icon.visible = self._get_bluetooth_visible()

        if audio.speaker.is_muted:
            self._speaker_icon.add_css_class("muted")
        else:
            self._speaker_icon.remove_css_class("muted")

    def _cleanup(self):
        self._signals.disconnect_all()
