import QtQuick
import QtQuick.Layouts
import "../Core"
import "../Ui"

Item {
  id: root

  property real u: 1
  property Item backdrop: null
  property string menu: ""

  readonly property real topInset: Config.v.showTopBar ? topBar.height : 0

  function focusInput() { pw.focusInput() }
  function dismiss() { root.menu = "" }
  function toggleMenu(name) { root.menu = root.menu === name ? "" : name }

  Sparkles {
    anchors.fill: parent
    visible: Config.v.sparkles
    u: root.u
  }

  TopBar {
    id: topBar
    flat: true
    showRight: false
    visible: Config.v.showTopBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    u: root.u
  }

  Row {
    visible: Config.v.showPower
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 14 * root.u
    anchors.rightMargin: 32 * root.u
    spacing: 12 * root.u

    PowerButton {
      u: root.u
      kind: "suspend"
      tipBelow: true
    }
    PowerButton {
      u: root.u
      kind: "restart"
      tipBelow: true
    }
    PowerButton {
      u: root.u
      kind: "shutdown"
      tipBelow: true
    }
  }

  ColumnLayout {
    id: center
    width: 460 * root.u
    x: (root.width - width) / 2
    y: Math.max(root.topInset + 16 * root.u, (root.height - height) / 2 - 20 * root.u)
    spacing: 0

    ClockBlock {
      Layout.fillWidth: true
      visible: Config.v.showClock
      u: root.u
      timeSize: 140
      dateSize: 22
      shadow: true
    }

    AvatarHalo {
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 18 * root.u
      u: root.u
      size: 88
      decorated: false
    }

    Pill {
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 10 * root.u
      u: root.u
      text: Auth.shownName
      pixelSize: 22
      weight: Font.Light
      letterSpacing: 1.5
      textColor: Qt.tint(Config.text, Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.3))
      opacityBoost: -0.12
    }

    PasswordField {
      id: pw
      Layout.fillWidth: true
      Layout.topMargin: 16 * root.u
      Layout.preferredHeight: 56 * root.u
      u: root.u
    }

    StatusLine {
      Layout.fillWidth: true
      Layout.topMargin: 8 * root.u
      Layout.preferredHeight: 36 * root.u
      u: root.u
    }

    UserChips {
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 10 * root.u
      u: root.u
    }
  }

  ControlBar {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 36 * root.u
    anchors.bottomMargin: 36 * root.u
    u: root.u
    withPower: false
    up: true
    popupAlign: "right"
    menu: root.menu
    onMenuToggled: name => root.toggleMenu(name)
  }

  Tagline {
    u: root.u
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 40 * root.u
  }

  Dots {
    u: root.u
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 40 * root.u
    anchors.bottomMargin: 46 * root.u
  }
}
