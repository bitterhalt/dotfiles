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
                widgets.Label(label="CPU:", css_classes=["cpu-info-label"]),
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
                widgets.Label(label="RAM:", css_classes=["ram-info-label"]),
                self._ram_bar,
                self._ram_label,
            ],
        )

        super().__init__(
            vertical=True,
            spacing=14,
            css_classes=["system-info-pill"],
            child=[cpu_box, ram_box],
        )

        self._last_cpu_total = None
        self._last_cpu_idle = None
        self._poll_cpu = None
        self._poll_ram = None

        self._update_cpu()
        self._update_ram()

        self._poll_cpu = utils.Poll(3000, self._update_cpu)
        self._poll_ram = utils.Poll(3000, self._update_ram)

        self.connect("destroy", self._cleanup)

    def _cleanup(self, *_):
        for p in (self._poll_cpu, self._poll_ram):
            if p:
                try:
                    p.cancel()
                except Exception:
                    pass
        self._poll_cpu = self._poll_ram = None

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
