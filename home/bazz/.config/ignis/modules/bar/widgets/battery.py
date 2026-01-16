from ignis import widgets
from ignis.services.upower import UPowerService
from modules.utils.signal_manager import SignalManager
from settings import config

upower = UPowerService.get_default()


class BatteryWidget(widgets.Box):
    def __init__(self):
        super().__init__(
            css_classes=["battery"],
            spacing=4,
            visible=False,
        )
        self._battery = None
        self._signals = SignalManager()
        self._icon = widgets.Icon(
            image="battery-missing-symbolic",
            pixel_size=22,
        )
        self._label = widgets.Label(
            label="--",
        )

        self.child = [self._icon, self._label]
        self._signals.connect(upower, "battery-added", lambda _, device: self._on_battery_added(device))
        self._check_existing_batteries()
        self.connect("destroy", lambda *_: self._cleanup())

    def _check_existing_batteries(self):
        for device in upower.devices:
            if hasattr(device, "percentage") and hasattr(device, "is_charging"):
                self._on_battery_added(device)
                break

    def _on_battery_added(self, device):
        """Handle battery device being added"""
        if self._battery is not None:
            return

        self._battery = device
        self.visible = True
        self._icon.image = device.icon_name
        self._label.label = f"{int(device.percentage)}%"
        self._label.label = device.bind("percentage", lambda p: f"{int(p)}%")
        self._setup_signals()
        self._update_all()

        # Handle battery removal
        self._signals.connect(device, "removed", lambda *_: self._on_battery_removed())

    def _on_battery_removed(self):
        """Handle battery being removed"""
        self._battery = None
        self.visible = False
        self._icon.image = "battery-missing-symbolic"
        self._label.label = "--"

    def _cleanup(self):
        self._signals.disconnect_all()

    def _setup_signals(self):
        if not self._battery:
            return

        battery = self._battery

        for signal in [
            "notify::percentage",
            "notify::is-charging",
            "notify::is-discharging",
            "notify::time-to-full",
            "notify::time-to-empty",
        ]:
            self._signals.connect(battery, signal, lambda *_: self._update_all())

    def _update_all(self):
        """Update all battery UI elements"""
        if not self._battery:
            return
        self._update_tooltip()
        self._update_warning_class()

    def _update_tooltip(self):
        """Update tooltip"""
        battery = self._battery

        status = "Charging" if battery.is_charging else "Discharging" if battery.is_discharging else "Full"

        time_str = ""
        if battery.is_charging and battery.time_to_full > 0:
            hours = battery.time_to_full // 3600
            mins = (battery.time_to_full % 3600) // 60
            time_str = f"\nTime to full: {hours}h {mins}m"
        elif battery.is_discharging and battery.time_to_empty > 0:
            hours = battery.time_to_empty // 3600
            mins = (battery.time_to_empty % 3600) // 60
            time_str = f"\nTime remaining: {hours}h {mins}m"

        self.set_tooltip_text(f"{battery.device_name}\n{status}: {int(battery.percentage)}%{time_str}")

    def _update_warning_class(self):
        """Update CSS classes based on battery level"""
        percent = self._battery.percentage

        if percent < config.battery.critical_threshold:
            self.add_css_class("critical")
            self.remove_css_class("warning")
        elif percent < config.battery.warning_threshold:
            self.add_css_class("warning")
            self.remove_css_class("critical")
        else:
            self.remove_css_class("warning")
            self.remove_css_class("critical")


def battery_widget():
    return BatteryWidget()
