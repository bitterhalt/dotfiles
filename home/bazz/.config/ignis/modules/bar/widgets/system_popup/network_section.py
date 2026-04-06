import asyncio
from ignis import utils, widgets
from ignis.services.network import NetworkService, EthernetDevice, WifiAccessPoint
from ignis.window_manager import WindowManager

net = NetworkService.get_default()
wifi = net.wifi
ethernet = net.ethernet
wm = WindowManager.get_default()

# ───────────────────────────────────────────────
# NETWORK ITEMS
# ───────────────────────────────────────────────


class WifiNetworkItem(widgets.Button):
    def __init__(self, ap: WifiAccessPoint):
        super().__init__(
            css_classes=["net-wifi-item", "unset"],
            on_click=lambda *_: asyncio.create_task(ap.connect_to_graphical()),
            child=widgets.Box(
                spacing=8,
                child=[
                    widgets.Icon(image=ap.bind("strength", lambda _v: ap.icon_name)),
                    widgets.Label(label=ap.ssid or "Unknown", ellipsize="end"),
                    widgets.Icon(
                        image="object-select-symbolic",
                        pixel_size=16,
                        visible=ap.bind("is_connected"),
                        hexpand=True,
                        halign="end",
                    ),
                ],
            ),
        )


class EthernetItem(widgets.Button):
    def __init__(self, dev: EthernetDevice):
        super().__init__(
            css_classes=["net-ethernet-item", "unset"],
            on_click=lambda *_: (
                asyncio.create_task(dev.disconnect_from())
                if dev.is_connected
                else asyncio.create_task(dev.connect_to())
            ),
            child=widgets.Box(
                spacing=8,
                child=[
                    widgets.Icon(image="network-wired-symbolic"),
                    widgets.Label(label=dev.name or "Ethernet", ellipsize="end"),
                    widgets.Label(
                        label=dev.bind("is_connected", lambda c: "Disconnect" if c else "Connect"),
                        hexpand=True,
                        halign="end",
                    ),
                ],
            ),
        )


# ───────────────────────────────────────────────
# HELPER FUNCTIONS
# ───────────────────────────────────────────────


def _generic_net_label() -> str:
    if ethernet.is_connected:
        return "Ethernet"
    if wifi.is_connected and wifi.devices:
        return "Wi-Fi"
    if not wifi.enabled:
        return "Airplane mode"
    return "Offline"


# ───────────────────────────────────────────────
# NETWORK SECTION
# ───────────────────────────────────────────────


class NetworkSection(widgets.Box):
    def __init__(self):
        super().__init__(vertical=True, spacing=10)
        self._list_visible = False

        self._label = widgets.Label(
            label=_generic_net_label(),
            ellipsize="end",
            max_width_chars=16,
            hexpand=True,
        )

        self._arrow = widgets.Icon(
            image="pan-down-symbolic",
            pixel_size=16,
            css_classes=["expand-arrow"],
        )

        pill_content = widgets.Box(
            spacing=8,
            child=[
                widgets.Icon(image="wifi-radar", pixel_size=22),
                self._label,
                self._arrow,
            ],
        )

        pill_button = widgets.Button(
            css_classes=["sys-pill", "sys-pill-primary", "unset"],
            child=pill_content,
            hexpand=True,
            on_click=lambda *_: self._toggle_list(),
            on_right_click=lambda *_: self._toggle_airplane(),
        )

        wifi_section = widgets.Box(
            vertical=True,
            spacing=4,
            child=wifi.bind(
                "devices",
                transform=lambda devs: (
                    [widgets.Label(label="No Wi-Fi device detected")]
                    if not devs
                    else devs[0].bind(
                        "access_points",
                        transform=lambda aps: [WifiNetworkItem(a) for a in aps],
                    )
                ),
            ),
        )

        ethernet_section = widgets.Box(
            vertical=True,
            spacing=4,
            child=ethernet.bind("devices", transform=lambda devs: [EthernetItem(d) for d in devs]),
        )

        settings_button = widgets.Button(
            css_classes=["network-settings-btn", "unset"],
            on_click=lambda *_: self._open_network_settings(),
            child=widgets.Box(
                spacing=8,
                halign="center",
                child=[
                    widgets.Icon(
                        image="emblem-system-symbolic",
                        pixel_size=16,
                    ),
                    widgets.Label(
                        label="Network Settings",
                        css_classes=["network-settings-label"],
                    ),
                ],
            ),
        )

        self._device_list = widgets.Box(
            vertical=True,
            spacing=4,
            visible=False,
            css_classes=["sys-net-details"],
            child=[
                wifi_section,
                ethernet_section,
                settings_button,
            ],
        )

        self.child = [pill_button, self._device_list]

        for obj, prop in [
            (wifi, "is_connected"),
            (wifi, "enabled"),
            (ethernet, "is_connected"),
        ]:
            obj.connect(f"notify::{prop.replace('_', '-')}", lambda *_: self._refresh())

        self._refresh()

    def _refresh(self):
        self._label.label = _generic_net_label()

    def _toggle_list(self):
        self._list_visible = not self._list_visible
        self._device_list.visible = self._list_visible
        self._arrow.set_css_classes(["expand-arrow", "rotated"] if self._list_visible else ["expand-arrow"])

        if self._list_visible and wifi.devices:
            asyncio.create_task(wifi.devices[0].scan())

    def _toggle_airplane(self):
        wifi.enabled = not wifi.enabled

    def _open_network_settings(self):
        asyncio.create_task(utils.exec_sh_async("nm-connection-editor"))
        wm.close_window("ignis_SYSTEM_MENU")
