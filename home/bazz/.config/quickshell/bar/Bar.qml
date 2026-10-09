import "../components"
import "modules/audio"
import "modules/battery"
import "modules/bluetooth"
import "modules/clock"
import "modules/idle"
import "modules/network"
import "../notifications"
import "modules/tray"
import "modules/window"
import "modules/workspaces"
import "../recorder"
import QtQuick
import Quickshell

PanelWindow {
    id: barWindow

    required property var targetScreen
    required property var config
    required property var niri
    required property var volumeOsd
    required property var notificationService
    required property var notificationPopup
    required property var bluetoothService
    required property var weatherService
    required property var batteryService
    required property var idleService
    required property var recorderService
    required property var uiService

    screen: targetScreen
    implicitHeight: config.barHeight
    color: config.bg

    anchors {
        top: true
        left: true
        right: true
    }

    PopupManager {
        id: popupManager

        barWindow: barWindow
        config: barWindow.config
    }

    // ---------------------------------------------------------
    // LEFT
    // Change module order here.
    // ---------------------------------------------------------
    Row {
        anchors.left: parent.left
        anchors.leftMargin: config.barEdgeMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.barModuleSpacing

        Workspaces {
            config: barWindow.config
            barWindow: barWindow
            niri: barWindow.niri
        }

        WindowTitle {
            config: barWindow.config
            barWindow: barWindow
            niri: barWindow.niri
        }

    }

    // ---------------------------------------------------------
    // CENTER
    // Change module order here.
    // ---------------------------------------------------------
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.barModuleSpacing

        Clock {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            weatherData: barWindow.weatherService
            uiService: barWindow.uiService
        }

        NotificationIndicator {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            notificationService: barWindow.notificationService
            notificationPopup: barWindow.notificationPopup
            uiService: barWindow.uiService
        }

        Recorder {
            config: barWindow.config
            barWindow: barWindow
            recorderService: barWindow.recorderService
        }

    }

    // ---------------------------------------------------------
    // RIGHT
    // Change module order here.
    // ---------------------------------------------------------
    Row {
        anchors.right: parent.right
        anchors.rightMargin: config.barEdgeMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.barModuleSpacing

        Network {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
        }

        Bluetooth {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            bluetoothService: barWindow.bluetoothService
        }

        Audio {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            volumeOsd: barWindow.volumeOsd
        }

        Idle {
            config: barWindow.config
            barWindow: barWindow
            idleService: barWindow.idleService
        }

        Battery {
            config: barWindow.config
            barWindow: barWindow
            battery: barWindow.batteryService
        }

        Tray {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            uiService: barWindow.uiService
        }

    }

}
