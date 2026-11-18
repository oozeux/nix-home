import QtQuick
import "../Core"

Item {
  id: root

  property real u: 1
  property real size: 150
  property bool decorated: true

  implicitWidth: root.size * u
  implicitHeight: root.size * u
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    antialiasing: true
    visible: root.decorated
    anchors.centerIn: parent
    width: parent.width + 30 * root.u
    height: width
    radius: width / 2
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.4)
  }

  RoundImage {
    anchors.fill: parent
    source: Auth.avatarSource
    ringWidth: 3 * root.u
    ringColor: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.85)
  }
}
