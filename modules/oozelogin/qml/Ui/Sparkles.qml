import QtQuick
import "../Core"

Item {
  id: root

  property real u: 1

  readonly property var points: [
    { x: 0.06, y: 0.62, s: 26 },
    { x: 0.13, y: 0.18, s: 18 },
    { x: 0.22, y: 0.42, s: 12 },
    { x: 0.31, y: 0.80, s: 14 },
    { x: 0.40, y: 0.12, s: 12 },
    { x: 0.64, y: 0.80, s: 12 },
    { x: 0.74, y: 0.20, s: 16 },
    { x: 0.86, y: 0.36, s: 26 },
    { x: 0.93, y: 0.12, s: 44 },
    { x: 0.90, y: 0.68, s: 18 },
    { x: 0.55, y: 0.91, s: 10 }
  ]

  Repeater {
    model: root.points

    delegate: Sparkle {
      id: star
      required property var modelData
      required property int index
      x: modelData.x * root.width - width / 2
      y: modelData.y * root.height - height / 2
      size: modelData.s * root.u
      color: Qt.tint(Qt.rgba(1, 1, 1, 0.8), Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.25))

      SequentialAnimation on opacity {
        running: root.visible
        loops: Animation.Infinite
        NumberAnimation { from: 1; to: 0.3; duration: 1800 + star.index * 260; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.3; to: 1; duration: 1800 + star.index * 260; easing.type: Easing.InOutSine }
      }
    }
  }
}
