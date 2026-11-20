import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

Item {
    id: root

    visible: false

    property var targetScreen: null

    signal notificationCenterActionRequested(string action)
    signal audioActionRequested(string action)
    signal bluetoothActionRequested(string action)
    signal networkActionRequested(string action)
    signal weatherActionRequested(string action)

    PopupIpcHandler {
        target: "weather"
        handleAction: action => root.weatherActionRequested(action)
    }

    PopupIpcHandler {
        target: "bluetooth"
        handleAction: action => root.bluetoothActionRequested(action)
    }

    PopupIpcHandler {
        target: "audio"
        handleAction: action => root.audioActionRequested(action)
    }

    PopupIpcHandler {
        target: "network"
        handleAction: action => root.networkActionRequested(action)
    }

    PopupIpcHandler {
        target: "notificationCenter"
        handleAction: action => root.notificationCenterActionRequested(action)
    }
}
