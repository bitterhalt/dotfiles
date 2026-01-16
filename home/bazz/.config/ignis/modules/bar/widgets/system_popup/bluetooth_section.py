import asyncio
from ignis import utils, widgets
from ignis.services.bluetooth import BluetoothService
from modules.utils.signal_manager import SignalManager
from settings import config

bluetooth = BluetoothService.get_default()


def exec_async(cmd: str):
    asyncio.create_task(utils.exec_sh_async(cmd))


class BluetoothDeviceItem(widgets.Button):
    def __init__(self, device):
        self._device = device

        self._battery_label = widgets.Label(
            label="",
            css_classes=["bluetooth-battery"],
            visible=False,
        )

        super().__init__(
            css_classes=["bluetooth-device-item", "unset"],
            on_click=lambda *_: self._toggle_connection(),
            child=widgets.Box(
                spacing=8,
                child=[
                    widgets.Icon(
                        image=device.bind("icon_name"),
                        pixel_size=22,
                    ),
                    widgets.Label(
                        label=device.alias,
                        ellipsize="end",
                        max_width_chars=20,
                        hexpand=True,
                        halign="start",
                    ),
                    self._battery_label,
                    widgets.Icon(
                        image="object-select-symbolic",
                        visible=device.bind("connected"),
                        halign="end",
                    ),
                ],
            ),
        )

        self._update_battery()
        device.connect("notify::battery-percentage", lambda *_: self._update_battery())

    def _update_battery(self):
        try:
            battery = self._device.battery_percentage
            if battery is not None and battery >= 0:
                self._battery_label.label = f"{int(battery)}%"
                self._battery_label.visible = True
            else:
                self._battery_label.visible = False
        except:
            self._battery_label.visible = False

    def _toggle_connection(self):
        if self._device.connected:
            asyncio.create_task(self._device.disconnect_from())
        else:
            asyncio.create_task(self._device.connect_to())


class BluetoothSection(widgets.Box):
    def __init__(self):
        super().__init__(vertical=True, spacing=10)
        self._signals = SignalManager()
        self._device_signals = SignalManager()
        self._list_visible = False
        self._scan_timeout = None
        self._icon = widgets.Icon(
            image="bluetooth-symbolic",
            pixel_size=22,
        )

        self._label = widgets.Label(
            label=self._get_label_text(),
            ellipsize="end",
            max_width_chars=16,
        )

        self._status = widgets.Label(
            label="",
            halign="end",
            hexpand=True,
        )

        self._arrow = widgets.Icon(
            image="pan-down-symbolic",
            pixel_size=16,
            css_classes=["expand-arrow"],
        )

        pill_content = widgets.Box(
            spacing=6,
            child=[self._icon, self._label, self._status, self._arrow],
        )

        pill_button = widgets.Button(
            css_classes=["sys-pill", "sys-pill-primary", "unset"],
            child=pill_content,
            hexpand=True,
            on_click=lambda *_: self._toggle_device_list(),
            on_right_click=lambda *_: self._toggle_bluetooth(),
        )

        self._device_list_content = widgets.Box(
            vertical=True,
            spacing=4,
            child=bluetooth.bind(
                "devices",
                transform=lambda devices: (
                    [BluetoothDeviceItem(d) for d in devices]
                    if devices
                    else [
                        widgets.Label(
                            label="No devices found",
                            css_classes=["bluetooth-empty-label"],
                        )
                    ]
                ),
            ),
        )

        settings_button = widgets.Button(
            css_classes=["bluetooth-settings-btn", "unset"],
            on_click=lambda *_: self._open_bluetooth_manager(),
            child=widgets.Box(
                spacing=8,
                halign="center",
                child=[
                    widgets.Icon(
                        image="emblem-system-symbolic",
                        pixel_size=16,
                    ),
                    widgets.Label(
                        label="Bluetooth Settings",
                        css_classes=["bluetooth-settings-label"],
                    ),
                ],
            ),
        )

        self._device_list = widgets.Box(
            vertical=True,
            spacing=6,
            visible=False,
            css_classes=["sys-bluetooth-details"],
            child=[self._device_list_content, widgets.Separator(), settings_button],
        )

        self.child = [pill_button, self._device_list]
        self._signals.connect(bluetooth, "notify::powered", lambda *_: self._update())
        self._signals.connect(bluetooth, "notify::connected-devices", lambda *_: self._on_devices_changed())
        self.connect("destroy", lambda *_: self._cleanup())
        self._on_devices_changed()
        self._update()

    def _cleanup(self):
        """Cleanup all signal connections and stop scanning"""
        self._signals.disconnect_all()
        self._device_signals.disconnect_all()

        if self._scan_timeout:
            try:
                self._scan_timeout.cancel()
            except:
                pass
            self._scan_timeout = None

        try:
            asyncio.create_task(bluetooth.stop_scan())
        except:
            pass

    def _get_label_text(self) -> str:
        """Get label text based on BT state"""
        try:
            if not bluetooth.powered:
                return "Bluetooth Off"

            devices = bluetooth.connected_devices
            if not devices:
                return "Bluetooth"
            elif len(devices) == 1:
                return devices[0].alias
            else:
                return f"{len(devices)} devices"
        except:
            return "Bluetooth"

    def _get_status_text(self) -> str:
        try:
            if not bluetooth.powered:
                return ""

            devices = bluetooth.connected_devices
            if not devices:
                return ""

            dev = devices[0]
            if (
                hasattr(dev, "battery_percentage")
                and dev.battery_percentage is not None
                and dev.battery_percentage >= 0
            ):
                return f"{int(dev.battery_percentage)}%"

            return ""
        except:
            return ""

    def _on_devices_changed(self):
        self._device_signals.disconnect_all()

        try:
            devices = bluetooth.connected_devices
            if devices:
                for dev in devices:
                    self._device_signals.connect(dev, "notify::battery-percentage", lambda *_: self._update())
        except:
            pass

        self._update()

    def _update(self):
        try:
            powered = bluetooth.powered
        except:
            powered = False

        if powered:
            self._icon.image = "bluetooth-symbolic"
        else:
            self._icon.image = "bluetooth-disabled-symbolic"

        self._label.label = self._get_label_text()
        self._status.label = self._get_status_text()

    def _toggle_bluetooth(self):
        """Toggle Bluetooth on/off"""
        try:
            bluetooth.powered = not bluetooth.powered
        except Exception as e:
            print(f"Failed to toggle Bluetooth: {e}")

    def _toggle_device_list(self):
        self._list_visible = not self._list_visible
        self._device_list.visible = self._list_visible
        self._arrow.set_css_classes(["expand-arrow", "rotated"] if self._list_visible else ["expand-arrow"])

        if self._list_visible and bluetooth.powered:
            self._start_scan()
        else:
            self._stop_scan()

    def _start_scan(self):
        """Start Bluetooth scan with auto-stop after 30 seconds"""
        try:
            asyncio.create_task(bluetooth.start_scan())

            if self._scan_timeout:
                self._scan_timeout.cancel()

            self._scan_timeout = utils.Timeout(30000, self._stop_scan)
        except Exception as e:
            print(f"Failed to start Bluetooth scan: {e}")

    def _stop_scan(self):
        """Stop Bluetooth scan"""
        try:
            asyncio.create_task(bluetooth.stop_scan())
        except Exception as e:
            print(f"Failed to stop Bluetooth scan: {e}")

        if self._scan_timeout:
            try:
                self._scan_timeout.cancel()
            except:
                pass
            self._scan_timeout = None

    def _open_bluetooth_manager(self):
        exec_async(config.system.bluetooth_manager)
