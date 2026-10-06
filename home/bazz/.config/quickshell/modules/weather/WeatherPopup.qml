import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: root

    required property var config
    required property var weatherData

    // Popup geometry from Config.qml
    readonly property int popupRadius: config.popupRadius

    // Rest are hard coded in here
    readonly property int popupWidth: 360
    readonly property int popupPadding: 22
    readonly property int popupSpacing: 10


    implicitWidth: root.popupWidth
    implicitHeight: weatherPanel.implicitHeight + root.popupPadding * 2
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        color: config.surface
        border.color: config.borderColor
        border.width: 1
        radius: root.popupRadius

        Column {
                                    anchors.fill: parent
                                    anchors.margins: root.popupPadding
                                    id: weatherPanel
                                    spacing: root.popupSpacing

                                    // Current conditions
                                    Row {
                                        width: parent.width
                                        height: 64
                                        spacing: 12

                                        Text {
                                            width: 54
                                            anchors.verticalCenter: parent.verticalCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            color: config.fg
                                            font.pointSize: config.fontSize(2.615)
                                            text: weatherData.data.icon ?? "✨"
                                        }

                                        Column {
                                            width: parent.width - 66
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1

                                            Text {
                                                width: parent.width
                                                color: config.fg
                                                font.pointSize: config.fontSize(1.154)
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                                text: weatherData.data.place ?? "Weather"
                                            }

                                            Row {
                                                spacing: 8

                                                Text {
                                                    color: config.fg
                                                    font.pointSize: config.fontSize(1.846)
                                                    font.weight: Font.DemiBold
                                                    text: weatherData.data.available
                                                        ? `${weatherData.data.temperature}°`
                                                        : "N/A"
                                                }

                                                Column {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 0

                                                    Text {
                                                        color: config.muted
                                                        font.pointSize: config.fontSize(0.923)
                                                        text: weatherData.data.condition ?? ""
                                                    }

                                                    Text {
                                                        color: config.muted
                                                        font.pointSize: config.fontSize(0.846)
                                                        text: weatherData.data.available
                                                            ? `Feels like ${weatherData.data.feels}°`
                                                            : ""
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: config.borderColor
                                    }

                                    // Basic details from the old Waybar tooltip.
                                    Grid {
                                        width: parent.width
                                        columns: 2
                                        columnSpacing: 10
                                        rowSpacing: 7

                                        Text {
                                            width: 163
                                            color: config.fg
                                            font.pointSize: config.fontSize(0.923)
                                            text: weatherData.data.available
                                                ? `💧  Humidity   ${weatherData.data.humidity}%`
                                                : ""
                                        }

                                        Text {
                                            width: 163
                                            color: config.fg
                                            font.pointSize: config.fontSize(0.923)
                                            text: weatherData.data.available
                                                ? `💨  Wind   ${weatherData.data.wind} km/h ${weatherData.data.windDirection}`
                                                : ""
                                        }

                                        Text {
                                            width: 163
                                            color: config.fg
                                            font.pointSize: config.fontSize(0.923)
                                            text: weatherData.data.available
                                                ? `👀  Visibility   ${weatherData.data.visibility} km`
                                                : ""
                                        }

                                        Text {
                                            width: 163
                                            color: config.fg
                                            font.pointSize: config.fontSize(0.923)
                                            text: weatherData.data.available
                                                ? `🌞  UV index   ${weatherData.data.uv}`
                                                : ""
                                        }

                                        Text {
                                            width: 163
                                            color: config.fg
                                            font.pointSize: config.fontSize(0.923)
                                            text: weatherData.data.available
                                                ? `🌅  Sunrise   ${weatherData.data.sunrise}`
                                                : ""
                                        }

                                        Text {
                                            width: 163
                                            color: config.fg
                                            font.pointSize: config.fontSize(0.923)
                                            text: weatherData.data.available
                                                ? `🌇  Sunset   ${weatherData.data.sunset}`
                                                : ""
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: config.borderColor
                                    }

                                    Row {
                                        width: parent.width
                                        height: 24
                                        spacing: 8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: config.fg
                                            font.pointSize: config.fontSize(1.154)
                                            text: weatherData.data.moon?.icon ?? "🌑"
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: config.fg
                                            font.pointSize: config.fontSize(0.923)
                                            text: weatherData.data.moon
                                                ? `${weatherData.data.moon.name}  ·  ${weatherData.data.moon.illumination}%`
                                                : ""
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: config.borderColor
                                    }

                                    Text {
                                        color: config.muted
                                        font.pointSize: config.fontSize(0.846)
                                        font.weight: Font.DemiBold
                                        text: "7-DAY FORECAST"
                                    }

                                    Column {
                                        width: parent.width
                                        spacing: 2

                                        Repeater {
                                            model: weatherData.data.forecast ?? []

                                            Item {
                                                required property var modelData
                                                width: weatherPanel.width
                                                height: 25

                                                Text {
                                                    x: 0
                                                    width: 36
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: config.fg
                                                    font.pointSize: config.fontSize(0.923)
                                                    font.weight: Font.DemiBold
                                                    text: modelData.day
                                                }

                                                Text {
                                                    x: 48
                                                    width: 28
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    horizontalAlignment: Text.AlignHCenter
                                                    color: config.fg
                                                    font.pointSize: config.fontSize(1.154)
                                                    text: modelData.icon
                                                }

                                                Text {
                                                    x: 92
                                                    width: 84
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: config.fg
                                                    font.pointSize: config.fontSize(0.923)
                                                    text: `${modelData.high}° / ${modelData.low}°`
                                                }

                                                Text {
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: config.muted
                                                    font.pointSize: config.fontSize(0.923)
                                                    text: `🌧 ${modelData.rain}%`
                                                }
                                            }
                                        }
                                    }
                                }
    }
  }
