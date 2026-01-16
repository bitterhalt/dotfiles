from ignis import widgets
from ignis.services.notifications import NotificationService
from modules.notifications.widgets import NotificationHistoryItem
from modules.utils.signal_manager import SignalManager
from settings import config

notifications = NotificationService.get_default()
MAX_NOTIFICATIONS = config.ui.notifications.max_history


class NotificationList:
    def __init__(self):
        self._signals = SignalManager()
        self._item_signals = {}
        self._notif_list = widgets.Box(vertical=True, css_classes=["content-list"])

        self._notif_empty = widgets.Label(
            label="No notifications",
            css_classes=["empty-state"],
            vexpand=True,
            valign="center",
            visible=False,
        )

        self.scroll = widgets.Scroll(
            vexpand=True,
            vscrollbar_policy="automatic",
            child=widgets.Box(
                vertical=True,
                valign="start",
                child=[self._notif_list, self._notif_empty],
            ),
        )

        self._load_notifications()
        self._signals.connect(notifications, "notified", self._on_notified)
        self.scroll.connect("destroy", lambda *_: self._cleanup())

    def _should_show_notification(self, notif) -> bool:
        return not config.ui.notifications.should_filter(notif)

    def _load_notifications(self):
        self._clear_items()

        all_notifs = notifications.notifications
        filtered_notifs = [n for n in all_notifs if self._should_show_notification(n)]
        items = filtered_notifs[:MAX_NOTIFICATIONS]

        for notif in items:
            item = NotificationHistoryItem(notif)
            self._notif_list.append(item)

            sig_manager = SignalManager()
            sig_manager.connect(notif, "closed", lambda *_: self._on_notification_closed())
            self._item_signals[id(notif)] = sig_manager

        self._update_empty_state()

    def _clear_items(self):
        for sig_manager in self._item_signals.values():
            sig_manager.disconnect_all()
        self._item_signals.clear()

        self._notif_list.child = []

    def _on_notified(self, _, notif):
        if not self._should_show_notification(notif):
            return

        item = NotificationHistoryItem(notif)
        self._notif_list.prepend(item)
        sig_manager = SignalManager()
        sig_manager.connect(notif, "closed", lambda *_: self._on_notification_closed())
        self._item_signals[id(notif)] = sig_manager

        visible_count = len([n for n in notifications.notifications if self._should_show_notification(n)])

        if visible_count > MAX_NOTIFICATIONS:
            excess_item = self._notif_list.child[-1]
            excess_item.visible = False
            excess_item.unparent()

        self._update_empty_state()

    def _on_notification_closed(self):
        self._load_notifications()

    def _update_empty_state(self):
        visible_notifs = [n for n in notifications.notifications if self._should_show_notification(n)]
        has_notifications = len(visible_notifs) > 0
        self._notif_empty.visible = not has_notifications

    def clear_all(self):
        notifications.clear_all()
        self._clear_items()
        self._update_empty_state()

    def _cleanup(self, *_):
        self._clear_items()
        self._signals.disconnect_all()
