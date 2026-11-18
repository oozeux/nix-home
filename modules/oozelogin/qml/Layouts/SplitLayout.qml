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
  readonly property real clockWidth: 300 * u
  readonly property real cardWidth: 380 * u
  readonly property real panelWidth: 250 * u
  readonly property real gap: 28 * u
  readonly property real pad: 22 * u
  readonly property bool hasClock: Config.v.showClock
  readonly property bool hasPanel: Config.v.showSessionPanel || Config.v.showKeyboard || Config.v.showPower
  readonly property real clockSpan: root.hasClock ? root.clockWidth + root.gap * 2 + 1 : 0
  readonly property real totalWidth: root.clockSpan + root.cardWidth + (root.hasPanel ? root.gap + root.panelWidth : 0)
  readonly property real startX: (root.width - root.totalWidth) / 2
  readonly property real midY: Math.max(root.topInset + card.height / 2 + 24 * u, root.height / 2 - 10 * u)

  function focusInput() { pw.focusInput() }
  function dismiss() { root.menu = "" }
  function toggleMenu(name) { root.menu = root.menu === name ? "" : name }

  TopBar {
    id: topBar
    flat: true
    visible: Config.v.showTopBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    u: root.u
  }

  ClockBlock {
    visible: root.hasClock
    x: root.startX
    y: root.midY - height / 2
    width: root.clockWidth
    u: root.u
    timeSize: 92
    dateSize: 18
    shadow: true
  }

  Rectangle {
    antialiasing: true
    visible: root.hasClock
    x: root.startX + root.clockWidth + root.gap
    y: root.midY - height / 2
    width: 1
    height: Math.min(card.height * 0.85, 240 * root.u)
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0) }
      GradientStop { position: 0.5; color: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.55) }
      GradientStop { position: 1.0; color: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0) }
    }
  }

  Glass {
    id: card
    backdrop: root.backdrop
    radius: Config.v.panelRadius * 1.3 * root.u
    width: root.cardWidth
    height: col.y + col.implicitHeight + root.pad
    x: root.startX + root.clockSpan
    y: root.midY - height / 2
    z: 1

    ColumnLayout {
      id: col
      x: root.pad
      y: root.pad
      width: card.width - root.pad * 2
      spacing: 0

      AvatarHalo {
        Layout.alignment: Qt.AlignHCenter
        u: root.u
        size: 112
        decorated: false
      }

      Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10 * root.u
        text: Auth.shownName
        font.pixelSize: 26 * root.u
        font.weight: Font.Light
        font.letterSpacing: 1.5 * root.u
        color: Qt.tint(Config.text, Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.3))
      }

      PasswordField {
        id: pw
        Layout.fillWidth: true
        Layout.topMargin: 16 * root.u
        Layout.preferredHeight: 56 * root.u
        u: root.u
        fillAlpha: 0.5
      }

      StatusLine {
        Layout.fillWidth: true
        Layout.topMargin: 6 * root.u
        Layout.preferredHeight: 36 * root.u
        u: root.u
      }

      UserChips {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 12 * root.u
        u: root.u
      }
    }
  }

  Glass {
    id: panel
    visible: root.hasPanel
    backdrop: root.backdrop
    radius: Config.v.panelRadius * 1.2 * root.u
    width: root.panelWidth
    height: panelCol.implicitHeight + 36 * root.u
    x: card.x + card.width + root.gap
    y: root.midY - height / 2
    z: root.menu !== "" ? 100 : 1

    ColumnLayout {
      id: panelCol
      x: 18 * root.u
      y: 18 * root.u
      width: panel.width - 36 * root.u
      spacing: 8 * root.u

      SessionDrop {
        Layout.fillWidth: true
        visible: Config.v.showSessionPanel
        u: root.u
        block: true
        up: false
        popupAlign: "left"
        open: root.menu === "session"
        onToggled: root.toggleMenu("session")
      }

      LanguageDrop {
        Layout.fillWidth: true
        visible: Config.v.showKeyboard
        u: root.u
        block: true
        up: false
        popupAlign: "left"
        open: root.menu === "language"
        onToggled: root.toggleMenu("language")
      }

      Rectangle {
        antialiasing: true
        Layout.fillWidth: true
        Layout.topMargin: 4 * root.u
        Layout.bottomMargin: 4 * root.u
        visible: (Config.v.showSessionPanel || Config.v.showKeyboard) && Config.v.showPower
        height: 1
        color: Qt.rgba(1, 1, 1, 0.14)
      }

      PowerButton {
        Layout.fillWidth: true
        visible: Config.v.showPower
        u: root.u
        kind: "restart"
        row: true
      }

      PowerButton {
        Layout.fillWidth: true
        visible: Config.v.showPower
        u: root.u
        kind: "shutdown"
        row: true
      }
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
