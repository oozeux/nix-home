import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string stage: "clean"
    property string failedAt: ""
    property bool showHints: false

    spacing: 9

    readonly property var rows: [
        { label: "Añadir paquete", hint: "Se guarda en tu archivo .nix, aún sin instalar" },
        { label: "Validar cambios (dry-build)", hint: "Comprueba que la configuración compila" },
        { label: "Probar configuración (opcional)", hint: "Activa los cambios hasta el próximo reinicio" },
        { label: "Aplicar cambios", hint: "Ahora o en el próximo arranque" }
    ]

    function stateOf(i) {
        const s = root.stage
        if (i === 0) return s === "clean" ? "active" : "done"
        if (i === 1) {
            if (root.failedAt === "validate") return "error"
            if (s === "validated" || s === "tested") return "done"
            return s === "pending" ? "active" : "todo"
        }
        if (i === 2) {
            if (s === "tested") return "done"
            return s === "validated" ? "active" : "todo"
        }
        if (root.failedAt === "apply") return "error"
        return (s === "validated" || s === "tested") ? "active" : "todo"
    }

    Repeater {
        model: root.rows
        delegate: RowLayout {
            id: line
            required property var modelData
            required property int index
            readonly property string st: root.stateOf(index)
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignTop
                radius: 11
                color: line.st === "done" ? Pal.accent
                     : line.st === "error" ? Pal.errBg
                     : line.st === "active" ? Pal.accentSoft
                     : "transparent"
                border.width: 2
                border.color: line.st === "error" ? Pal.err
                            : line.st === "todo" ? Pal.border
                            : Pal.accent
                Text {
                    anchors.centerIn: parent
                    text: line.st === "done" ? "✓" : (line.st === "error" ? "✕" : "")
                    color: line.st === "error" ? Pal.err : Pal.onAccent
                    font.pixelSize: Pal.fs(12)
                    font.bold: true
                }
                Rectangle {
                    visible: line.st === "active"
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: Pal.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: line.modelData.label
                    elide: Text.ElideRight
                    color: line.st === "todo" ? Pal.textDim : Pal.text
                    font.pixelSize: Pal.fs(12)
                    font.bold: line.st === "active"
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.showHints
                    text: line.modelData.hint
                    wrapMode: Text.WordWrap
                    color: Pal.textFaint
                    font.pixelSize: Pal.fs(10)
                }
            }
        }
    }
}
