import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../../components"

Item {
    id: deviceRow

    required property var config
    required property var row
    property string actionText: ""
    property bool highlighted: false
    property bool trusted: false
    property bool selected: false
    readonly property string detailText: {
        if (deviceRow.row.pairing)
            return "Pairing…";
        if (deviceRow.row.connected)
            return "Connected";
        if (deviceRow.row.paired)
            return "Connect";
        if (!deviceRow.row.pairing)
            return "Pair";
        return "";
    }
    readonly property string batteryText: row.connected && row.batteryAvailable ? `${Math.round(row.battery * 100)}%` : ""

    signal activated
    signal focused

    implicitHeight: detailText === "" ? 28 : 36

    SelectionIndicator {
        config: deviceRow.config
        selected: deviceRow.selected
    }

    Item {
        x: 4
        width: 28
        height: parent.height

        IconImage {
            anchors.centerIn: parent
            implicitSize: 18
            source: deviceRow.row.icon ? Quickshell.iconPath(deviceRow.row.icon) : ""
            visible: source.toString() !== ""
        }

        Text {
            anchors.centerIn: parent
            visible: !deviceRow.row.icon
            color: deviceRow.config.selectionBackground
            font.family: deviceRow.config.iconFontFamily
            font.pointSize: deviceRow.config.iconSize
            text: "󰂯"
        }
    }

    Column {
        x: 38
        width: Math.max(0, parent.width - x - actionColumn.width - 12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Row {
            width: parent.width
            spacing: 4

            Text {
                renderType: Text.NativeRendering
                width: Math.min(Math.max(0, parent.width - trustedStar.width - (deviceRow.trusted ? parent.spacing : 0)), implicitWidth)
                color: deviceMouse.containsMouse ? Qt.lighter(deviceRow.config.fg, 1.15) : deviceRow.config.fg
                font.pointSize: deviceRow.config.textSizeMedium
                font.weight: deviceRow.selected || deviceRow.highlighted ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                text: deviceRow.row.name
            }

            Text {
                id: trustedStar
                width: deviceRow.trusted ? implicitWidth : 0
                color: deviceRow.config.selectionBackground
                font.pointSize: deviceRow.config.textSizeSmall
                font.weight: Font.DemiBold
                text: "★"
                visible: deviceRow.trusted
            }
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: deviceRow.detailText !== ""
            color: deviceRow.config.muted
            font.pointSize: deviceRow.config.textSizeSmall
            elide: Text.ElideRight
            text: deviceRow.detailText
        }
    }

    Item {
        id: actionColumn
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: deviceRow.actionText || deviceRow.batteryText ? 72 : 0

        Text {
            renderType: Text.NativeRendering
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            horizontalAlignment: Text.AlignRight
            color: deviceRow.config.muted
            font.pointSize: deviceRow.config.textSizeSmall
            elide: Text.ElideRight
            text: deviceRow.actionText || deviceRow.batteryText
        }
    }

    MouseArea {
        id: deviceMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: deviceRow.focused()
        onClicked: {
            deviceRow.focused();
            deviceRow.activated();
        }
    }
}
