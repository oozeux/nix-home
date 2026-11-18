import QtQuick
import "../Core"

Rectangle {
  id: root

  property real u: 1
  property real fillAlpha: 0.58
  property bool reveal: false

  function focusInput() { field.forceActiveFocus() }

  antialiasing: true
  implicitWidth: 420 * u
  implicitHeight: 64 * u
  radius: height / 2
  color: Qt.rgba(Config.bg.r, Config.bg.g, Config.bg.b, root.fillAlpha)
  border.width: 1
  border.color: Auth.failed ? Config.error : (field.activeFocus ? Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.55) : Qt.rgba(1, 1, 1, 0.12))

  Behavior on border.color { ColorAnimation { duration: 150 } }

  transform: Translate { id: shiftX }

  Connections {
    target: Auth
    function onBusyChanged() { if (!Auth.busy) field.forceActiveFocus() }
    function onFailCountChanged() { shake.restart() }
    function onUsernameChanged() { field.forceActiveFocus() }
  }

  Component.onCompleted: field.forceActiveFocus()

  SequentialAnimation {
    id: shake
    NumberAnimation { target: shiftX; property: "x"; to: -14 * root.u; duration: 50 }
    NumberAnimation { target: shiftX; property: "x"; to: 14 * root.u; duration: 70 }
    NumberAnimation { target: shiftX; property: "x"; to: -9 * root.u; duration: 60 }
    NumberAnimation { target: shiftX; property: "x"; to: 9 * root.u; duration: 60 }
    NumberAnimation { target: shiftX; property: "x"; to: 0; duration: 50 }
  }

  Icon {
    id: lockIcon
    anchors.left: parent.left
    anchors.leftMargin: 24 * root.u
    anchors.verticalCenter: parent.verticalCenter
    glyph: Glyph.lock
    font.pixelSize: 24 * root.u
    color: Config.subtext
  }

  TextInput {
    id: field
    anchors.left: lockIcon.right
    anchors.leftMargin: 16 * root.u
    anchors.right: capsSlot.left
    anchors.rightMargin: 12 * root.u
    anchors.verticalCenter: parent.verticalCenter
    height: parent.height
    verticalAlignment: TextInput.AlignVCenter
    clip: true
    color: Config.text
    font.family: Config.fontFamily
    font.pixelSize: 20 * root.u
    selectionColor: Config.primary
    selectedTextColor: Config.onPrimary
    echoMode: (Auth.awaiting && Auth.promptEcho) || root.reveal ? TextInput.Normal : TextInput.Password
    passwordCharacter: "•"
    readOnly: Auth.busy || Auth.launching
    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
    text: Auth.input
    onTextChanged: { if (Auth.input !== text) Auth.input = text }
    Keys.onReturnPressed: Auth.submit()
    Keys.onEnterPressed: Auth.submit()
    Keys.onEscapePressed: Auth.clear()

    Label {
      anchors.fill: parent
      visible: field.text.length === 0
      text: Auth.awaiting && Auth.prompt !== "" ? Auth.prompt : Strings.t("password")
      font.pixelSize: 20 * root.u
      color: Config.textSoft
      opacity: 0.72
    }
  }

  Item {
    id: capsSlot
    anchors.right: eye.left
    anchors.rightMargin: Sys.capsLock ? 6 * root.u : 0
    anchors.verticalCenter: parent.verticalCenter
    width: Sys.capsLock ? 32 * root.u : 0
    height: 32 * root.u
    visible: Sys.capsLock

    Icon {
      anchors.centerIn: parent
      glyph: Glyph.capsLock
      font.pixelSize: 24 * root.u
      color: Config.primary
    }
  }

  Item {
    id: eye
    anchors.right: parent.right
    anchors.rightMargin: 20 * root.u
    anchors.verticalCenter: parent.verticalCenter
    width: 36 * root.u
    height: 36 * root.u
    visible: !(Auth.awaiting && Auth.promptEcho)

    Icon {
      anchors.centerIn: parent
      glyph: root.reveal ? Glyph.eyeOff : Glyph.eye
      font.pixelSize: 24 * root.u
      color: eyeArea.containsMouse ? Config.text : Config.subtext
    }
    MouseArea {
      id: eyeArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: { root.reveal = !root.reveal; field.forceActiveFocus() }
    }
  }
}
