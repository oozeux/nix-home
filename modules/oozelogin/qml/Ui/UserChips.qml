import QtQuick
import QtQuick.Layouts
import "../Core"

RowLayout {
  id: root

  property real u: 1

  spacing: 30 * u
  visible: Config.v.showUsers && Sys.users.length > 1

  Repeater {
    model: Sys.users

    delegate: ColumnLayout {
      id: chip
      required property var modelData
      readonly property bool selected: modelData.name === Auth.username
      spacing: 8 * root.u

      RoundImage {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 58 * root.u
        Layout.preferredHeight: 58 * root.u
        source: chip.modelData.avatar !== "" ? Config.avatarUrl(chip.modelData.avatar) : ""
        ringWidth: chip.selected ? 2 * root.u : 0
        ringColor: Qt.rgba(Config.primary.r, Config.primary.g, Config.primary.b, 0.9)
        opacity: chip.selected || chipArea.containsMouse ? 1 : 0.75
        Behavior on opacity { NumberAnimation { duration: 120 } }

        MouseArea {
          id: chipArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Auth.select(chip.modelData.name)
        }
      }

      Label {
        Layout.alignment: Qt.AlignHCenter
        text: chip.modelData.name
        font.pixelSize: 14 * root.u
        color: chip.selected ? Config.text : Config.subtext
      }
    }
  }
}
