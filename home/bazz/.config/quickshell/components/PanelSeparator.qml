import QtQuick

Rectangle {
    required property var config

    width: parent ? parent.width : 0
    implicitHeight: 1
    color: config.borderColor
}
