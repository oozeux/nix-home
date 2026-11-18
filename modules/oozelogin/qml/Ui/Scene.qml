import QtQuick
import "../Core"
import "../Layouts"

Item {
  id: root

  readonly property real u: Math.max(0.55, Math.min(2.2, height / 1080 * Config.v.uiScale / 100))
  readonly property string style: Config.v.layoutStyle

  Component.onCompleted: Sys.active = true

  Backdrop {
    id: bg
    anchors.fill: parent
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      if (!stage.item) return
      stage.item.dismiss()
      stage.item.focusInput()
    }
  }

  Component {
    id: singleLayout
    SingleCardLayout { u: root.u; backdrop: bg }
  }

  Component {
    id: splitLayout
    SplitLayout { u: root.u; backdrop: bg }
  }

  Component {
    id: ambientLayout
    AmbientLayout { u: root.u; backdrop: bg }
  }

  Component {
    id: classicLayout
    ClassicLayout { u: root.u; backdrop: bg }
  }

  Loader {
    id: stage
    anchors.fill: parent
    sourceComponent: {
      if (root.style === "split") return splitLayout
      if (root.style === "ambient") return ambientLayout
      if (root.style === "classic") return classicLayout
      return singleLayout
    }
  }
}
