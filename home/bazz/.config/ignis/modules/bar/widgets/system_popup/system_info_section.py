from ignis import utils, widgets
from ignis.services.fetch import FetchService

fetch = FetchService.get_default()


class SystemInfoWidget(widgets.Box):
    def __init__(self):
        self._cpu_bar = widgets.Scale(
            min=0,
            max=100,
            value=0,
            sensitive=False,
            hexpand=True,
            css_classes=["system-info-bar", "cpu-bar", "unset"],
        )

        self._cpu_label = widgets.Label(label="0%", css_classes=["system-info-percent"])
        cpu_box = widgets.Box(
            spacing=16,
            child=[
                widgets.Icon(image="cpu-symbolic", pixel_size=22),
                self._cpu_bar,
                self._cpu_label,
            ],
        )

        self._ram_bar = widgets.Scale(
            min=0,
            max=100,
            value=0,
            sensitive=False,
            hexpand=True,
            css_classes=["system-info-bar", "ram-bar", "unset"],
        )

        self._ram_label = widgets.Label(label="0%", css_classes=["system-info-percent"])

        ram_box = widgets.Box(
            spacing=16,
            child=[
                widgets.Icon(image="memory-symbolic", pixel_size=22),
                self._ram_bar,
                self._ram_label,
            ],
        )

        self._arrow = widgets.Icon(
            image="pan-down-symbolic",
            pixel_size=16,
            css_classes=["expand-arrow"],
        )

        expand_btn = widgets.Button(
            css_classes=["sys-info-expand-btn", "unset"],
            child=self._arrow,
            on_click=lambda *_: self._toggle_details(),
        )

        main_section = widgets.Box(
            vertical=True,
            spacing=10,
            child=[cpu_box, ram_box, expand_btn],
        )

        self._os_label = widgets.Label(label="Loading…", halign="start", css_classes=["system-info-text"])
        self._cpu_model_label = widgets.Label(label="Loading…", halign="start", css_classes=["system-info-text"])
        self._mem_total_label = widgets.Label(label="Loading…", halign="start", css_classes=["system-info-text"])
        self._uptime_label = widgets.Label(label="Loading…", halign="start", css_classes=["system-info-text"])

        self._details_box = widgets.Box(
            vertical=True,
            spacing=4,
            css_classes=["system-info-details"],
            visible=False,
            child=[
                self._os_label,
                self._cpu_model_label,
                self._mem_total_label,
                self._uptime_label,
            ],
        )

        super().__init__(
            vertical=True,
            spacing=10,
            css_classes=["system-info-widget"],
            child=[main_section, self._details_box],
        )

        self._last_cpu_total = None
        self._last_cpu_idle = None
        self._poll_cpu = None
        self._poll_ram = None
        self._poll_info = None

        self._update_cpu()
        self._update_ram()
        self._update_info()

        self._poll_cpu = utils.Poll(3000, self._update_cpu)
        self._poll_ram = utils.Poll(3000, self._update_ram)
        self._poll_info = utils.Poll(60000, self._update_info)

        self.connect("destroy", self._cleanup)

    def _toggle_details(self):
        """Toggle visibility of detailed system info"""
        new_state = not self._details_box.visible
        self._details_box.visible = new_state
        self._arrow.set_css_classes(["expand-arrow", "rotated"] if new_state else ["expand-arrow"])

    def _cleanup(self, *_):
        for p in (self._poll_cpu, self._poll_ram, self._poll_info):
            if p:
                try:
                    p.cancel()
                except Exception:
                    pass
        self._poll_cpu = self._poll_ram = self._poll_info = None

    def _read_cpu_stat(self):
        try:
            with open("/proc/stat", "r") as f:
                parts = f.readline().split()
        except Exception:
            return None, None

        values = list(map(int, parts[1:]))
        idle = values[3] + values[4]
        total = sum(values)
        return total, idle

    def _update_cpu(self, *_):
        total, idle = self._read_cpu_stat()
        if total is None:
            self._cpu_bar.value = 0
            self._cpu_label.label = "–%"
            return True

        if self._last_cpu_total is None:
            self._last_cpu_total = total
            self._last_cpu_idle = idle
            return True

        total_delta = total - self._last_cpu_total
        idle_delta = idle - self._last_cpu_idle

        self._last_cpu_total = total
        self._last_cpu_idle = idle

        usage = 0 if total_delta <= 0 else 100 * (1 - idle_delta / total_delta)
        usage = max(0, min(usage, 100))

        self._cpu_bar.value = usage
        self._cpu_label.label = f"{int(usage)}%"
        return True

    def _update_ram(self, *_):
        total = fetch.mem_total or 0
        available = fetch.mem_available or 0

        percent = ((total - available) / total) * 100 if total > 0 else 0
        self._ram_bar.value = percent
        self._ram_label.label = f"{int(percent)}%"
        return True

    def _update_info(self, *_):
        self._os_label.label = f"SYS: {fetch.os_name or 'Unknown'}"
        cpu = fetch.cpu or "Unknown"
        if len(cpu) > 40:
            cpu = cpu[:37] + "..."
        self._cpu_model_label.label = f"CPU: {cpu}"

        mem_total = fetch.mem_total or 0
        if mem_total > 0:
            mem_gb = mem_total / (1024 * 1024)  # Convert KB to GB
            self._mem_total_label.label = f"RAM: {mem_gb:.1f} GB"
        else:
            self._mem_total_label.label = "Memory: Unknown"

        uptime = fetch.uptime
        if uptime:
            self._uptime_label.label = "UP: " + self._format_uptime(*uptime)
        else:
            self._uptime_label.label = "Uptime: Unknown"
        return True

    def _format_uptime(self, days: int, hours: int, minutes: int, _seconds: int) -> str:
        if days > 0:
            return f"{days}d {hours}h {minutes}m"
        if hours > 0:
            return f"{hours}h {minutes}m"
        return f"{minutes}m"
