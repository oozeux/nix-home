import QtQuick
import QtQuick.Layouts
import "../Core"

ColumnLayout {
  id: root

  property real u: 1

  spacing: 0

  function focusInput() { field.focusInput() }

  RoundImage {
    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: 170 * root.u
    Layout.preferredHeight: 170 * root.u
    source: Auth.avatarSource
    ringWidth: 3 * root.u
    ringColor: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.85)
  }

  Pill {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 12 * root.u
    u: root.u
    text: Auth.shownName
    pixelSize: 30
    weight: Font.Light
    letterSpacing: 1.5
    textColor: Qt.tint(Config.text, Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.3))
    opacityBoost: -0.12
  }

  PasswordField {
    id: field
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 22 * root.u
    Layout.preferredWidth: 420 * root.u
    Layout.preferredHeight: 64 * root.u
    u: root.u
  }

  StatusLine {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 10 * root.u
    Layout.preferredWidth: 420 * root.u
    Layout.preferredHeight: 38 * root.u
    u: root.u
  }

  UserChips {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 14 * root.u
    u: root.u
  }
}
