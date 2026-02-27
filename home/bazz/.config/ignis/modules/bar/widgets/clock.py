import datetime
from ignis import utils, widgets
from ignis.options import options
from ignis.services.notifications import NotificationService
from ignis.window_manager import WindowManager
from modules.utils.signal_manager import SignalManager
from settings import config

wm = WindowManager.get_default()
notifications = NotificationService.get_default()


class ClockWidget(widgets.Button):
    def __init__(self):
        self._signals = SignalManager()
        self._clock_poll = None
        self._clock_label = widgets.Label(css_classes=["clock"])
        self._notif_dot = widgets.Label(
            label="●",
            css_classes=["clock-notif-dot"],
            visible=False,
        )

        self._dnd_icon = widgets.Icon(
            image="notification-disabled-symbolic",
            pixel_size=22,
            css_classes=["clock-dnd-icon"],
            visible=options.notifications.bind("dnd"),
        )

        self._dnd_tracker = widgets.Label(
            visible=options.notifications.bind("dnd"),
        )
        self._dnd_tracker.connect("notify::visible", lambda *_: self._update_notifications())

        clock_content = widgets.Box(
            spacing=6,
            child=[self._clock_label, self._dnd_icon, self._notif_dot],
        )

        super().__init__(
            child=clock_content,
            css_classes=["clock-button", "unset"],
            on_click=lambda x: wm.toggle_window("ignis_NOTIFICATION_CENTER"),
            on_right_click=lambda x: self._toggle_dnd(),
        )

        self._setup_clock()
        self._setup_notifications()
        self.connect("destroy", self._cleanup)

    def _toggle_dnd(self):
        options.notifications.set_dnd(not options.notifications.dnd)

    def _setup_clock(self):
        self._clock_poll = utils.Poll(60000, lambda *_: self._update_time())
        self._clock_label.set_property("label", self._clock_poll.bind("output"))

    def _update_time(self):
        time_str = datetime.datetime.now().strftime("%H:%M")

        try:
            from modules.osd.clock_osd import update_barless_clock

            update_barless_clock()
        except:
            pass

        return time_str

    def _setup_notifications(self):
        self._signals.connect(notifications, "notified", self._on_new_notification)
        self._signals.connect(notifications, "new_popup", self._on_new_notification)

        for nt in notifications.notifications:
            self._watch_notification(nt)

        self._update_notifications()

    def _should_show_notification(self, notif) -> bool:
        return not config.ui.notifications.should_filter(notif)

    def _update_notifications(self, *_):
        if options.notifications.dnd:
            self._notif_dot.visible = False
            return

        all_notifs = notifications.notifications
        visible_notifs = [n for n in all_notifs if self._should_show_notification(n)]
        count = len(visible_notifs)
        has_critical = any(n.urgency == 2 for n in visible_notifs)

        if count > 0:
            self._notif_dot.visible = True
            self._notif_dot.remove_css_class("normal")
            self._notif_dot.remove_css_class("critical")
            self._notif_dot.add_css_class("critical" if has_critical else "normal")
        else:
            self._notif_dot.visible = False

    def _watch_notification(self, nt):
        self._signals.connect(nt, "closed", self._update_notifications)
        try:
            self._signals.connect(nt, "dismissed", self._update_notifications)
        except Exception:
            pass

    def _on_new_notification(self, _, nt):
        self._watch_notification(nt)
        self._update_notifications()

    def _cleanup(self, *_):
        self._signals.disconnect_all()
        if self._clock_poll:
            try:
                self._clock_poll.cancel()
            except:
                pass
