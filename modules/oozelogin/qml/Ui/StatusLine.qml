import QtQuick
import "../Core"

Item {
  id: root

  property real u: 1

  readonly property bool capsOnly: Auth.statusText === "" && Sys.capsLock
  readonly property string statusLine: Auth.statusText !== "" ? Auth.statusText : (Sys.capsLock ? Strings.t("capsOn") : (Config.preview ? Strings.t("previewHint") : ""))

  implicitWidth: 420 * u
  implicitHeight: 38 * u

  Pill {
    anchors.centerIn: parent
    width: Math.min(implicitWidth, parent.width)
    u: root.u
    pixelSize: 14
    text: root.statusLine
    tint: Auth.failed ? Config.error : Config.primary
    tintAmount: Auth.failed ? 0.30 : (root.capsOnly ? 0.25 : 0)
    opacityBoost: Auth.failed ? 0.26 : (root.capsOnly ? 0.23 : 0)
  }
}
