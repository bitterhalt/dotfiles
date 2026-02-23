from ignis import widgets
from ignis.services.mpris import MprisPlayer, MprisService
from ignis.window_manager import WindowManager
from modules.utils.media_utils import MediaPlayerControls
from modules.utils.signal_manager import SignalManager

mpris = MprisService.get_default()
wm = WindowManager.get_default()


class MediaPill(widgets.Box):
    def __init__(self, player: MprisPlayer):
        super().__init__(
            vertical=True,
            spacing=12,
            css_classes=["media-pill-nc"],
            halign="fill",
            valign="center",
            hexpand=True,
        )

        self._player = player
        self._signals = SignalManager()

        title = widgets.Label(
            label=player.bind("title", lambda t: t or "Unknown"),
            ellipsize="end",
            max_width_chars=22,
            css_classes=["media-pill-title"],
        )

        artist = widgets.Label(
            label=player.bind("artist", lambda a: a or "Unknown Artist"),
            ellipsize="end",
            max_width_chars=22,
            css_classes=["media-pill-artist"],
        )

        text_box = widgets.Box(
            halign="center",
            hexpand=True,
            spacing=2,
            vertical=True,
            child=[
                title,
                artist,
            ],
        )

        self._btn_prev = widgets.Button(
            css_classes=["media-pill-nc-control"],
            on_click=lambda *_: MediaPlayerControls.previous(),
            child=widgets.Icon(
                image="media-skip-backward-symbolic",
                pixel_size=18,
            ),
        )

        self._btn_play_icon = widgets.Icon(
            image=MediaPlayerControls.get_play_pause_icon(player),
            pixel_size=18,
        )

        self._btn_play = widgets.Button(
            css_classes=["media-pill-nc-control", "primary"],
            child=self._btn_play_icon,
            on_click=lambda *_: MediaPlayerControls.play_pause(),
        )

        self._btn_next = widgets.Button(
            css_classes=["media-pill-nc-control"],
            on_click=lambda *_: MediaPlayerControls.next(),
            child=widgets.Icon(
                image="media-skip-forward-symbolic",
                pixel_size=18,
            ),
        )

        controls = widgets.Box(
            spacing=4,
            halign="center",
            css_classes=["media-pill-nc-controls"],
            child=[self._btn_prev, self._btn_play, self._btn_next],
        )

        content = widgets.Box(
            spacing=10,
            child=[text_box],
        )

        self.child = [content, controls]
        self._bind_play_icon()
        self._update_button_states()

        player.connect("notify::can-go-previous", lambda *_: self._update_button_states())
        player.connect("notify::can-go-next", lambda *_: self._update_button_states())

        self.connect("destroy", lambda *_: self._cleanup())

    def _cleanup(self):
        self._signals.disconnect_all()

    def _bind_play_icon(self):
        def update_icon(*_):
            self._btn_play_icon.image = MediaPlayerControls.get_play_pause_icon(self._player)

        self._signals.connect(self._player, "notify::playback-status", update_icon)
        update_icon()

    def _update_button_states(self):
        self._btn_prev.set_sensitive(self._player.can_go_previous)
        self._btn_next.set_sensitive(self._player.can_go_next)


class NoMediaPill(widgets.Box):
    def __init__(self):
        icon = widgets.Icon(
            image="folder-music-symbolic",
            pixel_size=32,
            css_classes=["media-pill-nc-icon"],
            opacity=0.5,
        )

        title = widgets.Label(
            label="No media playing",
            css_classes=["media-pill-nc-title"],
        )

        content = widgets.Box(
            vertical=True,
            spacing=12,
            halign="center",
            valign="center",
            child=[icon, title],
        )

        super().__init__(
            vertical=True,
            spacing=12,
            css_classes=["media-pill-nc"],
            halign="fill",
            valign="center",
            hexpand=True,
            child=[content],
        )


class MediaCenterWidget(widgets.Box):
    def __init__(self):
        self._current_player = None
        self._pill_content = widgets.Box()
        super().__init__(
            vertical=True,
            css_classes=["media-center-nc-wrapper"],
            halign="fill",
            valign="start",
            visible=True,
            child=[self._pill_content],
        )

        mpris.connect("player_added", self._on_player_added)
        mpris.connect("notify::players", lambda *_: self._refresh())

        self._refresh()

    def _on_player_added(self, service, player: MprisPlayer):
        player.connect("closed", lambda *_: self._on_player_closed(player))
        self._refresh()

    def _on_player_closed(self, closed_player: MprisPlayer):
        if self._current_player == closed_player:
            self._current_player = None
            self._refresh()

    def _refresh(self):
        players = mpris.players

        if not players:
            self._pill_content.child = [NoMediaPill()]
            self._current_player = None
            return

        player = players[0]

        if self._current_player == player:
            return

        self._current_player = player
        self._pill_content.child = [MediaPill(player)]
