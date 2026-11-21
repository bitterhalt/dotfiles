import QtQuick
import Quickshell
import Quickshell.Io

// State for the built-in wallpaper engine (replaces awww).
// The windows are drawn by wallpaper/WallpaperLayer.qml; call reload() after
// ~/.local/share/wall/{wallpaper,lockscreen}.png change. External scripts can use:
//   qs ipc call bg reload
Item {
    id: root
    visible: false

    readonly property string dir: "file://" + Quickshell.env("HOME") + "/.local/share/wall/"
    property int rev: 0

    function reload() {
        rev++;
    }

    IpcHandler {
        target: "bg"
        function reload() {
            root.reload();
        }
    }
}
