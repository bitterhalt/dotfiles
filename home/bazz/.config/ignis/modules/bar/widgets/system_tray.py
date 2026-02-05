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
        self._expanded = False

        self._arrow = widgets.Icon(
            image="pan-start-symbolic",
            pixel_size=16,
            css_classes=["tray-arrow"],
        )

        self._toggle_btn = widgets.Button(
            css_classes=["tray-toggle-btn", "unset"],
            child=self._arrow,
            on_click=lambda x: self._toggle_tray(),
            tooltip_text="Show system tray",
        )

        self._items_box = widgets.Box(
            css_classes=["tray-items"],
        )

        self._revealer = widgets.Revealer(
            child=self._items_box,
            reveal_child=False,
            transition_type="slide_left",
            transition_duration=200,
        )

        super().__init__(
            css_classes=["system-tray"],
            child=[self._toggle_btn, self._revealer],
        )

        for item in system_tray.items:
            self._items_box.append(TrayItem(item))

        system_tray.connect("added", lambda x, item: self._on_item_added(item))

        self._update_visibility()

    def _on_item_added(self, item):
        """Handle new tray item"""
        tray_item = TrayItem(item)
        self._items_box.append(tray_item)

        item.connect("removed", lambda x: self._update_visibility())

        self._update_visibility()

    def _update_visibility(self):
        has_items = len(self._items_box.child) > 0
        self.visible = has_items

        if not has_items and self._expanded:
            self._expanded = False
            self._revealer.reveal_child = False
            self._arrow.image = "pan-start-symbolic"
            self._toggle_btn.set_tooltip_text("Show system tray")

    def _toggle_tray(self):
        self._expanded = not self._expanded
        self._revealer.reveal_child = self._expanded

        if self._expanded:
            self._arrow.image = "pan-end-symbolic"
            self._toggle_btn.set_tooltip_text("Hide system tray")
        else:
            self._arrow.image = "pan-start-symbolic"
            self._toggle_btn.set_tooltip_text("Show system tray")
