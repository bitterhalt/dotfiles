import asyncio
from ignis import widgets
from ignis.services.network import EthernetDevice, VpnConnection, WifiAccessPoint


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
