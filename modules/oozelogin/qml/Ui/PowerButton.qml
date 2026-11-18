import QtQuick
import QtQuick.Layouts
import "../Core"

Rectangle {
  id: root

  property real u: 1
  property string kind: "shutdown"
  property bool row: false
  property bool armed: false
  property bool tipBelow: false

  readonly property bool confirms: root.kind !== "suspend"
  readonly property string glyph: root.kind === "restart" ? Glyph.restart : (root.kind === "suspend" ? Glyph.moon : Glyph.power)
  readonly property string caption: root.kind === "restart" ? Strings.t("restart") : (root.kind === "suspend" ? Strings.t("suspend") : Strings.t("shutdown"))
  readonly property color accent: root.armed ? Config.error : Config.textSoft

  function fire() {
    if (Config.preview) return
    if (root.kind === "restart") Sys.reboot()
    else if (root.kind === "suspend") Sys.suspend()
    else Sys.poweroff()
  }

  function press() {
    if (!root.confirms) { root.fire(); return }
    if (root.armed) {
      root.armed = false
      disarm.stop()
      root.fire()
      return
    }
    root.armed = true
    disarm.restart()
  }

  antialiasing: true
  implicitWidth: root.row ? 200 * u : 44 * u
  implicitHeight: root.row ? 46 * u : 44 * u
  radius: root.row ? 10 * u : height / 2
  color: {
    if (root.armed) return Qt.rgba(Config.error.r, Config.error.g, Config.error.b, 0.2)
    if (root.row) return area.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
    return area.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(Config.bg.r, Config.bg.g, Config.bg.b, 0.45)
  }
  border.width: root.row ? 0 : 1
  border.color: root.armed ? Config.error : Qt.rgba(1, 1, 1, 0.12)

  Behavior on color { ColorAnimation { duration: 120 } }

  Timer {
    id: disarm
    interval: 3000
    onTriggered: root.armed = false
  }

  Icon {
    visible: !root.row
    anchors.centerIn: parent
    glyph: root.glyph
    font.pixelSize: 20 * root.u
    color: root.accent
  }

  RowLayout {
    visible: root.row
    anchors.fill: parent
    anchors.leftMargin: 12 * root.u
    anchors.rightMargin: 12 * root.u
    spacing: 14 * root.u

    Icon {
      glyph: root.glyph
      font.pixelSize: 22 * root.u
      color: root.armed ? Config.error : Config.iconSoft
      Layout.preferredWidth: 26 * root.u
    }
    Label {
      text: root.armed ? Strings.t("sure") : root.caption
      font.pixelSize: 16 * root.u
      color: root.accent
      Layout.fillWidth: true
    }
  }

  Pill {
    visible: root.armed && !root.row
    u: root.u
    text: Strings.t("sure")
    pixelSize: 13
    tint: Config.error
    tintAmount: 0.3
    opacityBoost: 0.25
    x: (root.width - width) / 2
    y: root.tipBelow ? root.height + 8 * root.u : -height - 8 * root.u
    z: 100
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.press()
  }
}
