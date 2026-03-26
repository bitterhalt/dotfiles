import os
from ignis.services.mpris import MprisService, MprisPlayer
from settings import config

mpris = MprisService.get_default()


def _clear_art_cache():
    try:
        cache_dir = str(config.paths.art_url_cache_dir)
        if not os.path.isdir(cache_dir):
            return
        for filename in os.listdir(cache_dir):
            filepath = os.path.join(cache_dir, filename)
            if os.path.isfile(filepath):
                os.remove(filepath)
    except Exception as e:
        print(f"Failed to clear art cache: {e}")


_clear_art_cache()


class MediaPlayerConfig:
    PLAYER_ICONS = {
        "spotify": "spotify",
        "firefox": "firefox",
        "zen": "zen-browser",
        "vlc": "vlc",
        "mpv": "mpv",
        None: "folder-music-symbolic",
    }

    PLAYER_NAMES = {
        "spotify": "Spotify",
        "firefox": "Firefox",
        "zen": "Zen Browser",
        "vlc": "VLC",
        "mpv": "MPV",
        None: "Currently playing",
    }


class MediaPlayerInfo:
    @staticmethod
    def get_player_icon(player: MprisPlayer | None) -> str:
        if not player:
            return MediaPlayerConfig.PLAYER_ICONS[None]

        entry = player.desktop_entry
        return MediaPlayerConfig.PLAYER_ICONS.get(entry, MediaPlayerConfig.PLAYER_ICONS[None])

    @staticmethod
    def get_player_name(player: MprisPlayer | None) -> str:
        if not player:
            return MediaPlayerConfig.PLAYER_NAMES[None]

        entry = player.desktop_entry
        if entry in MediaPlayerConfig.PLAYER_NAMES:
            return MediaPlayerConfig.PLAYER_NAMES[entry]

        return entry.replace("-", " ").title() if entry else MediaPlayerConfig.PLAYER_NAMES[None]


class MediaPlayerControls:
    @staticmethod
    def get_active_player() -> MprisPlayer | None:
        players = mpris.players
        return players[0] if players else None

    @staticmethod
    def previous():
        player = MediaPlayerControls.get_active_player()
        if player and player.can_go_previous:
            player.previous()

    @staticmethod
    def next():
        player = MediaPlayerControls.get_active_player()
        if player and player.can_go_next:
            player.next()

    @staticmethod
    def play_pause():
        player = MediaPlayerControls.get_active_player()
        if player:
            player.play_pause()

    @staticmethod
    def get_play_pause_icon(player: MprisPlayer | None) -> str:
        if not player:
            return "media-playback-stop-symbolic"

        status = player.playback_status
        return "media-playback-pause-symbolic" if status == "Playing" else "media-playback-start-symbolic"
