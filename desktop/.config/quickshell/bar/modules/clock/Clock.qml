import QtQuick
import Quickshell

import "../../../components"
import "../../../weather"

ItemRevealer {
    id: root

    required property var popupManager
    required property var weatherData
    required property var uiService
    required property var resumeService

    Connections {
        target: root.resumeService
        function onResumed(): void {
            clock.enabled = false;
            clock.enabled = true;
        }
    }

    function weatherAction(action): void {
        if (action === "close" || root.barWindow.screen !== root.uiService.targetScreen) {
            root.popupManager.closeHost("weather");
            return;
        }
        if (action === "toggle")
            root.popupManager.toggleHost("weather", weatherPopupComponent, root, true, true);
        else if (action === "open")
            root.popupManager.openHost("weather", weatherPopupComponent, root, true, true);
    }

    Component {
        id: weatherPopupComponent
        WeatherPopup {
            config: root.config
            weatherData: root.weatherData
            onCloseRequested: root.popupManager.closeHost("weather")
        }
    }

    Connections {
        target: root.uiService
        function onWeatherActionRequested(action): void {
            root.weatherAction(action);
        }
    }

    // Primary bar time; the alternative date format is revealed on hover.
    Text {
        renderType: Text.NativeRendering
        color: root.config.fg
        font.pointSize: root.config.textSizeNormal
        font.weight: Font.DemiBold
        text: Qt.formatDateTime(clock.date, root.config.clockFormat)

        SystemClock {
            id: clock
            objectName: "barClock"
            precision: SystemClock.Minutes
        }
    }

    revealData: [
        Text {
            renderType: Text.NativeRendering
            color: root.config.fg
            font.pointSize: root.config.textSizeNormal
            font.weight: Font.DemiBold
            textFormat: Text.RichText

            text: {
                const formatted = Qt.formatDateTime(clock.date, root.config.clockAlternativeFormat);
                const longName = Qt.formatDateTime(clock.date, "dddd");
                const shortName = Qt.formatDateTime(clock.date, "ddd");

                // Check the long name first, since it usually contains the short one
                const weekday = formatted.includes(longName) ? longName : shortName;

                return formatted.replace(weekday, "<span style='color:" + root.config.selectionBackground + "'>" + weekday + "</span>");
            }
        },
        Text {
            renderType: Text.NativeRendering
            color: root.config.fg
            font.pointSize: root.config.textSizeNormal
            font.weight: Font.DemiBold
            text: root.weatherData.data.available ? root.weatherData.data.temperature + "°C" : "N/A"
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.popupManager.toggleHost("weather", weatherPopupComponent, root, true, true)
            }
        }
    ]
}
