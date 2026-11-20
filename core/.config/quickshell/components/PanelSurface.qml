import QtQuick

// Appearance only: callers own layout, input, window mapping and motion.
Rectangle {
    required property var config

    color: config.bg
    border.color: config.border
    border.width: 1
    radius: config.popupRadius
}
