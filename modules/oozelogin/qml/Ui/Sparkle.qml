import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property real size: 20
  property color color: Qt.rgba(1, 1, 1, 0.85)

  implicitWidth: root.size
  implicitHeight: root.size
  width: implicitWidth
  height: implicitHeight

  Shape {
    width: 100
    height: 100
    scale: root.size / 100
    transformOrigin: Item.TopLeft
    antialiasing: true

    ShapePath {
      fillColor: root.color
      strokeColor: "transparent"
      PathSvg { path: "M 50 0 Q 50 50 100 50 Q 50 50 50 100 Q 50 50 0 50 Q 50 50 50 0 Z" }
    }
  }
}
