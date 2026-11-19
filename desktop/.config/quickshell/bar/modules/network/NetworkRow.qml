import QtQuick
import "../../../components"

Item {
    id: root

    required property var config
    required property var row
    property bool selected: false
    property bool secured: true
    readonly property string statusText: {
        const state = root.row.connected ? "Connected" : (root.row.known ? "Saved" : "");
        const security = root.secured ? "Secured" : "Open";
        return state ? `${state}  ·  ${security}` : security;
    }

    signal activated
    signal focused

    function strengthIcon(strength) {
        if (strength >= 0.75)
            return "󰤨";

        if (strength >= 0.5)
            return "󰤥";

        if (strength >= 0.25)
            return "󰤢";

        return "󰤟";
    }

    implicitHeight: 40

    SelectionIndicator {
        config: root.config
        selected: root.selected
    }

    // Signal/lock icon beside the network name and status.
    Item {
        x: 4
        width: 28
        height: parent.height

        Text {
            anchors.centerIn: parent
            color: rowMouse.containsMouse ? Qt.lighter(root.config.fg, 1.15) : root.config.fg
            font.family: root.config.iconFontFamily
            font.pointSize: root.config.iconSize
            text: root.strengthIcon(root.row.strength)
        }
    }

    // Network name, security, and connection state.
    Column {
        x: 38
        width: Math.max(0, parent.width - x - signalLabel.width - 12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            color: rowMouse.containsMouse ? Qt.lighter(root.config.fg, 1.15) : root.config.fg
            font.pointSize: root.config.textSizeMedium
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            text: root.row.ssid
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            color: root.config.muted
            font.pointSize: root.config.textSizeSmall
            elide: Text.ElideRight
            text: root.statusText
        }
    }

    Text {
        id: signalLabel
        renderType: Text.NativeRendering
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        horizontalAlignment: Text.AlignRight
        color: root.config.muted
        font.pointSize: root.config.textSizeSmall
        text: `${Math.round(Math.max(0, Math.min(1, Number(root.row.strength) || 0)) * 100)}%`
    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onEntered: root.focused()
        onClicked: {
            root.focused();
            root.activated();
        }
    }
}
