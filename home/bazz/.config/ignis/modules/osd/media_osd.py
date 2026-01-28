from ignis import utils, widgets
from ignis.services.mpris import MprisService
from modules.utils.signal_manager import SignalManager
from modules.utils.media_utils import MediaPlayerInfo, MediaPlayerControls, MediaPlayerConfig
from settings import config

TIMEOUT = config.ui.media_osd_timeout
mpris = MprisService.get_default()


class MediaOsdWindow(widgets.Window):
    def __init__(self):
        self._timeout = None
        self._bound_player = None
        self._signals = SignalManager()

        self._app_icon = widgets.Icon(
            image=MediaPlayerConfig.PLAYER_ICONS[None],
            pixel_size=20,
            css_classes=["media-osd-app-icon"],
        )

        self._app_name = widgets.Label(
            label="Media Player",
            ellipsize="end",
            max_width_chars=30,
            css_classes=["media-osd-app-name"],
        )

        close_btn = widgets.Button(
            child=widgets.Icon(
                image="window-close-symbolic",
                pixel_size=20,
            ),
            css_classes=["close-btn"],
            halign="end",
            valign="center",
            on_click=lambda *_: self.set_visible(False),
        )

        header = widgets.Box(
            spacing=8,
            css_classes=["media-osd-header"],
            child=[
                self._app_icon,
                self._app_name,
                widgets.Box(hexpand=True),
                close_btn,
            ],
        )

        self._album_art = widgets.Picture(
            css_classes=["media-osd-art"],
            width=300,
            height=200,
        )

        self._title_label = widgets.Label(
            label="No Title",
            ellipsize="end",
            max_width_chars=35,
            css_classes=["media-osd-title"],
            halign="center",
        )

        self._artist_label = widgets.Label(
            label="No Artist",
            ellipsize="end",
            max_width_chars=35,
            css_classes=["media-osd-artist"],
            halign="center",
        )

        labels = widgets.Box(
            vertical=True,
            spacing=4,
            halign="center",
            child=[self._title_label, self._artist_label],
        )

        self._btn_prev = widgets.Button(
            css_classes=["media-osd-control"],
            on_click=lambda *_: MediaPlayerControls.previous(),
            child=widgets.Icon(
                image="media-skip-backward-symbolic",
                pixel_size=22,
            ),
        )

        self._btn_play_icon = widgets.Icon(
            image="media-playback-start-symbolic",
            pixel_size=22,
        )

        self._btn_play = widgets.Button(
            css_classes=["media-osd-control", "primary"],
            child=self._btn_play_icon,
            on_click=lambda *_: MediaPlayerControls.play_pause(),
        )

        self._btn_next = widgets.Button(
            css_classes=["media-osd-control"],
            on_click=lambda *_: MediaPlayerControls.next(),
            child=widgets.Icon(
                image="media-skip-forward-symbolic",
                pixel_size=22,
            ),
        )

        controls = widgets.Box(
            spacing=6,
            halign="center",
            css_classes=["media-osd-controls"],
            child=[self._btn_prev, self._btn_play, self._btn_next],
        )

        pill = widgets.Box(
            vertical=True,
            spacing=12,
            css_classes=["media-osd"],
            child=[header, self._album_art, labels, controls],
        )

        root = widgets.Box(
            halign="center",
            valign="start",
            child=[pill],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            layer="overlay",
            anchor=["top"],
            namespace="ignis_MEDIA_OSD",
            visible=False,
            css_classes=["media-osd-window"],
            child=root,
        )

        self.connect("notify::visible", self._on_visible_changed)
        self.connect("destroy", self._cleanup)

    def _cleanup(self, *_):
        self._signals.disconnect_all()
        if self._timeout:
            try:
                self._timeout.cancel()
            except:
                pass
            self._timeout = None

    def _on_visible_changed(self, *_):
        if self.get_visible():
            self._update_content()

            if self._timeout:
                self._timeout.cancel()

            self._timeout = utils.Timeout(
                TIMEOUT,
                lambda: self.set_visible(False),
            )
        else:
            if self._timeout:
                self._timeout.cancel()
                self._timeout = None

    def show_osd(self):
        self.set_visible(True)

    def _bind_play_icon(self, player):
        self._signals.disconnect_all()

        def update_icon(*_):
            self._btn_play_icon.image = MediaPlayerControls.get_play_pause_icon(player)

        self._signals.connect(player, "notify::playback-status", update_icon)
        update_icon()

    def _update_content(self):
        player = MediaPlayerControls.get_active_player()

        if not player:
            self._bound_player = None
            self._app_icon.image = MediaPlayerConfig.PLAYER_ICONS[None]
            self._app_name.label = "No Media"
            self._title_label.label = "No media playing"
            self._artist_label.label = ""
            self._album_art.visible = False
            self._btn_play_icon.image = "media-playback-stop-symbolic"
            self._btn_prev.set_sensitive(False)
            self._btn_next.set_sensitive(False)
            return

        self._app_icon.image = MediaPlayerInfo.get_player_icon(player)
        self._app_name.label = MediaPlayerInfo.get_player_name(player)
        self._title_label.label = player.title or "Unknown Title"
        self._artist_label.label = player.artist or "Unknown Artist"

        if player.art_url:
            self._album_art.image = player.art_url
            self._album_art.visible = True
        else:
            self._album_art.visible = False

        if self._bound_player != player:
            self._bind_play_icon(player)
            self._bound_player = player

        self._btn_prev.set_sensitive(player.can_go_previous)
        self._btn_next.set_sensitive(player.can_go_next)
