import os
import sys
import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict

try:
    from rich.console import Console

    console = Console(stderr=True)
    HAS_RICH = True
except ImportError:
    HAS_RICH = False
    console = None


def log_error(msg: str):
    """Print error and exit"""
    if HAS_RICH:
        console.print(f"[bold red]✖ Error:[/bold red] {msg}")
    else:
        print(f"✖ Error: {msg}", file=sys.stderr)
    sys.exit(1)


def log_warning(msg: str):
    """Print warning"""
    if HAS_RICH:
        console.print(f"[bold yellow]⚠ Warning:[/bold yellow] {msg}")
    else:
        print(f"⚠ Warning: {msg}", file=sys.stderr)


def log_info(msg: str):
    """Print info message"""
    if HAS_RICH:
        console.print(f"[green]Yay![/green] {msg}")
    else:
        print(f"ℹ Info: {msg}", file=sys.stderr)


def expand_path(path_str: str) -> Path:
    """Expand ~ and environment variables"""
    return Path(os.path.expanduser(os.path.expandvars(path_str)))


# ───────────────────────────────────────────────────────────────
# PATHS
# ───────────────────────────────────────────────────────────────
@dataclass
class PathConfig:
    """File and directory paths"""

    cache_dir: Path = field(default_factory=lambda: Path.home() / ".cache" / "ignis")
    data_dir: Path = field(default_factory=lambda: Path.home() / ".local" / "share" / "ignis")
    config_dir: Path = field(default_factory=lambda: Path.home() / ".config" / "ignis")

    recordings_dir: Path = Path.home() / "Videos" / "Captures"
    screenshots_dir: Path = Path.home() / "Pictures" / "Screenshots"

    weather_cache: Path = field(init=False)

    def __post_init__(self):
        self.weather_cache = self.cache_dir / "weather_cache.json"

        for directory in [
            self.cache_dir,
            self.data_dir,
            self.config_dir,
            self.recordings_dir,
            self.screenshots_dir,
        ]:
            directory.mkdir(parents=True, exist_ok=True)

    @classmethod
    def from_dict(cls, data: Dict) -> "PathConfig":
        return cls(
            recordings_dir=expand_path(data.get("recordings_dir", "~/Videos/Captures")),
            screenshots_dir=expand_path(data.get("screenshots_dir", "~/Pictures/Screenshots")),
        )


# ───────────────────────────────────────────────────────────────
# WEATHER
# ───────────────────────────────────────────────────────────────
@dataclass
class WeatherConfig:
    api_key: str = ""
    city_id: str = ""
    cache_ttl: int = 600
    use_12h_format: bool = False
    icon_base_path: str = "~/.config/ignis/assets/icons/weather"

    def __post_init__(self):
        if not self.api_key:
            self.api_key = os.getenv("OPEN_WEATHER_APIKEY", "")

        if not self.city_id:
            self.city_id = os.getenv("OPEN_WEATHER_CITY_ID", "")

        if not self.city_id:
            log_warning(
                "No weather city_id configured. Weather will be disabled. Set it in config.toml or via OPEN_WEATHER_CITY_ID."
            )

        self.icon_base_path = os.path.expanduser(self.icon_base_path)

    @classmethod
    def from_dict(cls, data: Dict) -> "WeatherConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


# ───────────────────────────────────────────────────────────────
# UI · MONITORS
# ───────────────────────────────────────────────────────────────


@dataclass
class MonitorConfig:
    primary: int = 0
    bar: int = 0
    osd: int = 0
    notifications: int = 0
    recording_overlay: int = 0
    weather: int = 0
    power_overlay: int = 0
    system_menu: int = 0
    notification_center: int = 0

    def __post_init__(self):
        """Validate monitor IDs and fallback to 0 if invalid"""
        try:
            from ignis import utils

            monitors = utils.get_monitors()
            monitor_count = len(monitors)

            # Check each monitor assignment
            for field_name in self.__dataclass_fields__:
                monitor_id = getattr(self, field_name)

                if monitor_id >= monitor_count or monitor_id < 0:
                    log_warning(
                        f"Monitor ID {monitor_id} for '{field_name}' is invalid. "
                        f"Only {monitor_count} monitor(s) detected. Falling back to monitor 0."
                    )
                    setattr(self, field_name, 0)

        except Exception as e:
            log_warning(f"Could not validate monitor configuration: {e}. All windows will default to primary monitor.")

    @classmethod
    def from_dict(cls, data: Dict) -> "MonitorConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


# ───────────────────────────────────────────────────────────────
# UI · TIMEOUTS
# ───────────────────────────────────────────────────────────────
@dataclass
class TimeoutConfig:
    osd: int = 2000
    volume_osd: int = 2000
    media_osd: int = 5000
    time_osd: int = 8000
    workspace_osd: int = 1500

    @classmethod
    def from_dict(cls, data: Dict) -> "TimeoutConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


# ───────────────────────────────────────────────────────────────
# UI · BAR
# ───────────────────────────────────────────────────────────────
@dataclass
class BarConfig:
    remember_state: bool = True
    window_title_exceptions: list[str] | None = None

    def __post_init__(self):
        if self.window_title_exceptions is None:
            self.window_title_exceptions = ["firefox", "zen"]

    @classmethod
    def from_dict(cls, data: Dict) -> "BarConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


# ───────────────────────────────────────────────────────────────
# UI · NOTIFICATIONS
# ───────────────────────────────────────────────────────────────
@dataclass
class NotificationConfig:
    max_history: int = 10
    popup_timeout: int = 5000
    filter_keywords: list[str] | None = None

    def __post_init__(self):
        if self.filter_keywords is None:
            self.filter_keywords = []
        # Convert to lowercase for case-insensitive matching
        self.filter_keywords = [kw.lower() for kw in self.filter_keywords]

    def should_filter(self, notification) -> bool:
        """Check if notification should be filtered from history"""
        if not self.filter_keywords:
            return False

        summary = (notification.summary or "").lower()
        body = (notification.body or "").lower()

        for keyword in self.filter_keywords:
            if keyword in summary or keyword in body:
                return True

        return False

    @classmethod
    def from_dict(cls, data: Dict) -> "NotificationConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


# ───────────────────────────────────────────────────────────────
# UI ROOT
# ───────────────────────────────────────────────────────────────
@dataclass
class UIConfig:
    monitors: MonitorConfig = field(default_factory=MonitorConfig)
    timeouts: TimeoutConfig = field(default_factory=TimeoutConfig)
    bar: BarConfig = field(default_factory=BarConfig)
    notifications: NotificationConfig = field(default_factory=NotificationConfig)

    @property
    def primary_monitor(self):
        return self.monitors.primary

    @property
    def bar_monitor(self):
        return self.monitors.bar

    @property
    def osd_monitor(self):
        return self.monitors.osd

    @property
    def notifications_monitor(self):
        return self.monitors.notifications

    @property
    def recording_overlay_monitor(self):
        return self.monitors.recording_overlay

    @property
    def weather_monitor(self):
        return self.monitors.weather

    @property
    def power_overlay_monitor(self):
        return self.monitors.power_overlay

    @property
    def system_menu_monitor(self):
        return self.monitors.system_menu

    @property
    def notification_center_monitor(self):
        return self.monitors.notification_center

    @property
    def osd_timeout(self):
        return self.timeouts.osd

    @property
    def volume_osd_timeout(self):
        return self.timeouts.volume_osd

    @property
    def media_osd_timeout(self):
        return self.timeouts.media_osd

    @property
    def time_osd_timeout(self):
        return self.timeouts.time_osd

    @property
    def workspace_osd_timeout(self):
        return self.timeouts.workspace_osd

    @property
    def bar_remember_state(self):
        return self.bar.remember_state

    @property
    def bar_window_title_exceptions(self):
        return self.bar.window_title_exceptions

    @property
    def max_notifications(self):
        return self.notifications.max_history

    @property
    def notification_popup_timeout(self):
        return self.notifications.popup_timeout

    @classmethod
    def from_dict(cls, data: Dict) -> "UIConfig":
        return cls(
            monitors=MonitorConfig.from_dict(data.get("monitors", {})),
            timeouts=TimeoutConfig.from_dict(data.get("timeouts", {})),
            bar=BarConfig.from_dict(data.get("bar", {})),
            notifications=NotificationConfig.from_dict(data.get("notifications", {})),
        )


# ───────────────────────────────────────────────────────────────
# SYSTEM
# ───────────────────────────────────────────────────────────────
@dataclass
class SystemConfig:
    bluetooth_manager: str = "blueman-manager"

    @classmethod
    def from_dict(cls, data: Dict) -> "SystemConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


# ───────────────────────────────────────────────────────────────
# OTHER SECTIONS
# ───────────────────────────────────────────────────────────────
@dataclass
class RecorderConfig:
    audio_device: str = "default_output"
    video_format: str = "mp4"

    @classmethod
    def from_dict(cls, data: Dict) -> "RecorderConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


@dataclass
class BatteryConfig:
    critical_threshold: int = 15
    warning_threshold: int = 30

    def __post_init__(self):
        if self.critical_threshold >= self.warning_threshold:
            log_warning(
                f"Battery critical_threshold ({self.critical_threshold}) "
                f"should be less than warning_threshold ({self.warning_threshold})"
            )

    @classmethod
    def from_dict(cls, data: Dict) -> "BatteryConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


@dataclass
class AnimationConfig:
    revealer_duration: int = 180

    @classmethod
    def from_dict(cls, data: Dict) -> "AnimationConfig":
        return cls(**{k: v for k, v in data.items() if k in cls.__annotations__})


# ───────────────────────────────────────────────────────────────
# ROOT CONFIG
# ───────────────────────────────────────────────────────────────
@dataclass
class AppConfig:
    paths: PathConfig = field(default_factory=PathConfig)
    weather: WeatherConfig = field(default_factory=WeatherConfig)
    ui: UIConfig = field(default_factory=UIConfig)
    system: SystemConfig = field(default_factory=SystemConfig)
    recorder: RecorderConfig = field(default_factory=RecorderConfig)
    battery: BatteryConfig = field(default_factory=BatteryConfig)
    animations: AnimationConfig = field(default_factory=AnimationConfig)

    @classmethod
    def from_file(cls, config_file: Path | None = None) -> "AppConfig":
        toml_config_file = Path.home() / ".config" / "ignis" / "config.toml"
        json_config_file = Path.home() / ".config" / "ignis" / "config.json"

        if config_file is not None:
            toml_config_file = config_file
            json_config_file = config_file.with_suffix(".json")

        data = None

        if toml_config_file.exists():
            try:
                with open(toml_config_file, "rb") as f:
                    data = tomllib.load(f)
                log_info(f"Loaded config from {toml_config_file}")
            except Exception as e:
                log_warning(f"Failed to parse TOML config {toml_config_file}: {e}. Trying JSON fallback.")

        if data is None and json_config_file.exists():
            try:
                import json

                with open(json_config_file) as f:
                    data = json.load(f)
                log_warning(f"Loaded config from JSON fallback {json_config_file}. Consider migrating to TOML.")
            except Exception as e:
                log_error(f"Failed to parse JSON config {json_config_file}: {e}")

        if data is None:
            log_error(f"No valid config file found at {toml_config_file} or {json_config_file}")

        return cls(
            paths=PathConfig.from_dict(data.get("paths", {})),
            weather=WeatherConfig.from_dict(data.get("weather", {})),
            ui=UIConfig.from_dict(data.get("ui", {})),
            system=SystemConfig.from_dict(data.get("system", {})),
            recorder=RecorderConfig.from_dict(data.get("recorder", {})),
            battery=BatteryConfig.from_dict(data.get("battery", {})),
            animations=AnimationConfig.from_dict(data.get("animations", {})),
        )


# ───────────────────────────────────────────────────────────────
# GLOBAL INSTANCE
# ───────────────────────────────────────────────────────────────
config = AppConfig.from_file()
