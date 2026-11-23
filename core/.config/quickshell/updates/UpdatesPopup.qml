pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import "../components"
import "UpdateModel.js" as UpdateModel

// Bounded, scrollable update report. The controller owns checking and upgrades.
PanelWindow {
    id: root

    required property var config
    required property var targetScreen
    required property var controller
    required property var popupMotion

    readonly property var rows: UpdateModel.rows(controller.report)
    readonly property int total: UpdateModel.total(controller.report)
    readonly property int rowSpacing: 2
    readonly property int maxHeight: UpdateModel.popupMaxHeight(targetScreen ? targetScreen.height : 0, config.popupGap)
    readonly property int maxListHeight: UpdateModel.listMaxHeight(maxHeight, config, header.height, footer.height)
    readonly property int viewportHeight: UpdateModel.listViewportHeight(rows, config, maxListHeight, rowSpacing)
    readonly property bool hasError: controller.errorText !== ""
    readonly property int pageStep: UpdateModel.pageStep(list.height, UpdateModel.rowHeight(config, "package"))
    readonly property string statusLabel: {
        const status = root.statusText();
        if (!status)
            return "";
        return list.contentHeight > list.height + 0.5 ? status + " · scroll" : status;
    }

    signal closeRequested

    function statusText(): string {
        if (hasError)
            return controller.errorText;
        if (controller.busy)
            return "Checking…";
        if (!controller.report || !controller.report.checked)
            return "";
        return "Checked " + Qt.formatTime(new Date(controller.report.checked * 1000), "HH:mm");
    }

    function scrollTo(offset): void {
        list.contentY = UpdateModel.clampScroll(offset, list.contentHeight, list.height);
    }

    function scrollBy(delta): void {
        root.scrollTo(list.contentY + delta);
    }

    visible: popupMotion.surfaceVisible
    screen: targetScreen
    anchors.top: true
    anchors.left: true
    implicitWidth: targetScreen ? Math.min(420, targetScreen.width - config.popupGap * 2) : 420
    implicitHeight: config.panelPadding * 2 + header.height + viewportHeight + footer.height + config.spacingControl * 2
    color: "transparent"
    exclusiveZone: 0
    focusable: controller.opened
    margins.top: config.popupGap
    margins.left: screen ? Math.max(0, Math.round((screen.width - width) / 2)) : 0

    Binding {
        target: popupMotion
        property: "surfaceHeight"
        value: root.height
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "slim-updates"
    WlrLayershell.keyboardFocus: root.controller.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Dismiss on a click outside the surface, like the other standalone popups.
    PopupCatcher {
        targetScreen: root.targetScreen
        visible: root.visible
        onDismissed: root.closeRequested()
    }

    FocusScope {
        id: keyboardHandler

        anchors.fill: parent
        enabled: root.controller.opened
        focus: true
        opacity: root.popupMotion.contentOpacity
        transform: Translate {
            y: root.popupMotion.contentOffset
        }

        // The background shares the content's opacity and slide so the whole
        // card moves as one unit, like the other standalone popups.
        PanelSurface {
            anchors.fill: parent
            config: root.config
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                root.closeRequested();
                event.accepted = true;
                break;
            case Qt.Key_Up:
                root.scrollBy(-root.config.textSizeMedium * 3);
                event.accepted = true;
                break;
            case Qt.Key_Down:
                root.scrollBy(root.config.textSizeMedium * 3);
                event.accepted = true;
                break;
            case Qt.Key_PageUp:
                root.scrollBy(-root.pageStep);
                event.accepted = true;
                break;
            case Qt.Key_PageDown:
                root.scrollBy(root.pageStep);
                event.accepted = true;
                break;
            case Qt.Key_Home:
                root.scrollTo(0);
                event.accepted = true;
                break;
            case Qt.Key_End:
                root.scrollTo(list.contentHeight);
                event.accepted = true;
                break;
            }

            if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
                return;
            const key = event.text.toLowerCase();
            if (key === "r" && refreshButton.enabled) {
                root.controller.refresh();
                event.accepted = true;
            } else if (key === "u" && upgradeButton.enabled) {
                root.controller.upgrade();
                event.accepted = true;
            }
        }
        Component.onCompleted: Qt.callLater(() => keyboardHandler.forceActiveFocus())

        Item {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.config.panelPadding
            height: headerLabel.implicitHeight

            Text {
                id: headerLabel

                anchors.fill: parent
                color: root.config.fg
                elide: Text.ElideRight
                font.pointSize: root.config.textSizeNormal
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
                text: UpdateModel.headerLabel(root.controller.report, root.controller.busy)
                verticalAlignment: Text.AlignVCenter
            }
        }

        ListView {
            id: list

            objectName: "updatesList"
            anchors.top: header.bottom
            anchors.topMargin: root.config.spacingControl
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.config.panelPadding
            anchors.rightMargin: root.config.panelPadding
            anchors.bottom: footer.top
            anchors.bottomMargin: root.config.spacingControl
            clip: true
            spacing: root.rowSpacing
            boundsBehavior: Flickable.StopAtBounds
            model: root.rows

            delegate: Item {
                id: row

                required property var modelData

                width: list.width
                height: UpdateModel.rowHeight(root.config, modelData.kind)

                Item {
                    anchors.fill: parent
                    visible: row.modelData.kind === "package"

                    Text {
                        id: packageName

                        anchors.left: parent.left
                        anchors.leftMargin: root.config.spacingControl
                        anchors.right: versions.left
                        anchors.rightMargin: root.config.spacingControl
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.config.fg
                        elide: Text.ElideRight
                        font.pointSize: root.config.textSizeMedium
                        renderType: Text.NativeRendering
                        text: row.modelData.name ?? ""
                    }

                    Row {
                        id: versions

                        anchors.right: parent.right
                        anchors.rightMargin: root.config.spacingControl
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.config.spacingTight

                        Text {
                            color: root.config.muted
                            font.pointSize: root.config.textSizeSmall
                            renderType: Text.NativeRendering
                            text: row.modelData.old ?? ""
                            visible: text !== ""
                        }

                        Text {
                            color: root.config.muted
                            font.pointSize: root.config.textSizeSmall
                            renderType: Text.NativeRendering
                            text: "→"
                            visible: row.modelData.old !== ""
                        }

                        Text {
                            color: root.config.selectionBackground
                            font.pointSize: root.config.textSizeSmall
                            renderType: Text.NativeRendering
                            text: row.modelData.new ?? ""
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: root.config.spacingControl
                    anchors.right: parent.right
                    anchors.rightMargin: root.config.spacingControl
                    anchors.verticalCenter: parent.verticalCenter
                    color: row.modelData.level === "error" ? root.config.urgent : root.config.muted
                    elide: Text.ElideRight
                    font.pointSize: root.config.textSizeSmall
                    renderType: Text.NativeRendering
                    text: row.modelData.text ?? ""
                    visible: row.modelData.kind === "notice"
                }
            }
        }

        Text {
            anchors.centerIn: list
            width: list.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: root.rows.length === 0
            color: root.hasError ? root.config.urgent : root.config.muted
            font.pointSize: root.config.textSizeMedium
            renderType: Text.NativeRendering
            text: root.hasError ? root.controller.errorText : root.controller.busy ? "Checking for updates…" : "System is up to date"
        }

        ScrollIndicator {
            objectName: "updatesScrollIndicator"
            config: root.config
            flickable: list
            anchors.top: list.top
            anchors.bottom: list.bottom
            anchors.right: parent.right
            anchors.rightMargin: 6
        }

        Item {
            id: footer

            readonly property int buttonHeight: Math.max(refreshButton.implicitHeight, upgradeButton.implicitHeight)

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.config.panelPadding
            height: buttonHeight + root.config.spacingControl

            PanelSeparator {
                config: root.config
                anchors.top: parent.top
            }

            ShellButton {
                id: refreshButton

                anchors.left: parent.left
                anchors.bottom: parent.bottom
                config: root.config
                compact: true
                enabled: !root.controller.busy
                focusPolicy: Qt.NoFocus
                outlined: true
                text: "[r] Refresh"
                onClicked: {
                    root.controller.refresh();
                    keyboardHandler.forceActiveFocus();
                }
            }

            Text {
                anchors.left: refreshButton.right
                anchors.leftMargin: root.config.spacingControl
                anchors.right: upgradeButton.left
                anchors.rightMargin: root.config.spacingControl
                anchors.verticalCenter: refreshButton.verticalCenter
                color: root.hasError ? root.config.urgent : root.config.muted
                elide: Text.ElideRight
                font.pointSize: root.config.textSizeSmall
                renderType: Text.NativeRendering
                text: root.statusLabel
            }

            ShellButton {
                id: upgradeButton

                anchors.right: parent.right
                anchors.bottom: parent.bottom
                config: root.config
                compact: true
                enabled: !root.controller.busy && root.total > 0
                filled: true
                focusPolicy: Qt.NoFocus
                text: "[u] Upgrade"
                onClicked: root.controller.upgrade()
            }
        }
    }
}
