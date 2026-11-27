import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var app
    property string view: "summary"
    property bool confirmRevert: false
    property bool confirmReboot: false

    readonly property bool busy: app.runner.running
    readonly property bool clean: app.pending.length === 0
    readonly property bool wide: width > 720
    readonly property real detailH: Math.max(440, page.height - 24)
    readonly property var diffLines: root.app.diffText === "" ? [] : root.app.diffText.split("\n")
    readonly property var modes: [
        { id: "switch", title: "Aplicar ahora", sub: "Recomendado. Se activa ya y se conserva al reiniciar." },
        { id: "test", title: "Probar sin guardar", sub: "Se activa ya, pero se pierde al reiniciar." },
        { id: "boot", title: "Aplicar al próximo arranque", sub: "No cambia nada ahora; se activa al reiniciar." }
    ]
    readonly property string primaryLabel: app.applyMode === "test" ? "Validar y probar"
        : (app.applyMode === "boot" ? "Validar y programar" : "Validar y aplicar ahora")

    function runCommand() {
        const c = cmd.text.trim()
        if (c === "" || root.busy) return
        cmd.text = ""
        root.app.runFree(c)
    }

    Timer { id: confirmTimer; interval: 3500; onTriggered: { root.confirmRevert = false; root.confirmReboot = false } }

    Connections {
        target: root.app.runner
        function onRunningChanged() {
            if (!root.app.runner.running) return
            root.view = "log"
            if (!root.wide) Qt.callLater(() => { page.contentY = Math.max(0, page.contentHeight - page.height) })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // ───────────── Avisos ─────────────
        Rectangle {
            visible: root.app.resultText !== "" && root.app.runKind !== "try"
            Layout.fillWidth: true
            Layout.preferredHeight: bannerRow.implicitHeight + 24
            radius: Pal.rMd
            color: root.app.resultKind === "ok" ? Pal.okBg : (root.app.resultKind === "err" ? Pal.errBg : Pal.accentSoft)
            border.color: root.app.resultKind === "ok" ? Pal.alpha(Pal.ok, 0.5)
                        : (root.app.resultKind === "err" ? Pal.alpha(Pal.err, 0.5) : Pal.alpha(Pal.accent, 0.5))
            RowLayout {
                id: bannerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14
                spacing: 12
                Text {
                    text: root.app.resultKind === "ok" ? "✔" : (root.app.resultKind === "err" ? "✕" : "ℹ")
                    color: root.app.resultKind === "ok" ? Pal.ok : (root.app.resultKind === "err" ? Pal.err : Pal.accentText)
                    font.pixelSize: Pal.fs(16)
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.app.resultText
                    wrapMode: Text.WordWrap
                    color: Pal.text
                    font.pixelSize: Pal.fs(12)
                }
                Btn {
                    small: true
                    visible: root.app.resultKind === "err" && !root.busy && root.app.runner.errorFiles > 0
                    kind: "danger"
                    label: "Ir al error ↗"
                    onClicked: { const r = root.app.runner.firstErrorRef(); if (r) root.app.openFile(r.file, r.line) }
                }
                Btn { small: true; visible: root.app.resultKind === "err"; label: "Ver salida"; onClicked: root.view = "log" }
            }
        }

        Rectangle {
            visible: root.clean && root.app.bootPending && !root.busy
            Layout.fillWidth: true
            Layout.preferredHeight: rebootRow.implicitHeight + 24
            radius: Pal.rMd
            color: Pal.accentSoft
            border.color: Pal.alpha(Pal.accent, 0.5)
            RowLayout {
                id: rebootRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14
                spacing: 12
                Text { text: "↻"; color: Pal.accentText; font.pixelSize: Pal.fs(16); font.bold: true }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Hay una versión del sistema lista que se activará al reiniciar."
                    color: Pal.text
                    font.pixelSize: Pal.fs(12)
                }
                Btn {
                    small: true
                    kind: "primary"
                    label: root.confirmReboot ? "¿Seguro? Pulsa otra vez" : "Reiniciar ahora"
                    onClicked: {
                        if (!root.confirmReboot) { root.confirmReboot = true; confirmTimer.restart(); return }
                        root.confirmReboot = false
                        root.app.rebootNow()
                    }
                }
            }
        }

        Flickable {
            id: page
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: grid.height
            interactive: !root.wide
            boundsBehavior: Flickable.StopAtBounds

        GridLayout {
            id: grid
            width: page.width
            height: root.wide ? page.height : leftCol.implicitHeight + rowSpacing + root.detailH
            columns: root.wide ? 2 : 1
            columnSpacing: 14
            rowSpacing: 14

            // ───────────── Pasos y acciones ─────────────
            Flickable {
                id: leftFlick
                Layout.fillHeight: root.wide
                Layout.fillWidth: !root.wide
                Layout.preferredWidth: root.wide ? Math.min(380, Math.max(300, root.width * 0.4)) : -1
                Layout.preferredHeight: root.wide ? -1 : leftCol.implicitHeight
                contentHeight: leftCol.implicitHeight
                interactive: root.wide
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: leftCol
                    width: leftFlick.width
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: stCol.implicitHeight + 36
                        radius: Pal.rLg
                        color: Pal.card
                        border.color: Pal.border
                        ColumnLayout {
                            id: stCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 18
                            spacing: 12
                            Text { text: "Estado de tus cambios"; color: Pal.text; font.pixelSize: Pal.fs(14); font.bold: true }
                            Stepper {
                                Layout.fillWidth: true
                                visible: !root.clean
                                stage: root.app.stage
                                failedAt: root.app.failedAt
                                showHints: true
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: root.clean
                                wrapMode: Text.WordWrap
                                text: "No hay cambios pendientes. Añade paquetes desde la pestaña Paquetes y aquí podrás validarlos y aplicarlos."
                                color: Pal.textDim
                                font.pixelSize: Pal.fs(12)
                            }
                        }
                    }

                    Rectangle {
                        visible: !root.clean
                        Layout.fillWidth: true
                        implicitHeight: modeCol.implicitHeight + 36
                        radius: Pal.rLg
                        color: Pal.card
                        border.color: Pal.border
                        ColumnLayout {
                            id: modeCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 18
                            spacing: 10
                            Text { text: "¿Cómo quieres aplicarlos?"; color: Pal.text; font.pixelSize: Pal.fs(14); font.bold: true }
                            Repeater {
                                model: root.modes
                                delegate: Rectangle {
                                    id: card
                                    required property var modelData
                                    readonly property bool sel: root.app.applyMode === modelData.id
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 64
                                    radius: Pal.rMd
                                    color: sel ? Pal.accentSoft : (mm.containsMouse ? Pal.hover : "transparent")
                                    border.width: 1
                                    border.color: sel ? Pal.accent : Pal.border
                                    Rectangle {
                                        id: radio
                                        anchors.left: parent.left
                                        anchors.leftMargin: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "transparent"
                                        border.width: 2
                                        border.color: card.sel ? Pal.accent : Pal.border
                                        Rectangle { visible: card.sel; anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: Pal.accent }
                                    }
                                    ColumnLayout {
                                        anchors.left: radio.right
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text { Layout.fillWidth: true; text: card.modelData.title; elide: Text.ElideRight; color: Pal.text; font.pixelSize: Pal.fs(12); font.bold: true }
                                        Text {
                                            Layout.fillWidth: true
                                            text: card.modelData.sub
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            color: Pal.textDim
                                            font.pixelSize: Pal.fs(11)
                                        }
                                    }
                                    MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.app.applyMode = card.modelData.id }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        visible: !root.clean
                        Layout.fillWidth: true
                        spacing: 8
                        Btn {
                            Layout.fillWidth: true
                            kind: "primary"
                            icon: "▶"
                            label: root.primaryLabel
                            enabled: !root.busy
                            onClicked: root.app.runStep(root.app.applyMode)
                        }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: "Siempre se valida primero (dry-build). Si hay errores, no se aplica nada."
                            color: Pal.textFaint
                            font.pixelSize: Pal.fs(10)
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Btn { Layout.fillWidth: true; label: "Solo validar"; enabled: !root.busy; onClicked: root.app.runStep("validate") }
                            Btn {
                                Layout.fillWidth: true
                                kind: "danger"
                                label: root.confirmRevert ? "¿Seguro?" : "Deshacer todo"
                                enabled: !root.busy && root.app.changed.length > 0
                                onClicked: {
                                    if (!root.confirmRevert) { root.confirmRevert = true; confirmTimer.restart(); return }
                                    root.confirmRevert = false
                                    root.app.revertAll()
                                }
                            }
                        }
                        Btn { Layout.fillWidth: true; visible: root.busy; kind: "danger"; icon: "■"; label: "Detener"; onClicked: root.app.runner.stop() }
                    }
                }
            }

            // ───────────── Detalle ─────────────
            Rectangle {
                id: detail
                Layout.fillWidth: true
                Layout.fillHeight: root.wide
                Layout.preferredHeight: root.wide ? -1 : root.detailH
                Layout.minimumHeight: 320
                radius: Pal.rLg
                color: Pal.card
                border.color: Pal.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Segmented {
                            value: root.view
                            options: [
                                { id: "summary", label: "Resumen" },
                                { id: "diff", label: "Diff" },
                                { id: "log", label: root.busy ? "Terminal ●" : "Terminal" }
                            ]
                            onPicked: id => root.view = id
                        }
                        Item { Layout.fillWidth: true }
                        Badge {
                            visible: root.view === "log" && root.app.runner.title !== ""
                            tone: root.busy ? "accent" : (root.app.runner.exitCode === 0 ? "ok" : "err")
                            text: root.busy ? "ejecutando…" : (root.app.runner.exitCode === 0 ? "OK" : "falló (" + root.app.runner.exitCode + ")")
                        }
                        Btn { small: true; icon: "↻"; label: "Refrescar"; visible: root.view !== "log"; onClicked: root.app.refresh() }
                        Btn { small: true; label: "Limpiar"; visible: root.view === "log"; enabled: !root.busy; onClicked: root.app.runner.clear() }
                        Btn { small: true; label: "Copiar"; visible: root.view === "log"; onClicked: root.app.copyOutput() }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // ───────────── Resumen ─────────────
                        Item {
                            anchors.fill: parent
                            visible: root.view === "summary"
                            ListView {
                                id: sumList
                                anchors.fill: parent
                                anchors.rightMargin: 12
                                clip: true
                                spacing: 6
                                model: root.app.pending
                                boundsBehavior: Flickable.StopAtBounds
                                delegate: Rectangle {
                                    required property var modelData
                                    width: sumList.width
                                    height: 54
                                    radius: Pal.rMd
                                    color: Pal.raised
                                    Rectangle {
                                        id: sign
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 28
                                        height: 28
                                        radius: 14
                                        color: modelData.action === "add" ? Pal.okBg : Pal.errBg
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.action === "add" ? "＋" : "−"
                                            color: modelData.action === "add" ? Pal.ok : Pal.err
                                            font.pixelSize: Pal.fs(14)
                                            font.bold: true
                                        }
                                    }
                                    ColumnLayout {
                                        anchors.left: sign.right
                                        anchors.leftMargin: 12
                                        anchors.right: undo.left
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.attr; color: Pal.text; font.pixelSize: Pal.fs(13); font.bold: true }
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                            text: (modelData.action === "add" ? "Se añade en " : "Se quita de ") + modelData.file
                                            color: Pal.textDim
                                            font.pixelSize: Pal.fs(11)
                                        }
                                    }
                                    Btn {
                                        id: undo
                                        small: true
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        label: "Deshacer"
                                        enabled: !root.busy
                                        onClicked: modelData.action === "add" ? root.app.removePackage(modelData.attr, modelData.file) : root.app.addPackage(modelData.attr, modelData.file)
                                    }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: root.clean
                                text: "Sin cambios pendientes"
                                color: Pal.textFaint
                                font.pixelSize: Pal.fs(12)
                            }
                        }

                        // ───────────── Diff ─────────────
                        Rectangle {
                            anchors.fill: parent
                            visible: root.view === "diff"
                            radius: Pal.rMd
                            color: Pal.termBg
                            ListView {
                                id: diff
                                anchors.fill: parent
                                anchors.margins: 10
                                anchors.rightMargin: 18
                                clip: true
                                model: root.diffLines
                                boundsBehavior: Flickable.StopAtBounds
                                delegate: Rectangle {
                                    required property var modelData
                                    width: diff.width
                                    height: Pal.fs(19)
                                    radius: 3
                                    color: modelData.startsWith("+") && !modelData.startsWith("+++") ? Pal.diffAdd
                                         : modelData.startsWith("-") && !modelData.startsWith("---") ? Pal.diffDel
                                         : "transparent"
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        text: modelData
                                        textFormat: Text.PlainText
                                        font.family: Pal.mono
                                        font.pixelSize: Pal.fs(12)
                                        color: modelData.startsWith("@@") ? Pal.accentText
                                             : modelData.startsWith("+++") || modelData.startsWith("---") ? Pal.textDim
                                             : modelData.startsWith("+") ? Pal.ok
                                             : modelData.startsWith("-") ? Pal.err
                                             : Pal.text
                                    }
                                }
                            }
                            VScroll { target: diff; anchors.right: parent.right; anchors.rightMargin: 5; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 8 }
                            Text {
                                anchors.centerIn: parent
                                visible: root.diffLines.length === 0
                                text: "El diff aparecerá aquí"
                                color: Pal.textFaint
                                font.pixelSize: Pal.fs(12)
                            }
                        }

                        // ───────────── Terminal (salida en vivo y comandos) ─────────────
                        ColumnLayout {
                            anchors.fill: parent
                            visible: root.view === "log"
                            spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Pal.rMd
                            color: Pal.termBg
                            ListView {
                                id: out
                                anchors.fill: parent
                                anchors.margins: 10
                                anchors.rightMargin: 18
                                clip: true
                                model: root.app.runner.lines
                                boundsBehavior: Flickable.StopAtBounds
                                property bool follow: true
                                onMovementEnded: follow = atYEnd
                                onCountChanged: if (follow) Qt.callLater(() => out.positionViewAtEnd())

                                delegate: Item {
                                    required property string text
                                    required property string kind
                                    required property string file
                                    required property int line
                                    width: out.width
                                    height: lineText.implicitHeight + 2
                                    Text {
                                        id: lineText
                                        anchors.left: parent.left
                                        anchors.right: link.visible ? link.left : parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.text
                                        textFormat: Text.PlainText
                                        wrapMode: Text.WrapAnywhere
                                        font.family: Pal.mono
                                        font.pixelSize: Pal.fs(12)
                                        color: parent.kind === "err" ? Pal.err
                                             : parent.kind === "warn" ? Pal.warn
                                             : parent.kind === "ok" ? Pal.ok
                                             : parent.kind === "cmd" ? Pal.accentText
                                             : Pal.text
                                    }
                                    Text {
                                        id: link
                                        visible: parent.file !== ""
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "editar ↗"
                                        font.pixelSize: Pal.fs(11)
                                        color: Pal.accentText
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.app.openFile(parent.parent.file, parent.parent.line)
                                        }
                                    }
                                }
                            }
                            VScroll { target: out; anchors.right: parent.right; anchors.rightMargin: 5; anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 8 }
                            Text {
                                anchors.centerIn: parent
                                visible: root.app.runner.lines.count === 0
                                horizontalAlignment: Text.AlignHCenter
                                lineHeight: 1.4
                                text: "Aquí verás en vivo lo que ocurre al validar y aplicar.\nTambién puedes escribir cualquier comando abajo (se ejecuta en tu repositorio)."
                                color: Pal.textFaint
                                font.pixelSize: Pal.fs(12)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Field {
                                id: cmd
                                Layout.fillWidth: true
                                mono: true
                                icon: "$"
                                placeholder: "git status, nix flake check, journalctl -xe -n 50…"
                                onAccepted: root.runCommand()
                            }
                            Btn {
                                label: "Ejecutar"
                                kind: "primary"
                                enabled: !root.busy && cmd.text.trim() !== ""
                                onClicked: root.runCommand()
                            }
                        }
                        }
                    }
                }
            }
        }
        }
    }
}
