import QtQuick
import QtQuick.Layouts
import "../Core"

RowLayout {
  id: root

  property real u: 1
  property real lineWidth: 72

  readonly property color clear: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0)
  readonly property color solid: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.6)

  spacing: 12 * u

  Rectangle {
    antialiasing: true
    Layout.preferredWidth: root.lineWidth * root.u
    Layout.preferredHeight: 1
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: root.clear }
      GradientStop { position: 1.0; color: root.solid }
    }
  }

  Sparkle {
    size: 16 * root.u
    color: Qt.tint(Config.text, Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.4))
  }

  Rectangle {
    antialiasing: true
    Layout.preferredWidth: root.lineWidth * root.u
    Layout.preferredHeight: 1
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: root.solid }
      GradientStop { position: 1.0; color: root.clear }
    }
  }
}
