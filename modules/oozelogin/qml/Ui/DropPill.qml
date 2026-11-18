import QtQuick
import QtQuick.Layouts
import "../Core"

Rectangle {
  id: root

  property real u: 1
  property string glyph: ""
  property string text: ""
  property var model: []
  property bool open: false
  property bool up: true
  property bool block: false
  property string popupAlign: "center"
  property real maxLabel: 200
  signal toggled()
  signal picked(var item)

  antialiasing: true
  implicitWidth: row.implicitWidth + 28 * u
  implicitHeight: 44 * u
  radius: root.block ? 12 * u : height / 2
  z: root.open ? 100 : 0
  color: root.open || area.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(Config.bg.r, Config.bg.g, Config.bg.b, 0.45)
  border.width: 1
  border.color: Qt.rgba(1, 1, 1, root.open ? 0.22 : 0.12)

  Behavior on color { ColorAnimation { duration: 120 } }

  RowLayout {
    id: row
    anchors.fill: parent
    anchors.leftMargin: 14 * root.u
    anchors.rightMargin: 12 * root.u
    spacing: 8 * root.u

    Icon {
      glyph: root.glyph
      font.pixelSize: 20 * root.u
      color: Config.iconSoft
      Layout.preferredWidth: 22 * root.u
    }

    Label {
      text: root.text
      font.pixelSize: 14 * root.u
      color: Config.textSoft
      Layout.fillWidth: true
      Layout.maximumWidth: root.maxLabel * root.u
    }

    Icon {
      glyph: Glyph.chevron
      font.pixelSize: 16 * root.u
      color: Config.iconSoft
      rotation: root.open ? (root.up ? 90 : -90) : (root.up ? -90 : 90)
      Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }

  Rectangle {
    id: pop
    antialiasing: true
    visible: root.open && root.model.length > 0
    z: 100
    width: Math.max(root.width, 240 * root.u)
    height: popCol.implicitHeight + 12 * root.u
    x: root.popupAlign === "right" ? root.width - width : (root.popupAlign === "left" ? 0 : (root.width - width) / 2)
    y: root.up ? -height - 8 * root.u : root.height + 8 * root.u
    radius: 14 * root.u
    color: Qt.rgba(Config.bg.r, Config.bg.g, Config.bg.b, 0.94)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.14)

    MouseArea { anchors.fill: parent }

    Column {
      id: popCol
      x: 6 * root.u
      y: 6 * root.u
      width: pop.width - 12 * root.u

      Repeater {
        model: root.model

        delegate: Item {
          id: entry
          required property var modelData
          readonly property bool isHeader: !!modelData.header

          width: popCol.width
          height: entry.isHeader ? 32 * root.u : 40 * root.u

          Label {
            visible: entry.isHeader
            anchors.left: parent.left
            anchors.leftMargin: 12 * root.u
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4 * root.u
            text: String(entry.modelData.label).toUpperCase()
            font.pixelSize: 11 * root.u
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2 * root.u
            color: Config.primary
          }

          Rectangle {
            visible: !entry.isHeader
            anchors.fill: parent
            radius: 9 * root.u
            antialiasing: true
            color: entry.modelData.selected ? Qt.rgba(1, 1, 1, 0.10) : (itemArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")

            Icon {
              visible: !!entry.modelData.selected
              anchors.left: parent.left
              anchors.leftMargin: 10 * root.u
              anchors.verticalCenter: parent.verticalCenter
              glyph: Glyph.check
              font.pixelSize: 16 * root.u
              color: Config.primary
            }

            Label {
              anchors.left: parent.left
              anchors.leftMargin: 36 * root.u
              anchors.right: parent.right
              anchors.rightMargin: 10 * root.u
              anchors.verticalCenter: parent.verticalCenter
              text: entry.modelData.label
              font.pixelSize: 15 * root.u
              color: entry.modelData.selected ? Config.text : Config.textSoft
            }

            MouseArea {
              id: itemArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.picked(entry.modelData)
            }
          }
        }
      }
    }
  }
}
