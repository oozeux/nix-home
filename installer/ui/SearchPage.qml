import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var app

    property string mode: "search"
    property var results: []
    property int selected: -1
    property bool searching: false
    property string errText: ""
    property bool missing: false
    property string target: ""
    property int searchGen: 0
    property string pendingQuery: ""
    property bool rerun: false
    readonly property bool narrow: width < 720

    property bool showSelection: false

    readonly property var current: selected >= 0 && selected < results.length ? results[selected] : null
    readonly property var targetFiles: app.targets.map(t => t.file)
    readonly property string currentStatus: root.current ? root.statusOf(root.current.attr) : "none"
    readonly property string currentFile: root.mode === "installed" && root.current ? root.current.file : root.target
    readonly property bool alreadyIn: root.mode === "search" && root.current !== null && (root.app.inConfig[root.current.attr] ?? []).indexOf(root.target) >= 0

    function suggest(pkg) {
        const hay = (pkg.attr + " " + (pkg.desc ?? "")).toLowerCase()
        for (let i = 0; i < app.categories.length; i++) {
            const c = app.categories[i]
            if (root.targetFiles.indexOf(c.file) < 0) continue
            if ((c.keywords ?? []).some(k => hay.indexOf(k.toLowerCase()) >= 0)) return c.file
        }
        if (root.target !== "" && root.targetFiles.indexOf(root.target) >= 0) return root.target
        const home = app.targets.find(t => t.kind === "home")
        return home ? home.file : (root.targetFiles[0] ?? "")
    }

    function statusOf(attr) {
        const pa = root.app.pendingMap[attr]
        if (pa === "add") return root.app.stage === "tested" ? "tested" : "pending"
        if (pa === "remove") return "removing"
        return (root.app.inConfig[attr] ?? []).length > 0 ? "installed" : "none"
    }

    function statusText(st) {
        return st === "pending" ? "Sin aplicar" : st === "tested" ? "Probado (temporal)" : st === "removing" ? "Se quitará" : "En tu configuración"
    }

    function statusTone(st) {
        return st === "pending" ? "warn" : st === "tested" ? "accent" : st === "removing" ? "err" : "ok"
    }

    function categoryLabel(file) {
        for (const c of root.app.categories) if (c.file === file) return c.label
        return ""
    }

    function select(i) {
        root.selected = i
        if (i >= 0 && root.mode === "search" && root.results[i]) root.target = root.suggest(root.results[i])
    }

    function buildInstalled() {
        const q = field.text.trim().toLowerCase()
        const out = []
        for (const t of app.targets)
            for (const p of t.packages)
                if (q === "" || p.attr.toLowerCase().indexOf(q) >= 0 || t.file.toLowerCase().indexOf(q) >= 0)
                    out.push({ attr: p.attr, version: "", desc: t.file, file: t.file, line: p.line, unfree: false })
        root.results = out
        root.selected = out.length > 0 ? 0 : -1
    }

    function setMode(m) {
        root.mode = m
        root.errText = ""
        root.missing = false
        if (m === "installed") { debounce.stop(); root.buildInstalled() }
        else { root.results = []; root.selected = -1; root.startSearch() }
    }

    function startSearch() {
        if (root.mode === "installed") { root.buildInstalled(); return }
        const q = field.text.trim()
        if (q.length < 2) {
            root.rerun = false
            if (proc.running) proc.running = false
            root.results = []
            root.selected = -1
            root.searching = false
            return
        }
        root.pendingQuery = q
        if (proc.running) { root.rerun = true; proc.running = false; return }
        root.runSearch(q)
    }

    function runSearch(q) {
        proc.buf = []
        proc.gotGen = false
        proc.valid = false
        proc.err = ""
        proc.terms = q.split(/\s+/).filter(t => t !== "")
        root.searchGen++
        root.searching = true
        root.errText = ""
        root.missing = false
        proc.running = true
    }

    function parseItem(o) {
        if (!o || typeof o !== "object") return null
        const attr = o.package_attr_name ?? o.attr ?? o.attribute ?? o.name ?? ""
        if (attr === "") return null
        return {
            attr: attr,
            version: String(o.package_pversion ?? o.version ?? ""),
            desc: String(o.package_description ?? o.description ?? ""),
            unfree: o.package_unfree === true || o.unfree === true,
            file: "", line: 0
        }
    }

    function chooseCategory(c) {
        field.text = (c.keywords && c.keywords.length > 0) ? c.keywords[0] : c.label
        if (root.mode !== "search") root.mode = "search"
        root.startSearch()
    }

    Timer { id: debounce; interval: 350; onTriggered: root.startSearch() }

    Process {
        id: proc
        property var buf: []
        property var terms: []
        property bool gotGen: false
        property bool valid: false
        property string err: ""

        command: ["sh", "-c",
            'echo "$1"; shift; ' +
            'command -v nix-search >/dev/null 2>&1 || { echo __NO_NIX_SEARCH__; exit 127; }; ' +
            'exec nix-search "$@"',
            "sh", String(root.searchGen)
        ].concat(["--json", "--max-results", "40"],
                 (root.app.channel !== "" ? ["--channel", root.app.channel] : []),
                 ["--"], proc.terms)

        stdout: SplitParser {
            onRead: line => {
                if (!proc.gotGen) { proc.gotGen = true; proc.valid = (line === String(root.searchGen)); return }
                if (!proc.valid || line === "") return
                if (line === "__NO_NIX_SEARCH__") { root.missing = true; return }
                let parsed
                try { parsed = JSON.parse(line) } catch (e) { return }
                const list = Array.isArray(parsed) ? parsed : [parsed]
                for (let i = 0; i < list.length; i++) {
                    const it = root.parseItem(list[i])
                    if (it) proc.buf.push(it)
                }
                root.results = proc.buf.slice()
                if (root.selected < 0 && root.results.length > 0) root.select(0)
            }
        }
        stderr: SplitParser {
            onRead: line => { if (line.trim() !== "") proc.err = line.trim() }
        }
        onRunningChanged: {
            if (running) return
            root.searching = false
            if (root.rerun) { root.rerun = false; root.runSearch(root.pendingQuery); return }
            if (!proc.valid) return
            if (proc.buf.length === 0) { root.results = []; root.selected = -1; root.errText = proc.err }
        }
    }

    Connections {
        target: root.app
        function onTargetsChanged() { if (root.mode === "installed") root.buildInstalled() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // ───────────── Búsqueda ─────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Field {
                id: field
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                icon: "⌕"
                placeholder: root.mode === "search" ? (root.narrow ? "Buscar paquetes…" : "Buscar paquetes en nixpkgs (" + (root.app.channel !== "" ? root.app.channel : "unstable") + ")…") : "Filtrar paquetes de tu configuración…"
                onEdited: { if (root.mode === "installed") root.buildInstalled(); else debounce.restart() }
                onAccepted: { debounce.stop(); root.startSearch() }
            }
            Segmented {
                Layout.preferredHeight: 48
                value: root.mode
                options: [{ id: "search", label: "Buscar" }, { id: "installed", label: root.narrow ? "Mi config" : "En mi configuración" }]
                onPicked: id => root.setMode(id)
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            visible: root.mode === "search"
            Repeater {
                model: root.app.categories
                delegate: Rectangle {
                    height: 30
                    width: chip.implicitWidth + 24
                    radius: Pal.rMd + 4
                    color: cm.containsMouse ? Pal.accentSoft : Pal.card
                    border.color: cm.containsMouse ? Pal.alpha(Pal.accent, 0.5) : Pal.border
                    Behavior on color { ColorAnimation { duration: Pal.animFast } }
                    Text { id: chip; anchors.centerIn: parent; text: modelData.label; color: cm.containsMouse ? Pal.accentText : Pal.textDim; font.pixelSize: Pal.fs(11) }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.chooseCategory(modelData) }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.narrow ? 1 : 2
            columnSpacing: 14
            rowSpacing: 14

            // ───────────── Resultados ─────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumHeight: root.narrow ? 170 : 0
                radius: Pal.rLg
                color: Pal.card
                border.color: Pal.border
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Text {
                        Layout.leftMargin: 4
                        text: (root.mode === "search" ? "Resultados" : "En tu configuración") + " (" + root.results.length + ")"
                        color: Pal.text
                        font.pixelSize: Pal.fs(13)
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: list
                            anchors.fill: parent
                            anchors.rightMargin: 10
                            clip: true
                            spacing: 4
                            model: root.results
                            currentIndex: root.selected
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                id: row
                                required property var modelData
                                required property int index
                                readonly property string status: root.statusOf(modelData.attr)
                                readonly property bool sel: index === root.selected
                                width: list.width
                                height: Pal.fs(68)
                                radius: Pal.rMd
                                color: sel ? Pal.accentSoft : (hov.containsMouse ? Pal.hover : "transparent")
                                border.width: 1
                                border.color: sel ? Pal.alpha(Pal.accent, 0.5) : "transparent"
                                Behavior on color { ColorAnimation { duration: Pal.animFast } }

                                MouseArea { id: hov; anchors.fill: parent; hoverEnabled: true; onClicked: root.select(index) }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 14
                                    Rectangle {
                                        Layout.preferredWidth: 40
                                        Layout.preferredHeight: 40
                                        radius: Pal.rMd
                                        color: row.sel ? Pal.accent : Pal.raised
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.attr.charAt(0).toUpperCase()
                                            color: row.sel ? Pal.onAccent : Pal.accentText
                                            font.pixelSize: Pal.fs(16)
                                            font.bold: true
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true
                                            clip: true
                                            spacing: 8
                                            Text { text: modelData.attr; color: Pal.text; font.pixelSize: Pal.fs(14); font.bold: true }
                                            Text { visible: modelData.version !== ""; text: modelData.version; color: Pal.textFaint; font.pixelSize: Pal.fs(11) }
                                            Badge { visible: modelData.unfree; text: "unfree"; tone: "warn" }
                                            Badge {
                                                visible: row.status !== "none" && !(root.mode === "installed" && row.status === "installed")
                                                text: root.statusText(row.status)
                                                tone: root.statusTone(row.status)
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.desc
                                            color: Pal.textDim
                                            font.pixelSize: Pal.fs(11)
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                        VScroll { target: list; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom }

                        ColumnLayout {
                            anchors.centerIn: parent
                            visible: root.results.length === 0
                            spacing: 8
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.missing || root.errText !== "" ? "⚠" : (root.searching ? "…" : "⌕")
                                color: root.missing || root.errText !== "" ? Pal.err : Pal.textFaint
                                font.pixelSize: Pal.fs(34)
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.missing ? "No encuentro nix-search" : (root.searching ? "Buscando…" : (root.errText !== "" ? "La búsqueda falló" : (root.mode === "search" ? "Escribe al menos 2 letras" : "Sin paquetes")))
                                color: root.missing || root.errText !== "" ? Pal.err : Pal.text
                                font.pixelSize: Pal.fs(16)
                                font.bold: true
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: 420
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                color: Pal.textDim
                                font.pixelSize: Pal.fs(12)
                                text: root.missing ? "Instala nix-search-cli (por ejemplo: nix shell nixpkgs#nix-search-cli) y vuelve a abrir el instalador."
                                    : (root.errText !== "" ? root.errText : "")
                            }
                        }
                    }
                }
            }

            // ───────────── Detalle ─────────────
            Rectangle {
                Layout.fillWidth: root.narrow
                Layout.fillHeight: !root.narrow
                Layout.preferredWidth: root.narrow ? -1 : Math.max(340, Math.min(430, root.width * 0.4))
                Layout.preferredHeight: root.narrow ? 300 : -1
                Layout.minimumHeight: root.narrow ? 220 : 0
                radius: Pal.rLg
                clip: true
                color: Pal.card
                border.color: Pal.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Flickable {
                        id: detailFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: detailCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: detailCol
                            width: detailFlick.width
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                visible: root.current === null
                                wrapMode: Text.WordWrap
                                text: "Selecciona un paquete para ver sus detalles."
                                color: Pal.textFaint
                                font.pixelSize: Pal.fs(13)
                            }

                            ColumnLayout {
                                visible: root.current !== null
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    Text { Layout.fillWidth: true; elide: Text.ElideRight; text: root.current ? root.current.attr : ""; color: Pal.text; font.pixelSize: Pal.fs(24); font.bold: true }
                                    Text { visible: root.current !== null && root.current.version !== ""; text: root.current ? root.current.version : ""; color: Pal.accentText; font.pixelSize: Pal.fs(13) }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: root.current !== null && root.current.desc !== ""
                                    wrapMode: Text.WordWrap
                                    text: root.current ? root.current.desc : ""
                                    color: Pal.textDim
                                    font.pixelSize: Pal.fs(13)
                                }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Badge { visible: root.currentStatus !== "none"; text: root.statusText(root.currentStatus); tone: root.statusTone(root.currentStatus) }
                                    Badge { visible: root.current !== null && root.current.unfree; text: "unfree"; tone: "warn" }
                                    Badge { visible: root.categoryLabel(root.currentFile) !== ""; text: root.categoryLabel(root.currentFile); tone: "dim" }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: Pal.border }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "Atributo Nix"; color: Pal.text; font.pixelSize: Pal.fs(12); font.bold: true }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Rectangle {
                                            Layout.preferredHeight: 30
                                            Layout.preferredWidth: attrText.implicitWidth + 24
                                            radius: Pal.rSm + 2
                                            color: Pal.raised
                                            Text { id: attrText; anchors.centerIn: parent; text: root.current ? root.current.attr : ""; color: Pal.text; font.family: Pal.mono; font.pixelSize: Pal.fs(12) }
                                        }
                                        Btn {
                                            small: true
                                            visible: root.mode === "search"
                                            label: "Copiar nix shell"
                                            onClicked: root.app.copyTryCommand(root.current.attr)
                                        }
                                    }
                                }

                                ColumnLayout {
                                    visible: root.mode === "search"
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text { text: "Dónde se guardará"; color: Pal.text; font.pixelSize: Pal.fs(12); font.bold: true }
                                    Dropdown {
                                        app: root.app
                                        openUp: false
                                        Layout.fillWidth: true
                                        model: root.targetFiles
                                        value: root.target
                                        onPicked: v => root.target = v
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: root.mode === "installed" && root.current !== null
                                    wrapMode: Text.WordWrap
                                    text: root.current ? "Está en " + root.current.file + ", línea " + root.current.line + "." : ""
                                    color: Pal.textDim
                                    font.pixelSize: Pal.fs(12)
                                }

                                Rectangle {
                                    visible: root.mode === "search"
                                    Layout.fillWidth: true
                                    implicitHeight: howCol.implicitHeight + 28
                                    radius: Pal.rLg
                                    color: Pal.accentSoft
                                    border.color: Pal.alpha(Pal.accent, 0.5)
                                    ColumnLayout {
                                        id: howCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 14
                                        spacing: 10
                                        RowLayout {
                                            spacing: 8
                                            Rectangle {
                                                Layout.preferredWidth: 22
                                                Layout.preferredHeight: 22
                                                radius: 11
                                                color: Pal.accent
                                                Text { anchors.centerIn: parent; text: "i"; color: Pal.onAccent; font.pixelSize: Pal.fs(12); font.bold: true }
                                            }
                                            Text { text: "¿Cómo funciona?"; color: Pal.text; font.pixelSize: Pal.fs(13); font.bold: true }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            text: "Añadir no instala nada todavía: solo guarda el paquete en tu configuración. Antes de aplicarlo siempre se valida, y puedes probarlo sin instalar."
                                            color: Pal.textDim
                                            font.pixelSize: Pal.fs(11)
                                        }
                                        Stepper {
                                            Layout.fillWidth: true
                                            stage: root.app.stage
                                            failedAt: root.app.failedAt
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: root.mode === "search"
                        Btn {
                            icon: "▷"
                            label: "Probar sin instalar"
                            enabled: root.current !== null && !root.app.runner.running
                            onClicked: root.app.tryPackage(root.current.attr)
                        }
                        Btn {
                            Layout.fillWidth: true
                            kind: "primary"
                            icon: root.alreadyIn || root.currentStatus === "pending" || root.currentStatus === "tested" ? "✓" : "＋"
                            label: root.currentStatus === "pending" || root.currentStatus === "tested" ? "Añadido · falta aplicar"
                                 : (root.alreadyIn ? "Ya está en tu configuración" : "Añadir a mi selección")
                            enabled: root.current !== null && root.target !== "" && !root.alreadyIn
                            onClicked: root.app.addPackage(root.current.attr, root.target)
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        visible: root.mode === "installed"
                        Btn { label: "Editar archivo"; enabled: root.current !== null; onClicked: root.app.openFile(root.current.file, root.current.line) }
                        Btn {
                            Layout.fillWidth: true
                            kind: "danger"
                            label: "Quitar de la configuración"
                            enabled: root.current !== null
                            onClicked: root.app.removePackage(root.current.attr, root.current.file)
                        }
                    }
                }
            }
        }

        // ───────────── Actividad ─────────────
        Rectangle {
            visible: root.app.runner.running || (root.app.runKind === "try" && root.app.resultText !== "")
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: Pal.rMd
            color: Pal.raised
            border.color: root.app.runner.running ? Pal.alpha(Pal.accent, 0.5)
                        : (root.app.resultKind === "err" ? Pal.alpha(Pal.err, 0.5) : Pal.alpha(Pal.ok, 0.5))
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 10
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.app.runner.running ? Pal.accent : (root.app.resultKind === "err" ? Pal.err : Pal.ok)
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Pal.text
                    font.pixelSize: Pal.fs(12)
                    text: root.app.runner.running
                        ? root.app.runner.title + (root.app.runner.lines.count > 0 ? " — " + root.app.runner.lines.get(root.app.runner.lines.count - 1).text : "")
                        : root.app.resultText
                }
                Btn { small: true; label: "Ver salida"; onClicked: root.app.showOutput() }
                Btn { small: true; kind: "danger"; icon: "■"; label: "Detener"; visible: root.app.runner.running; onClicked: root.app.runner.stop() }
            }
        }

        // ───────────── Tu selección ─────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: selCol.implicitHeight + 28
            radius: Pal.rLg
            color: Pal.card
            border.color: Pal.border

            ColumnLayout {
                id: selCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 18
                anchors.rightMargin: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: Pal.rMd
                        color: Pal.accentSoft
                        Text { anchors.centerIn: parent; text: "▣"; color: Pal.accentText; font.pixelSize: Pal.fs(18) }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Tu selección"; color: Pal.text; font.pixelSize: Pal.fs(14); font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.app.pending.length === 0 ? "Nada pendiente. Añade paquetes para aplicarlos juntos."
                                : root.app.pending.length + (root.app.pending.length === 1 ? " cambio sin aplicar" : " cambios sin aplicar")
                            color: Pal.textDim
                            font.pixelSize: Pal.fs(11)
                        }
                    }
                    Btn {
                        visible: root.app.pending.length > 0
                        label: root.showSelection ? "Ocultar ▴" : "Ver detalles ▾"
                        onClicked: root.showSelection = !root.showSelection
                    }
                    Btn {
                        kind: "primary"
                        icon: "▶"
                        label: root.narrow ? "Aplicar (" + root.app.pending.length + ")" : "Revisar y aplicar (" + root.app.pending.length + ")"
                        enabled: root.app.pending.length > 0
                        onClicked: root.app.tab = 1
                    }
                }

                Flickable {
                    visible: root.showSelection && root.app.pending.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(96, chips.implicitHeight)
                    contentHeight: chips.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Flow {
                        id: chips
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: root.app.pending
                            delegate: Rectangle {
                                required property var modelData
                                height: 30
                                width: chipRow.implicitWidth + 20
                                radius: Pal.rMd + 4
                                color: modelData.action === "add" ? Pal.okBg : Pal.errBg
                                Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (modelData.action === "add" ? "＋ " : "− ") + modelData.attr
                                        color: modelData.action === "add" ? Pal.ok : Pal.err
                                        font.pixelSize: Pal.fs(11)
                                        font.bold: true
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "✕"
                                        color: Pal.textDim
                                        font.pixelSize: Pal.fs(11)
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.action === "add" ? root.app.removePackage(modelData.attr, modelData.file) : root.app.addPackage(modelData.attr, modelData.file)
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
}
