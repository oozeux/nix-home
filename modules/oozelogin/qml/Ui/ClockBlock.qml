import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../Core"

ColumnLayout {
  id: root

  property real u: 1
  property real timeSize: 96
  property real dateSize: 20
  property bool shadow: false

  readonly property color timeColor: Qt.tint(Config.text, Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.38))

  spacing: 4 * u

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Label {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: Strings.time(clock.date, Config.v.clock24h)
    font.pixelSize: root.timeSize * root.u
    font.weight: Font.ExtraLight
    elide: Text.ElideNone
    color: root.timeColor
    layer.enabled: root.shadow
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowColor: Qt.rgba(0, 0, 0, 0.45)
      shadowBlur: 0.8
      shadowVerticalOffset: 2
    }
  }

  Label {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: Strings.longDate(clock.date)
    font.pixelSize: root.dateSize * root.u
    elide: Text.ElideNone
    color: Config.textSoft
    layer.enabled: root.shadow
    layer.effect: MultiEffect {
      shadowEnabled: true
      shadowColor: Qt.rgba(0, 0, 0, 0.45)
      shadowBlur: 0.8
      shadowVerticalOffset: 1
    }
  }

  RowLayout {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 6 * root.u
    visible: Config.v.showWeather && Sys.weatherOk
    spacing: 10 * root.u

    Icon {
      glyph: Sys.weatherInfo.glyph
      font.pixelSize: 22 * root.u
      color: Config.text
    }
    Label {
      text: Math.round(Sys.weatherTemp) + (Config.v.weatherFahrenheit ? "°F" : "°C") + "  ·  " + Strings.t(Sys.weatherInfo.key)
      font.pixelSize: 15 * root.u
      color: Config.textSoft
    }
  }
}
