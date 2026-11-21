pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../services"

// One wallpaper window per screen, plus the blurred "overview" window that
// niri places in its backdrop (see the layer-rule in niri/rules.kdl).
Scope {
    id: root

    required property WallpaperService service

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property var modelData

            WallpaperSurface {
                screen: perScreen.modelData
                namespace: "slim-wallpaper"
                url: root.service.dir + "wallpaper.png"
                rev: root.service.rev
                fadeMs: 600
            }

            WallpaperSurface {
                screen: perScreen.modelData
                namespace: "overview"
                url: root.service.dir + "lockscreen.png"
                rev: root.service.rev
                fadeMs: 0
            }
        }
    }
}
