pragma ComponentBehavior: Bound

import QtQuick
import "../../../components"

Item {
    id: root

    required property var config
    required property var barWindow
    required property var niri
    required property var settingsService

    readonly property bool minimalLayout: settingsService.workspaceLayout === "minimal"
    readonly property var outputWorkspaces: niri.workspaces.filter(workspace => workspace.output === barWindow.screen.name).sort((a, b) => a.idx - b.idx)
    readonly property var activeWorkspace: outputWorkspaces.find(workspace => workspace.is_active) ?? null
    readonly property var otherWorkspaces: outputWorkspaces.filter(workspace => !workspace.is_active)
    property bool layoutAnimationRequested: false

    implicitWidth: minimalLayout ? workspaceRevealer.implicitWidth : dotsRow.implicitWidth
    width: implicitWidth
    height: barWindow.height

    // Right-click the workspace module to switch its persisted layout.
    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: root.settingsService.settingsLoaded
        onTapped: {
            root.layoutAnimationRequested = true;
            root.settingsService.saveWorkspaceLayout(root.minimalLayout ? "dots" : "minimal");
        }
    }

    function focusWorkspace(workspace): void {
        if (workspace)
            config.run(`niri msg action focus-workspace ${workspace.idx}`);
    }

    // Dots layout: active, urgent, and inactive workspaces for this output.
    Row {
        id: dotsRow
        objectName: "dotsRow"

        anchors.centerIn: parent
        spacing: 8
        visible: opacity > 0
        enabled: !root.minimalLayout
        opacity: root.minimalLayout ? 0 : 1
        scale: root.minimalLayout ? 0.88 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
            enabled: root.layoutAnimationRequested
        }
        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
            enabled: root.layoutAnimationRequested
        }

        Repeater {
            model: root.outputWorkspaces

            delegate: Rectangle {
                id: workspaceDot
                objectName: "workspace-dot-" + modelData.idx
                required property var modelData

                width: modelData.is_active ? 24 : 8
                height: 8
                radius: 4
                color: workspaceDot.modelData.is_urgent ? root.config.urgent : workspaceDot.modelData.is_active ? root.config.selectionBackground : root.config.fg
                opacity: workspaceDot.modelData.is_active ? 1 : 0.7

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.focusWorkspace(workspaceDot.modelData)
                }
            }
        }
    }

    // Minimal layout: active workspace chip, with other workspaces revealed on hover.
    ItemRevealer {
        id: workspaceRevealer
        objectName: "workspaceRevealer"

        config: root.config
        barWindow: root.barWindow
        visible: opacity > 0
        enabled: root.minimalLayout
        opacity: root.minimalLayout ? 1 : 0
        scale: root.minimalLayout ? 1 : 0.88

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
            enabled: root.layoutAnimationRequested
        }
        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
            enabled: root.layoutAnimationRequested
        }

        Rectangle {
            objectName: "activeWorkspaceChip"
            width: activeName.implicitWidth + 16
            height: 26
            radius: 4
            color: root.config.selectionBackground

            Text {
                id: activeName
                objectName: "activeWorkspaceName"
                renderType: Text.NativeRendering

                anchors.centerIn: parent
                color: root.config.selectionForeground
                font.pointSize: root.config.textSizeNormal
                font.weight: Font.DemiBold
                text: root.activeWorkspace ? (root.activeWorkspace.name || String(root.activeWorkspace.idx)) : "—"
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.activeWorkspace !== null
                cursorShape: Qt.PointingHandCursor
                onClicked: root.focusWorkspace(root.activeWorkspace)
            }
        }

        revealData: [
            Repeater {
                model: root.otherWorkspaces

                delegate: Rectangle {
                    id: workspaceItem
                    required property var modelData

                    width: workspaceName.implicitWidth + 16
                    height: 24
                    radius: 4
                    color: workspaceMouse.containsMouse ? root.config.selectionBackground : Qt.alpha(workspaceItem.modelData.is_urgent ? root.config.urgent : root.config.selectionBackground, 0.6)

                    Text {
                        id: workspaceName
                        objectName: "workspace-name-" + workspaceItem.modelData.idx
                        renderType: Text.NativeRendering

                        anchors.centerIn: parent
                        color: workspaceMouse.containsMouse ? root.config.selectionForeground : workspaceItem.modelData.is_urgent ? root.config.bg : root.config.selectionForeground
                        font.pointSize: root.config.textSizeNormal
                        font.weight: Font.DemiBold
                        text: workspaceItem.modelData.name || String(workspaceItem.modelData.idx)
                    }

                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.focusWorkspace(workspaceItem.modelData)
                    }
                }
            }
        ]
    }
}
