import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    visible: false

    // UPower's display device aggregates system batteries, not peripherals.
    readonly property var device: UPower.displayDevice
    readonly property bool present: !!device && device.ready && device.isLaptopBattery && device.isPresent
    readonly property int capacity: present && Number.isFinite(device.percentage) ? Math.max(0, Math.min(100, Math.round(device.percentage))) : 0
    readonly property string status: {
        if (!present)
            return "";

        switch (device.state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        case UPowerDeviceState.Empty:
            return "Empty";
        case UPowerDeviceState.FullyCharged:
            return "Full";
        case UPowerDeviceState.PendingCharge:
            return "Not charging";
        case UPowerDeviceState.PendingDischarge:
            return "Pending discharge";
        default:
            return "Unknown";
        }
    }

    readonly property string icon: {
        if (status === "Charging")
            return "󰂄";

        const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        const index = Math.max(0, Math.min(10, Math.round(capacity / 10)));
        return icons[index];
    }
}
