import QtQuick
import Quickshell
import Quickshell.Io

import "../weather"

Item {
  id: root

  required property var config
  required property var barWindow
  required property var popupManager

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

  WeatherData {
    id: weather
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
        text: weather.text
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
      weatherData: weather
    }
  }

  IpcHandler {
    target: "weather"

    function toggle(): void {
      popupManager.toggleHost(
        "weather",
        weatherPopupComponent,
        root,
        false,
        true
      )
    }

    function open(): void {
      popupManager.openHost(
        "weather",
        weatherPopupComponent,
        root,
        false,
        true
      )
    }

    function close(): void {
      popupManager.closeHost("weather")
    }
  }
}
