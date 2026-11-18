import QtQuick
import QtQuick.Layouts
import "../Core"

RowLayout {
  id: root

  property real u: 1
  property string menu: ""
  property bool up: true
  property bool withPower: true
  property string popupAlign: "center"
  property real maxLabel: 110
  signal menuToggled(string name)

  readonly property bool hasDrops: Config.v.showSessionPanel || Config.v.showKeyboard
  readonly property bool hasPower: root.withPower && Config.v.showPower
  readonly property bool hasAny: root.hasDrops || root.hasPower

  spacing: 8 * u
  visible: root.hasAny
  z: root.menu !== "" ? 100 : 0

  SessionDrop {
    visible: Config.v.showSessionPanel
    u: root.u
    up: root.up
    popupAlign: root.popupAlign
    maxLabel: root.maxLabel
    open: root.menu === "session"
    onToggled: root.menuToggled("session")
  }

  LanguageDrop {
    visible: Config.v.showKeyboard
    u: root.u
    up: root.up
    popupAlign: root.popupAlign
    maxLabel: root.maxLabel
    open: root.menu === "language"
    onToggled: root.menuToggled("language")
  }

  Rectangle {
    antialiasing: true
    visible: root.hasDrops && root.hasPower
    Layout.preferredWidth: 1
    Layout.preferredHeight: 34 * root.u
    color: Qt.rgba(1, 1, 1, 0.18)
  }

  PowerButton {
    visible: root.hasPower
    u: root.u
    kind: "restart"
  }

  PowerButton {
    visible: root.hasPower
    u: root.u
    kind: "shutdown"
  }
}
