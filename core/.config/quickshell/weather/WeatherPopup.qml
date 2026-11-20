import QtQuick
import QtQuick.Layouts
import "../components"

FocusScope {
    id: root

    required property var config
    required property var weatherData

    // Weather keeps its own proportions, independently of text sizing.
    property real mainIconSize: config.iconSize * 3
    property real mainTemperatureSize: config.fontSize * 2.8
    property real forecastIconSize: config.iconSize * 1.3
    property real detailIconSize: config.iconSize
    property real moonIconSize: config.iconSize * 0.8

    signal closeRequested

    // Detail rows live in a two-column uniform grid inside the content
    // margins. Derive their value cap from the fixed popup width: reading any
    // layout-managed width back into a layout child makes Qt abort with
    // "Detected recursive rearrange".
    readonly property int contentMargin: 16
    readonly property int detailColumnSpacing: 14
    readonly property real detailValueMaxWidth: (width - contentMargin * 2 - detailColumnSpacing) / 2 * 0.62

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 32
    width: implicitWidth
    height: implicitHeight
    focus: true
    Component.onCompleted: Qt.callLater(() => {
        return forceActiveFocus();
    })
    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return;

        if (event.key === Qt.Key_F5) {
            if (!weatherData.refreshing && !event.isAutoRepeat)
                weatherData.refresh(true);

            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        }
    }

    PanelSurface {
        anchors.fill: parent
        config: root.config
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.contentMargin
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Icon {
                text: "󰍎"
                color: root.config.selectionBackground
            }

            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.weatherData.data.place || "Weather"
                font.weight: Font.DemiBold
                font.family: root.config.textFontFamily
                font.pointSize: root.config.textSizeNormal
                elide: Text.ElideRight
            }

            Label {
                objectName: "weatherRefreshHint"
                text: root.weatherData.refreshing ? "Refreshing…" : "F5 Refresh"
                color: root.config.muted
                font.family: root.config.textFontFamily
                font.pointSize: root.config.textSizeSmall
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 78
                Layout.preferredHeight: 78
                radius: root.config.popupRadius
                color: Qt.alpha(root.config.selectionBackground, 0.1)

                Text {
                    objectName: "weatherConditionIcon"
                    anchors.centerIn: parent
                    text: root.weatherData.data.icon || "✨"
                    font.pointSize: root.mainIconSize
                    font.family: root.config.textFontFamily
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0

                Label {
                    objectName: "weatherTemperature"
                    Layout.fillWidth: true
                    text: root.weatherData.data.available ? root.weatherData.data.temperature + "°C" : "N/A"
                    font.pointSize: root.mainTemperatureSize
                    font.family: root.config.textFontFamily
                    font.weight: Font.Bold
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: root.config.muted
                    font.pointSize: root.config.textSizeSmall
                    text: root.weatherData.data.available ? root.weatherData.data.condition + " · Feels like " + root.weatherData.data.feels + "°" : root.weatherData.refreshing ? "Loading weather…" : "Weather unavailable"
                }
            }
        }

        Separator {}

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            uniformCellWidths: true
            columnSpacing: root.detailColumnSpacing
            rowSpacing: 6

            Detail {
                icon: "󰖌"
                label: "Humidity"
                value: root.weatherData.data.humidity + "%"
            }

            Detail {
                icon: "󰖝"
                label: "Wind"
                value: root.weatherData.data.wind + " km/h " + root.weatherData.data.windDirection
            }

            Detail {
                icon: "󰈈"
                label: "Visibility"
                value: root.weatherData.data.visibility + " km"
            }

            Detail {
                icon: "󰖙"
                label: "UV index"
                value: String(root.weatherData.data.uv)
            }

            Detail {
                icon: "󰖜"
                label: "Sunrise"
                value: root.weatherData.data.sunrise || ""
            }

            Detail {
                icon: "󰖛"
                label: "Sunset"
                value: root.weatherData.data.sunset || ""
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: root.config.popupRadius
            color: Qt.alpha(root.config.selectionBackground, 0.12)

            Item {
                anchors.fill: parent

                Label {
                    objectName: "weatherMoonIcon"
                    visible: !!root.weatherData.data.moon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weatherData.data.moon ? root.weatherData.data.moon.icon : ""
                    font.pointSize: root.moonIconSize * 1.30
                }

                Label {
                    objectName: "weatherMoonName"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - 88)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    font.pointSize: root.config.textSizeSmall
                    text: root.weatherData.data.moon ? root.weatherData.data.moon.name : "Moon information unavailable"
                    font.family: root.config.textFontFamily
                }

                Label {
                    objectName: "weatherMoonIllumination"
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    horizontalAlignment: Text.AlignRight
                    font.pointSize: root.config.textSizeMedium
                    text: root.weatherData.data.moon ? root.weatherData.data.moon.illumination + "%" : ""
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                renderType: Text.NativeRendering
                text: "7-DAY FORECAST"
                color: root.config.muted
                font.weight: Font.DemiBold
                font.pointSize: root.config.textSizeSmall
            }

            Separator {}
        }

        Repeater {
            model: root.weatherData.data.forecast || []

            delegate: Rectangle {
                id: forecastRow

                required property var modelData
                required property int index

                objectName: "weatherForecast-" + index
                Layout.fillWidth: true
                implicitHeight: 28
                radius: root.config.popupRadius
                color: Qt.alpha(root.config.selectionBackground, index % 2 === 0 ? 0.1 : 0.05)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    Label {
                        Layout.preferredWidth: 34
                        text: forecastRow.modelData.day
                        font.weight: Font.DemiBold
                        font.pointSize: root.config.textSizeMedium
                    }

                    Label {
                        objectName: "weatherForecastIcon-" + forecastRow.index
                        Layout.preferredWidth: 28
                        text: forecastRow.modelData.icon
                        font.pointSize: root.forecastIconSize
                        font.family: root.config.textFontFamily
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        Layout.fillWidth: true
                        text: forecastRow.modelData.high + "° / " + forecastRow.modelData.low + "°"
                    }

                    Icon {
                        text: "󰖗"
                        color: root.config.muted
                    }

                    Label {
                        Layout.preferredWidth: 34
                        horizontalAlignment: Text.AlignRight
                        text: forecastRow.modelData.rain + "%"
                        color: root.config.muted
                    }
                }
            }
        }
    }

    component Label: Text {
        renderType: Text.NativeRendering
        textFormat: Text.PlainText
        color: root.config.fg
        font.family: root.config.textFontFamily
        font.pointSize: root.config.textSizeMedium
    }

    component Icon: Label {
        objectName: "weatherDetailIcon"
        font.family: root.config.iconFontFamily
        font.pointSize: root.detailIconSize
    }

    component Detail: RowLayout {
        id: detail

        required property string icon
        required property string label
        required property string value

        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 5

        Icon {
            text: detail.icon
            color: root.config.selectionBackground
        }

        Label {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: detail.label
            color: root.config.muted
            elide: Text.ElideRight
            font.pointSize: root.config.textSizeSmall
        }

        Item {
            // 62% of one uniform grid cell.
            Layout.maximumWidth: root.detailValueMaxWidth
            implicitWidth: valueLabel.implicitWidth + 12
            implicitHeight: 20

            Label {
                id: valueLabel

                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                text: root.weatherData.data.available ? detail.value : "—"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                font.pointSize: root.config.textSizeSmall
            }
        }
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: root.config.border
    }
}
