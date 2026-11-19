import "../components/CriticalColors.js" as CriticalColors
import "HistoryModel.js" as HistoryModel
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Services.Notifications

// Toast preview only. Full text and actions belong to notification history.
Rectangle {
    id: root

    required property var config
    property var notification: null
    readonly property int appIconSize: 36
    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical
    readonly property color criticalTextColor: CriticalColors.text

    implicitHeight: 100
    clip: true
    radius: config.popupRadius
    color: config.bg
    border.color: config.border
    border.width: 1

    Item {
        id: imageBox

        objectName: "notificationIconBox"
        anchors.right: parent.right
        anchors.rightMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        width: root.appIconSize
        height: width

        Image {
            id: appIcon
            objectName: "notificationIcon"

            anchors.fill: parent
            source: root.critical ? "" : HistoryModel.appIconSource(root.notification, (name, fallback) => Quickshell.iconPath(name, fallback))
            sourceSize.width: Math.ceil(width * Screen.devicePixelRatio * 2)
            sourceSize.height: Math.ceil(height * Screen.devicePixelRatio * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            visible: status === Image.Ready
        }

        Text {
            objectName: "notificationFallbackIcon"
            anchors.centerIn: parent
            visible: !appIcon.visible
            color: root.critical ? root.criticalTextColor : config.muted
            font.family: config.iconFontFamily
            font.pointSize: config.iconSize
            text: root.critical ? "󰀧" : "󰂚"
        }
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: imageBox.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            textFormat: Text.PlainText
            color: root.critical ? root.criticalTextColor : config.fg
            font.pointSize: config.textSizeNormal
            font.weight: Font.DemiBold
            maximumLineCount: 1
            elide: Text.ElideRight
            text: root.notification ? (root.notification.summary || "") : ""
        }

        Text {
            renderType: Text.NativeRendering
            width: parent.width
            visible: text.length > 0
            color: config.muted
            font.pointSize: config.textSizeMedium
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: root.notification ? (root.notification.body || "") : ""
        }
    }
}
