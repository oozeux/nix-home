import QtQuick
import "../Core"

DropPill {
  id: root

  readonly property string currentName: {
    for (const s of Sys.sessions) if (s.id === Auth.sessionId) return s.name
    return Strings.t("noSessions")
  }

  glyph: Glyph.monitor
  text: root.currentName
  model: Sys.sessions.map(s => ({ id: s.id, exec: s.exec, label: s.name, selected: s.id === Auth.sessionId }))

  onPicked: item => {
    Auth.pickSession(item.id, item.exec)
    root.toggled()
  }
}
