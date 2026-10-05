import "../components"
import "../modules/audio"
import "../modules/battery"
import "../modules/bluetooth"
import "../modules/clock"
import "../modules/idle"
import "../modules/network"
import "../modules/notifications"
import "../modules/recorder"
import "../modules/tray"
import "../modules/window"
import "../modules/workspaces"
import QtQuick
import Quickshell

PanelWindow {
    id: barWindow

    required property var targetScreen
    required property var config
    required property var niri
    required property var volumeOsd
    required property var notificationService

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
        }

        Notifications {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
            notificationService: barWindow.notificationService
        }

        Recorder {
            config: barWindow.config
            barWindow: barWindow
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
        }

        Battery {
            config: barWindow.config
            barWindow: barWindow
        }

        Tray {
            config: barWindow.config
            barWindow: barWindow
            popupManager: popupManager
        }

    }

}
