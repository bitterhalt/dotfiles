import asyncio
from ignis import widgets
from settings import config
from ignis.services.system_tray import SystemTrayService, SystemTrayItem

system_tray = SystemTrayService.get_default()


class TrayItem(widgets.Button):
    def __init__(self, item: SystemTrayItem, on_removed_callback=None):
        if item.menu:
            menu = item.menu.copy()
        else:
            menu = None

        super().__init__(
            child=widgets.Box(
                child=[
                    widgets.Icon(
                        image=item.bind("icon"),
                        pixel_size=config.ui.bar_tray_icon_size,
                    ),
                    menu,
                ]
            ),
            on_click=lambda x: self._safe_activate(item),
            on_right_click=lambda x: menu.popup() if menu else None,
            css_classes=["tray-item", "unset"],
        )

        item.connect("removed", lambda x: self._on_removed(on_removed_callback))

    def _on_removed(self, callback):
        self.unparent()
        if callback:
            callback()

    def _safe_activate(self, item):
        async def activate():
            try:
                await item.activate_async()
            except Exception as e:
                try:
                    item.secondary_activate()
                except Exception:
                    pass

        asyncio.create_task(activate())


class SystemTrayWidget(widgets.Box):
    def __init__(self):
        self._items_box = widgets.Box(
            css_classes=["tray-items"],
            spacing=14,
        )

        super().__init__(
            css_classes=["system-tray"],
            child=[self._items_box],
            visible=False,
        )

        for item in system_tray.items:
            self._items_box.append(TrayItem(item, self._update_visibility))

        system_tray.connect("added", lambda x, item: self._on_item_added(item))
        self._update_visibility()

    def _on_item_added(self, item):
        tray_item = TrayItem(item, self._update_visibility)
        self._items_box.append(tray_item)
        self._update_visibility()

    def _update_visibility(self):
        has_items = len(self._items_box.child) > 0
        self.visible = has_items
