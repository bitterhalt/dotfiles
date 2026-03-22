from ignis import utils, widgets
from ignis.services.mpris import MprisService, MprisPlayer
from modules.utils.signal_manager import SignalManager
from modules.utils.media_utils import MediaPlayerInfo, MediaPlayerControls, MediaPlayerConfig
from settings import config

TIMEOUT = config.ui.media_osd_timeout
mpris = MprisService.get_default()


class MediaOsdWindow(widgets.RevealerWindow):
    def __init__(self):
        self._timeout = None
        self._bound_player = None
        self._player_signals = SignalManager()
        self._mpris_signals = SignalManager()

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

        header = widgets.Box(
            spacing=8,
            css_classes=["media-osd-header"],
            child=[
                self._app_icon,
                self._app_name,
                widgets.Box(hexpand=True),
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

        revealer = widgets.Revealer(
            child=pill,
            reveal_child=True,
            transition_type="slide_down",
            transition_duration=config.animations.revealer_duration,
        )

        root = widgets.Box(
            halign="center",
            valign="start",
            child=[revealer],
        )

        super().__init__(
            monitor=config.ui.primary_monitor,
            layer="overlay",
            anchor=["top"],
            namespace="ignis_MEDIA_OSD",
            visible=False,
            css_classes=["media-osd-window"],
            child=root,
            revealer=revealer,
        )

        self._mpris_signals.connect(mpris, "notify::players", self._on_players_changed)
        self.connect("notify::visible", self._on_visible_changed)
        self.connect("destroy", self._cleanup)
        self._bind_active_player()

    def _cleanup(self, *_):
        self._player_signals.disconnect_all()
        self._mpris_signals.disconnect_all()
        if self._timeout:
            try:
                self._timeout.cancel()
            except Exception:
                pass
            self._timeout = None

    def _on_players_changed(self, *_):
        player = MediaPlayerControls.get_active_player()
        if player != self._bound_player:
            self._bind_active_player()

    def _bind_active_player(self):
        self._player_signals.disconnect_all()
        player = MediaPlayerControls.get_active_player()
        self._bound_player = player

        if not player:
            self._apply_no_player()
            return

        self._apply_player(player)

        self._player_signals.connect(player, "notify::title", lambda *_: self._on_track_changed(player))
        self._player_signals.connect(player, "notify::artist", lambda *_: self._on_track_changed(player))
        self._player_signals.connect(player, "notify::art-url", lambda *_: self._on_track_changed(player))
        self._player_signals.connect(player, "notify::playback-status", lambda *_: self._update_play_icon(player))
        self._player_signals.connect(player, "notify::can-go-previous", lambda *_: self._update_button_states(player))
        self._player_signals.connect(player, "notify::can-go-next", lambda *_: self._update_button_states(player))

    def _on_track_changed(self, player: MprisPlayer):
        self._apply_player(player)

    def _apply_no_player(self):
        self._app_icon.image = MediaPlayerConfig.PLAYER_ICONS[None]
        self._app_name.label = ""
        self._title_label.label = ""
        self._artist_label.label = "No media playing"
        self._album_art.visible = False
        self._btn_prev.visible = False
        self._btn_play.visible = False
        self._btn_next.visible = False

    def _apply_player(self, player: MprisPlayer):
        self._app_icon.image = MediaPlayerInfo.get_player_icon(player)
        self._app_name.label = MediaPlayerInfo.get_player_name(player)
        self._title_label.label = player.title or "Unknown Title"
        self._artist_label.label = player.artist or "Unknown Artist"

        if player.art_url:
            self._album_art.image = player.art_url
            self._album_art.visible = True
        else:
            self._album_art.visible = False

        self._btn_prev.visible = True
        self._btn_play.visible = True
        self._btn_next.visible = True

        self._update_play_icon(player)
        self._update_button_states(player)

    def _update_play_icon(self, player: MprisPlayer):
        self._btn_play_icon.image = MediaPlayerControls.get_play_pause_icon(player)

    def _update_button_states(self, player: MprisPlayer):
        self._btn_prev.set_sensitive(player.can_go_previous)
        self._btn_next.set_sensitive(player.can_go_next)

    def _on_visible_changed(self, *_):
        if self.get_visible():
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
