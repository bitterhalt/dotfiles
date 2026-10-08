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

ShellRoot {
  id: root

  property bool barVisible: true

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
  }

  Menu {
    id: mainMenu
    config: appConfig
    themeMenu: themeMenu
  }

  NotificationService {
    id: appNotificationService
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  VolumeOsd {
    id: appVolumeOsd
    config: appConfig
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

      visible: root.barVisible
    }
  }
}
