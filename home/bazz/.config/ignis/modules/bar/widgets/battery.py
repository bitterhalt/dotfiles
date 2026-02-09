from ignis import widgets
from ignis.services.upower import UPowerService, UPowerDevice
from settings import config

upower = UPowerService.get_default()


class BatteryItem(widgets.Box):
    def __init__(self, device: UPowerDevice):
        super().__init__(
            css_classes=["battery"],
            spacing=4,
            setup=lambda self: self._setup_styles(device),
            child=[
                widgets.Icon(
                    image=device.bind("icon_name"),
                    pixel_size=22,
                ),
                widgets.Label(
                    label=device.bind("percentage", lambda p: f"{int(p)}%"),
                ),
            ],
        )

        device.connect("removed", lambda x: self.unparent())

        device.connect("notify::percentage", lambda *_: self._update_warning_class(device))

    def _setup_styles(self, device):
        self._update_warning_class(device)

    def _update_warning_class(self, device):
        percent = device.percentage

        if percent < config.battery.critical_threshold:
            self.add_css_class("critical")
            self.remove_css_class("warning")
        elif percent < config.battery.warning_threshold:
            self.add_css_class("warning")
            self.remove_css_class("critical")
        else:
            self.remove_css_class("warning")
            self.remove_css_class("critical")


class BatteryWidget(widgets.Box):
    def __init__(self):
        super().__init__(
            setup=lambda self: upower.connect("battery-added", lambda x, device: self.append(BatteryItem(device))),
        )
