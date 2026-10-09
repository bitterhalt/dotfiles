//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import "components"
import "services"
import "recorder"
import "osd"
import "bar"
import "menu"
import "modules/bluetooth"
import "modules/notifications"

ShellRoot {
  id: root

  property bool barVisible: true
  readonly property var activeScreen: {
    const screens = Quickshell.screens

    if (!screens || screens.length === 0)
      return null

    for (let i = 0; i < screens.length; ++i) {
      if (screens[i].name === niriService.focusedOutput)
        return screens[i]
    }

    return screens[0]
  }

  ThemeService {
    id: themeService
  }

  Config {
    id: appConfig
    theme: themeService
  }

  NiriService {
    id: niriService

  }

  ThemeMenu {
    id: themeMenu
    config: appConfig
    targetScreen: root.activeScreen
  }

  Menu {
    id: mainMenu
    config: appConfig
    themeMenu: themeMenu
    targetScreen: root.activeScreen
  }

  NotificationService {
    id: appNotificationService
  }

  NotificationPopup {
    id: appNotificationPopup
    config: appConfig
    targetScreen: root.activeScreen
    notificationService: appNotificationService
  }

  Connections {
    target: appNotificationService

    function onToastSerialChanged(): void {
      if (!appNotificationService.dnd
          && appNotificationService.toastNotification) {
        appNotificationPopup.show(
          appNotificationService.toastNotification
        )
      }
    }

    function onDndChanged(): void {
      if (appNotificationService.dnd)
        appNotificationPopup.hide()
    }
  }

  BluetoothService {
    id: appBluetoothService
  }

  BluetoothNotifier {
    config: appConfig
    targetScreen: root.activeScreen
    devices: appBluetoothService.devices
  }

  WeatherService {
    id: appWeatherService
  }

  BatteryService {
    id: appBatteryService
  }

  IdleService {
    id: appIdleService
    config: appConfig
    targetScreen: root.activeScreen
  }

  RecorderService {
    id: appRecorderService
    targetScreen: root.activeScreen
  }

  ShellUiService {
    id: shellUiService
    targetScreen: root.activeScreen
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  VolumeOsd {
    id: appVolumeOsd
    config: appConfig
    targetScreen: root.activeScreen
  }

  // Niri/keybind control:
  //
  //   qs ipc call bar toggle
  //   qs ipc call bar hide
  //   qs ipc call bar show
  IpcHandler {
    target: "bar"

    function toggle(): void {
      root.barVisible = !root.barVisible
    }

    function hide(): void {
      root.barVisible = false
    }

    function show(): void {
      root.barVisible = true
    }

    function isVisible(): bool {
      return root.barVisible
    }
  }

  Variants {
    model: Quickshell.screens

    Bar {
      required property var modelData

      targetScreen: modelData
      config: appConfig
      niri: niriService
      volumeOsd: appVolumeOsd
      notificationService: appNotificationService
      notificationPopup: appNotificationPopup
      bluetoothService: appBluetoothService
      weatherService: appWeatherService
      batteryService: appBatteryService
      idleService: appIdleService
      recorderService: appRecorderService
      uiService: shellUiService

      visible: root.barVisible
    }
  }
}
