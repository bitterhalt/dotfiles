import "../components"
import "../notifications"
import "../recorder"
import QtQuick
import Quickshell
import Quickshell.Wayland
import "modules/audio"
import "modules/battery"
import "modules/bluetooth"
import "modules/clock"
import "modules/drives"
import "modules/idle"
import "modules/network"
import "modules/privacy"
import "modules/tray"
import "modules/window"
import "modules/workspaces"

PanelWindow {
    id: barWindow

    required property var targetScreen
    required property var config
    required property var niri
    required property var resumeService
    required property var notificationService
    required property var notificationPopup
    required property var bluetoothService
    required property var audioService
    required property var networkService
    required property var driveService
    required property var privacyService
    required property var batteryService
    required property var weatherService
    required property var idleService
    required property var settingsService
    required property var recorderService
    required property var uiService

    screen: targetScreen
    implicitHeight: config.barHeight
    color: config.bg
    WlrLayershell.namespace: "slim-bar"

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

    // Recorder UI is controlled through its existing IPC; Privacy shows activity.
    Recorder {
        config: barWindow.config
        barWindow: barWindow
        recorderService: barWindow.recorderService
    }

    // ---------------------------------------------------------
    // LEFT
    // Change module order here.
    // ---------------------------------------------------------
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Workspaces {
            config: barWindow.config
            barWindow: barWindow
            niri: barWindow.niri
            settingsService: barWindow.settingsService
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
        spacing: 8

        Clock {
            config: barWindow.config
            barWindow: barWindow
            resumeService: barWindow.resumeService
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
    }

    // ---------------------------------------------------------
    // RIGHT
    // Change module order here.
    // ---------------------------------------------------------
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Privacy {
            config: barWindow.config
            barWindow: barWindow
            privacyService: barWindow.privacyService
            recorderService: barWindow.recorderService
        }

        Drives {
            config: barWindow.config
            barWindow: barWindow
            driveService: barWindow.driveService
        }

        Network {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            uiService: barWindow.uiService
            networkService: barWindow.networkService
        }

        Bluetooth {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            bluetoothService: barWindow.bluetoothService
            uiService: barWindow.uiService
        }

        Audio {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            uiService: barWindow.uiService
            audioService: barWindow.audioService
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
            visible: barWindow.config.showTray && hasItems
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
        }
    }
}
