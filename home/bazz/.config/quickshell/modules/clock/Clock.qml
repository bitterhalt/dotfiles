import QtQuick
import Quickshell

import "../weather"

Item {
  id: root

  required property var config
  required property var barWindow
  required property var popupManager
  required property var weatherData
  required property var uiService

  readonly property int revealDuration: 300
  property real revealProgress: clockHover.hovered ? 1 : 0

  readonly property real revealExtent:
  revealRow.implicitWidth * revealProgress

  readonly property real revealSpacing:
  config.barModuleSpacing * revealProgress

  height: barWindow.height

  implicitWidth:
  clockText.implicitWidth
  + revealSpacing
  + revealExtent

  Behavior on revealProgress {
    NumberAnimation {
      duration: root.revealDuration
      easing.type: Easing.OutCubic
    }
  }

  HoverHandler {
    id: clockHover
  }

  Text {
    id: clockText

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    color: config.fg
    font.pointSize: config.fontSize(1)
    font.weight: Font.DemiBold
    text: Qt.formatDateTime(clock.date, config.clockFormat)

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }
  }

  Item {
    id: weatherClip

    x: clockText.implicitWidth + root.revealSpacing
    anchors.verticalCenter: parent.verticalCenter

    width: root.revealExtent
    height: revealRow.implicitHeight
    clip: true

    Row {
      id: revealRow

      x: weatherClip.width - implicitWidth
      anchors.verticalCenter: parent.verticalCenter
      spacing: config.barModuleSpacing

      Text {
        id: dateText

        color: config.fg
        font.pointSize: config.fontSize(1)
        font.weight: Font.DemiBold
        textFormat: Text.RichText

        text: {
          const formatted = Qt.formatDateTime(
            clock.date,
            config.clockAlternativeFormat
          )
          const weekday = Qt.formatDateTime(clock.date, "ddd")

          return formatted.replace(
            weekday,
            "<span style='color:" + config.accent + "'>"
              + weekday
              + "</span>"
          )
        }
      }

      Text {
        id: weatherText

        color: config.fg
        font.pointSize: config.fontSize(1)
        font.weight: Font.DemiBold
        text: weatherData.text
      }
    }
  }

  MouseArea {
    anchors.fill: weatherClip
    enabled: weatherClip.width > 0
    cursorShape: Qt.PointingHandCursor

    onClicked:
    popupManager.toggleHost(
      "weather",
      weatherPopupComponent,
      root,
      false,
      true
    )
  }

  Component {
    id: weatherPopupComponent

    WeatherPopup {
      config: root.config
      weatherData: root.weatherData
    }
  }

  Connections {
    target: uiService

    function onWeatherActionRequested(action): void {
      if (action === "close") {
        popupManager.closeHost("weather")
        return
      }

      if (barWindow.screen !== uiService.targetScreen) {
        popupManager.closeHost("weather")
        return
      }

      if (action === "toggle") {
        popupManager.toggleHost(
          "weather",
          weatherPopupComponent,
          root,
          false,
          true
        )
      } else if (action === "open") {
        popupManager.openHost(
          "weather",
          weatherPopupComponent,
          root,
          false,
          true
        )
      }
    }
  }
}
