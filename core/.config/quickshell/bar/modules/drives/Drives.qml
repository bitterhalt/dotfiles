import QtQuick
import "../../../components"
import "../../../services/drives/DriveModel.js" as DriveModel

// Removable volumes on the bar: one chip per volume, lit while mounted and
// muted while not. Click mounts or opens; right-click unmounts. Locked LUKS
// volumes stay inert until unlocked outside the bar.
Item {
    id: root

    required property var config
    required property var barWindow
    required property var driveService

    readonly property var volumes: driveService.volumes
    readonly property bool compact: driveService.compact

    visible: volumes.length > 0
    implicitWidth: visible ? chipRow.implicitWidth : 0
    width: implicitWidth
    height: barWindow.height

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: root.config.spacingTight

        // Many volumes collapse to one counted chip; clicking expands again.
        Item {
            id: compactChip
            objectName: "driveCompactChip"
            visible: root.compact
            width: Math.max(24, compactContent.implicitWidth + 4)
            height: root.barWindow.height

            Row {
                id: compactContent
                anchors.centerIn: parent
                spacing: 1

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.muted
                    font.family: root.config.iconFontFamily
                    font.pointSize: root.config.iconSize * 0.88
                    text: "󱊞"
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.config.muted
                    font.family: root.config.textFontFamily
                    font.pointSize: root.config.textSizeSmall
                    text: root.volumes.length
                }
            }

            MouseArea {
                id: compactMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.driveService.compact = false
            }

            ShellToolTip {
                objectName: "driveCompactTooltip"
                config: root.config
                anchorItem: compactChip
                shown: compactMouse.containsMouse && root.visible
                text: DriveModel.compactTooltip(root.volumes)
            }
        }

        Repeater {
            model: root.compact ? [] : root.volumes

            Item {
                id: chip

                required property var modelData

                readonly property var volume: modelData
                readonly property bool busy: root.driveService.busyPath === chip.volume.path
                // Unmounted chips dim like muted text.
                readonly property real chipOpacity: chip.volume.mounted ? 1 : 0.65

                objectName: "driveChip/" + chip.volume.path
                width: Math.max(24, chipContent.implicitWidth + 8)
                height: root.barWindow.height

                Row {
                    id: chipContent
                    anchors.centerIn: parent
                    spacing: root.config.spacingTight

                    Text {
                        objectName: "driveGlyph/" + chip.volume.path
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.config.fg
                        opacity: chip.chipOpacity
                        font.family: root.config.iconFontFamily
                        font.pointSize: root.config.iconSize
                        text: chip.volume.locked ? "󰌾" : (chip.volume.loop ? "󰗮" : "󰕓")
                    }

                    Text {
                        objectName: "driveLabel/" + chip.volume.path
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.config.fg
                        opacity: chip.chipOpacity
                        font.family: root.config.textFontFamily
                        font.pointSize: root.config.textSizeNormal
                        renderType: Text.NativeRendering
                        text: chip.volume.label
                    }

                    Text {
                        objectName: "driveSize/" + chip.volume.path
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.config.fg
                        opacity: chip.chipOpacity
                        font.family: root.config.textFontFamily
                        font.pointSize: root.config.textSizeMedium
                        renderType: Text.NativeRendering
                        text: chip.volume.size
                        visible: text !== ""
                    }
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: chip.volume.locked || chip.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (chip.volume.locked || chip.busy)
                            return;
                        if (mouse.button === Qt.RightButton) {
                            if (chip.volume.mounted)
                                root.driveService.unmount(chip.volume.path);
                            return;
                        }
                        root.driveService.activate(chip.volume);
                    }
                }

                ShellToolTip {
                    objectName: "driveTooltip/" + chip.volume.path
                    config: root.config
                    anchorItem: chip
                    shown: chipMouse.containsMouse && root.visible
                    text: DriveModel.tooltip(chip.volume, root.driveService.errorText || root.driveService.inventoryError)
                }
            }
        }
    }
}
