import QtQuick
import "../Core"

DropPill {
  id: root

  readonly property bool hasLayouts: Sys.layouts.length > 0
  readonly property string langName: {
    for (const l of Strings.languages) if (l.code === Strings.lang) return l.name
    return Strings.lang
  }
  readonly property var layoutItems: Sys.layouts.map((code, i) => ({ kind: "layout", index: i, label: Strings.layoutName(code), selected: i === Sys.layoutIndex }))
  readonly property var langItems: Strings.languages.map(l => ({ kind: "lang", code: l.code, label: l.name, selected: l.code === Strings.lang }))

  glyph: Glyph.globe
  text: root.hasLayouts ? Strings.layoutName(Sys.layouts[Sys.layoutIndex] || "") : root.langName
  model: {
    const out = []
    if (root.hasLayouts) {
      out.push({ header: true, label: Strings.t("keyboardLabel") })
      for (const item of root.layoutItems) out.push(item)
    }
    out.push({ header: true, label: Strings.t("interfaceLanguage") })
    for (const item of root.langItems) out.push(item)
    return out
  }

  onPicked: item => {
    if (item.kind === "layout") Sys.setLayout(item.index)
    else Strings.runtimeLang = item.code
    root.toggled()
  }
}
