from .battery import BatteryWidget
from .clock import ClockWidget
from .focused_window import WindowTitleWidget
from .idle_indicator import IdleIndicatorWidget
from .network_items import EthernetItem, VpnNetworkItem, WifiNetworkItem
from .recorder_indicator import RecordingIndicator
from .system_indicator import SystemIndicatorWidget
from .system_popup import SystemPopup
from .system_tray import SystemTrayWidget
from .workspaces import WorkspaceWidget

__all__ = [
    "BatteryWidget",
    "ClockWidget",
    "EthernetItem",
    "IdleIndicatorWidget",
    "RecordingIndicator",
    "SystemIndicatorWidget",
    "SystemPopup",
    "SystemTrayWidget",
    "VpnNetworkItem",
    "WifiNetworkItem",
    "WindowTitleWidget",
    "WorkspaceWidget",
]
