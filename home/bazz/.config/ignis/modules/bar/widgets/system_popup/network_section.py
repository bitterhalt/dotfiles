import asyncio
from ignis import utils, widgets
from ignis.services.network import NetworkService, EthernetDevice, VpnConnection, WifiAccessPoint

net = NetworkService.get_default()
wifi = net.wifi
ethernet = net.ethernet
vpn = net.vpn


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
                        visible=ap.bind("is_connected"),
                        hexpand=True,
                        halign="end",
                    ),
                ],
            ),
        )


class VpnNetworkItem(widgets.Button):
    def __init__(self, conn: VpnConnection):
        super().__init__(
            css_classes=["net-vpn-item", "unset"],
            on_click=lambda *_: asyncio.create_task(conn.toggle_connection()),
            child=widgets.Box(
                spacing=8,
                child=[
                    widgets.Icon(image="network-vpn-symbolic", pixel_size=22),
                    widgets.Label(label=conn.name, ellipsize="end", max_width_chars=20),
                    widgets.Label(
                        label=conn.bind("is_connected", lambda c: "Disconnect" if c else "Connect"),
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
    if vpn.is_connected:
        return "VPN"
    if ethernet.is_connected:
        return "Ethernet"
    if wifi.is_connected and wifi.devices:
        try:
            ap = wifi.devices[0].ap
            if ap and ap.ssid:
                return ap.ssid
        except Exception:
            pass
        return "Wi-Fi"
    if not wifi.enabled:
        return "Airplane mode"
    return "Offline"


def _net_signal_percent() -> str:
    if wifi.is_connected and wifi.devices:
        try:
            ap = wifi.devices[0].ap
            if ap is not None and ap.strength is not None:
                return f"{ap.strength}%"
        except Exception:
            return "…"
    if vpn.is_connected:
        return "VPN"
    if ethernet.is_connected:
        return "LAN"
    return ""


def _primary_net_icon() -> str:
    if vpn.is_connected:
        return vpn.icon_name
    if ethernet.is_connected:
        return ethernet.icon_name
    if wifi.is_connected:
        return wifi.icon_name
    return "network-offline-symbolic"


# ───────────────────────────────────────────────
# NETWORK SECTION
# ───────────────────────────────────────────────


class NetworkSection(widgets.Box):
    def __init__(self):
        super().__init__(vertical=True, spacing=10)
        self._list_visible = False
        self._icon = widgets.Icon(image=_primary_net_icon(), pixel_size=22)
        self._label = widgets.Label(
            label=_generic_net_label(),
            ellipsize="end",
            max_width_chars=16,
        )

        self._percent = widgets.Label(
            label=_net_signal_percent(),
            halign="end",
            hexpand=True,
        )

        self._arrow = widgets.Icon(
            image="pan-down-symbolic",
            pixel_size=16,
            css_classes=["expand-arrow"],
        )

        pill_content = widgets.Box(
            spacing=16,
            child=[self._icon, self._label, self._percent, self._arrow],
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

        vpn_section = widgets.Box(
            vertical=True,
            spacing=4,
            child=vpn.bind(
                "connections",
                transform=lambda conns: [VpnNetworkItem(c) for c in conns],
            ),
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
            spacing=6,
            visible=False,
            css_classes=["sys-net-details"],
            child=[
                wifi_section,
                ethernet_section,
                vpn_section,
                widgets.Separator(),
                settings_button,
            ],
        )

        self.child = [pill_button, self._device_list]

        for obj, prop in [
            (wifi, "is_connected"),
            (wifi, "strength"),
            (wifi, "enabled"),
            (ethernet, "is_connected"),
            (vpn, "is_connected"),
        ]:
            obj.connect(f"notify::{prop.replace('_', '-')}", lambda *_: self._refresh())

        self._refresh()

    def _refresh(self):
        self._icon.image = _primary_net_icon()
        self._label.label = _generic_net_label()
        self._percent.label = _net_signal_percent()

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
