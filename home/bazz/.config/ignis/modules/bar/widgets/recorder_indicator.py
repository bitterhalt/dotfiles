import asyncio
from ignis import widgets
from ignis.services.recorder import RecorderService
from modules.utils.signal_manager import SignalManager

recorder = RecorderService.get_default()


class RecordingIndicator(widgets.EventBox):
    def __init__(self):
        self._signals = SignalManager()

        self._icon = widgets.Label(
            label="",
            css_classes=["recording-icon"],
        )

        super().__init__(
            css_classes=["recording-box"],
            visible=False,
            child=[self._icon],
            on_click=lambda x: asyncio.create_task(recorder.stop_recording()),
        )

        self._setup_signals()
        self._update_state()
        self.connect("destroy", lambda *_: self._cleanup())

    def _setup_signals(self):
        self._signals.connect(recorder, "recording_started", self._on_start)
        self._signals.connect(recorder, "recording_stopped", self._on_stop)

    def _on_start(self, *_):
        self._icon.set_label("󰻂")
        self._icon.set_tooltip_text("Recording.. .\n\nClick to stop")
        self.set_visible(True)

    def _on_stop(self, *_):
        self._icon.set_label("")
        self._icon.set_tooltip_text("")
        self.set_visible(False)

    def _update_state(self):
        if recorder.active:
            self._on_start()
        else:
            self._on_stop()

    def _cleanup(self):
        self._signals.disconnect_all()
