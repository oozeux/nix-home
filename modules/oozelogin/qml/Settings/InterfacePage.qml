import QtQuick
import QtQuick.Layouts
import "../Core"
import "../Ui"

Page {
  Section {
    title: Strings.t("layoutSection")
    hint: Strings.t("layoutSectionHint")

    FormRow {
      last: Config.v.layoutStyle !== "single"
      label: Strings.t("layoutStyle")
      Choice {
        model: [
          { value: "single", label: Strings.t("layoutSingle") },
          { value: "split", label: Strings.t("layoutSplit") },
          { value: "ambient", label: Strings.t("layoutAmbient") },
          { value: "classic", label: Strings.t("layoutClassic") }
        ]
        current: Config.v.layoutStyle
        onPicked: v => Config.set("layoutStyle", v)
      }
    }

    FormRow {
      visible: Config.v.layoutStyle === "single"
      last: true
      label: Strings.t("singleToolbar")
      Choice {
        model: [
          { value: "inside", label: Strings.t("toolbarInside") },
          { value: "below", label: Strings.t("toolbarBelow") }
        ]
        current: Config.v.singleToolbar
        onPicked: v => Config.set("singleToolbar", v)
      }
    }
  }

  Section {
    title: Strings.t("panels")
    hint: Strings.t("panelsHint")

    ToggleRow { label: Strings.t("showTopBar"); key: "showTopBar" }
    ToggleRow { label: Strings.t("showInfoPanel"); key: "showInfoPanel" }
    ToggleRow { label: Strings.t("showClock"); key: "showClock" }
    ToggleRow { label: Strings.t("showWeather"); key: "showWeather" }
    ToggleRow { label: Strings.t("showStats"); key: "showStats" }
    ToggleRow { label: Strings.t("showSessionPanel"); key: "showSessionPanel" }
    ToggleRow { label: Strings.t("showKeyboard"); key: "showKeyboard" }
    ToggleRow { label: Strings.t("showPower"); key: "showPower" }
    ToggleRow { label: Strings.t("showUsers"); key: "showUsers" }
    ToggleRow { label: Strings.t("showTagline"); key: "showTagline" }
    ToggleRow { label: Strings.t("showFooter"); key: "showFooter" }
    ToggleRow { label: Strings.t("showDots"); key: "showDots" }
    ToggleRow { label: Strings.t("labelBubbles"); key: "labelBubbles" }
    ToggleRow { label: Strings.t("sessionPanelExpanded"); key: "sessionPanelExpanded" }
    ToggleRow { label: Strings.t("clock24h"); key: "clock24h"; last: true }
  }

  Section {
    title: Strings.t("texts")

    TextRow { label: Strings.t("brand"); key: "brand" }
    TextRow { label: Strings.t("subtitle"); key: "subtitle" }
    TextRow { label: Strings.t("tagline"); key: "tagline"; placeholder: "..." }
    TextRow { label: Strings.t("footerBrand"); key: "footerBrand"; last: true }
  }
}
