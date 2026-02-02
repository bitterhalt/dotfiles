import asyncio
from ignis import widgets
from ignis.services.system_tray import SystemTrayService, SystemTrayItem

system_tray = SystemTrayService.get_default()


class TrayItem(widgets.Button):
    def __init__(self, item: SystemTrayItem):
        if item.menu:
            menu = item.menu.copy()
        else:
            menu = None

        super().__init__(
            child=widgets.Box(
                child=[
                    widgets.Icon(image=item.bind("icon"), pixel_size=22),
                    menu,
                ]
            ),
            tooltip_text=item.bind("tooltip"),
            on_click=lambda x: asyncio.create_task(item.activate_async()),
            on_right_click=lambda x: menu.popup() if menu else None,
            css_classes=["tray-item", "unset"],
        )

        item.connect("removed", lambda x: self.unparent())


class SystemTrayWidget(widgets.Box):
    def __init__(self):
        super().__init__(
            css_classes=["system-tray"],
            spacing=10,
        )

        for item in system_tray.items:
            self.append(TrayItem(item))

        system_tray.connect("added", lambda x, item: self.append(TrayItem(item)))
