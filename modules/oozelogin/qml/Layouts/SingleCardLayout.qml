import QtQuick
import QtQuick.Layouts
import "../Core"
import "../Ui"

Item {
  id: root

  property real u: 1
  property Item backdrop: null
  property string menu: ""

  readonly property bool below: Config.v.singleToolbar === "below"
  readonly property real avatarHalf: 75 * u
  readonly property real topInset: Config.v.showTopBar ? topBar.height : 0
  readonly property real pad: 40 * u
  readonly property real gap: 16 * u
  readonly property real groupHeight: root.avatarHalf + card.height + (belowBar.visible ? root.gap + belowBar.height : 0)

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
    visible: Config.v.showTopBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    u: root.u
  }

  Glass {
    id: card
    backdrop: root.backdrop
    radius: Config.v.panelRadius * 1.4 * root.u
    width: 540 * root.u
    height: col.y + col.implicitHeight + root.pad
    x: (root.width - width) / 2
    y: Math.max(root.topInset + root.avatarHalf + 16 * root.u, (root.height - root.groupHeight) / 2 + root.avatarHalf)
    z: root.menu !== "" ? 100 : 1

    ColumnLayout {
      id: col
      x: root.pad
      y: root.avatarHalf + 30 * root.u
      width: card.width - root.pad * 2
      spacing: 0

      Label {
        Layout.alignment: Qt.AlignHCenter
        text: Auth.shownName
        font.pixelSize: 30 * root.u
        font.weight: Font.Light
        font.letterSpacing: 1.5 * root.u
        color: Qt.tint(Config.text, Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.3))
      }

      ClockBlock {
        Layout.fillWidth: true
        Layout.topMargin: 6 * root.u
        visible: Config.v.showClock
        u: root.u
        timeSize: 84
        dateSize: 18
      }

      PasswordField {
        id: pw
        Layout.fillWidth: true
        Layout.topMargin: 14 * root.u
        Layout.preferredHeight: 60 * root.u
        u: root.u
        fillAlpha: 0.5
      }

      StatusLine {
        Layout.fillWidth: true
        Layout.topMargin: 6 * root.u
        Layout.preferredHeight: 36 * root.u
        u: root.u
      }

      ControlBar {
        id: insideBar
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 6 * root.u
        visible: !root.below && insideBar.hasAny
        u: root.u
        up: false
        menu: root.menu
        onMenuToggled: name => root.toggleMenu(name)
      }

      UserChips {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 14 * root.u
        u: root.u
      }
    }
  }

  AvatarHalo {
    x: card.x + (card.width - width) / 2
    y: card.y - height / 2
    z: card.z + 1
    u: root.u
    size: 150
  }

  Glass {
    id: belowBar
    visible: root.below && belowControls.hasAny
    backdrop: root.backdrop
    radius: height / 2
    width: belowControls.implicitWidth + 40 * root.u
    height: 70 * root.u
    x: (root.width - width) / 2
    y: card.y + card.height + root.gap
    z: root.menu !== "" ? 100 : 1

    ControlBar {
      id: belowControls
      anchors.centerIn: parent
      u: root.u
      up: false
      menu: root.menu
      onMenuToggled: name => root.toggleMenu(name)
    }
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
