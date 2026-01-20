from ignis import widgets
from ignis.services.mpris import MprisPlayer, MprisService
from ignis.window_manager import WindowManager
from modules.utils.media_utils import MediaPlayerInfo

mpris = MprisService.get_default()
wm = WindowManager.get_default()


class MediaPill(widgets.Box):
    def __init__(self, player: MprisPlayer):
        super().__init__(
            spacing=12,
            css_classes=["media-pill"],
            halign="fill",
            valign="center",
            hexpand=True,
        )

        self._player = player
        self._icon = widgets.Icon(
            image=MediaPlayerInfo.get_player_icon(player),
            pixel_size=28,
            css_classes=["media-pill-icon"],
        )

        player.connect("notify::desktop-entry", lambda *_: self._update_icon())
        player.connect("notify:: track-id", lambda *_: self._update_icon())

        title = widgets.Label(
            label=player.bind("title", lambda t: t or "Unknown"),
            ellipsize="end",
            max_width_chars=30,
            css_classes=["media-pill-title"],
            halign="start",
        )

        artist = widgets.Label(
            label=player.bind("artist", lambda a: a or "Unknown Artist"),
            ellipsize="end",
            max_width_chars=30,
            css_classes=["media-pill-artist"],
            halign="start",
        )

        text_box = widgets.Box(
            vertical=True,
            spacing=2,
            child=[title, artist],
        )

        self.child = [self._icon, text_box]

    def _update_icon(self):
        self._icon.image = MediaPlayerInfo.get_player_icon(self._player)


class MediaCenterWidget(widgets.Button):
    def __init__(self):
        self._current_player = None
        self._pill_content = widgets.Box()
        super().__init__(
            css_classes=["media-center-wrapper", "unset"],
            halign="fill",
            valign="center",
            on_click=lambda x: self._open_media_osd(),
            child=self._pill_content,
        )

        mpris.connect("player_added", self._on_player_added)
        mpris.connect("notify:: players", lambda *_: self._refresh())

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
            self.visible = False
            self._pill_content.child = []
            self._current_player = None
            return

        player = players[0]

        if self._current_player == player:
            return

        self._current_player = player
        self.visible = True
        self._pill_content.child = [MediaPill(player)]

    def _open_media_osd(self):
        wm.close_window("ignis_NOTIFICATION_CENTER")
        wm.open_window("ignis_MEDIA_OSD")
