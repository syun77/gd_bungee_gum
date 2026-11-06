import AppKit

final class MapEdit: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1180, height: 620),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                                  backing: .buffered, defer: false)
    private let canvas = Canvas()
    private let category = NSPopUpButton()
    private let variant = NSPopUpButton()
    private let status = NSTextField(labelWithString: "")
    private let history = UndoManager()
    private var baseline: Data?
    private var file: URL?
    private var categories: [String] = []
    private var variants: [[Int]] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        history.levelsOfUndo = 50
        history.groupsByEvent = false
        window.title = "MapEdit"
        window.delegate = self
        window.minSize = NSSize(width: 650, height: 350)
        window.center()
        installMenu()

        category.target = self
        category.action = #selector(selectCategory)
        variant.target = self
        variant.action = #selector(selectVariant)
        let fitButton = NSButton(title: "全体表示", target: self, action: #selector(fit))
        let bar = NSStackView(views: [NSTextField(labelWithString: "配置"), category, variant, fitButton, status])
        bar.spacing = 8

        let hint = NSTextField(labelWithString: "左ドラッグで配置・移動　右ドラッグで消去　Space + ドラッグでパン　ホイール／ピンチでズーム")
        hint.textColor = .secondaryLabelColor
        let root = NSView()
        window.contentView = root
        for view in [bar, canvas, hint] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            bar.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -12),
            canvas.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 8),
            canvas.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            hint.topAnchor.constraint(equalTo: canvas.bottomAnchor, constant: 6),
            hint.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            hint.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8)
        ])
        canvas.onHover = { [weak self] label in self?.status.stringValue = label }
        canvas.onCommit = { [weak self] previous in
            self?.remember(previous)
            self?.refreshTitle()
        }
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
        NSApp.activate(ignoringOtherApps: true)
        refreshPalette()
    }

    private func installMenu() {
        let main = NSMenu()
        func submenu(_ title: String, _ items: [(String, Selector, String, NSEvent.ModifierFlags)]) {
            let parent = NSMenuItem()
            let menu = NSMenu(title: title)
            parent.submenu = menu
            main.addItem(parent)
            for (title, action, key, flags) in items {
                let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
                item.target = self
                item.keyEquivalentModifierMask = flags
                menu.addItem(item)
            }
        }
        submenu("MapEdit", [("MapEdit を終了", #selector(quit), "q", [.command])])
        submenu("ファイル", [
            ("開く…", #selector(openFile), "o", [.command]),
            ("保存", #selector(save), "s", [.command]),
            ("名前を付けて保存…", #selector(saveAs), "s", [.command, .shift])
        ])
        submenu("編集", [
            ("元に戻す", #selector(undo), "z", [.command]),
            ("やり直す", #selector(redo), "z", [.command, .shift]),
            ("Godot 向けに配置をコピー", #selector(copyMap), "c", [.command]),
            ("配置を貼り付け", #selector(pasteMap), "v", [.command])
        ])
        submenu("表示", [("全体表示", #selector(fit), "0", [.command])])
        NSApp.mainMenu = main
    }

    private func refreshPalette() {
        category.removeAllItems()
        guard let map = canvas.document else {
            category.isEnabled = false
            variant.isEnabled = false
            return
        }
        let labels = ["TerrainTiles": "地形", "OneWayPlatforms": "片方向床", "GumPassBarriers": "バリア",
                      "GumAnchors": "ガムアンカー", "Spikes": "トゲ", "Foods": "食べ物", "MusicNotes": "音符"]
        categories = MapDocument.order.filter { map.layers[$0] != nil }
        category.addItems(withTitles: categories.map { labels[$0] ?? $0 })
        categories.append(contentsOf: map.markers.keys.sorted())
        for path in map.markers.keys.sorted() {
            let label = String(path.split(separator: "/").last ?? "")
            category.addItem(withTitle: label == "PlayerSpawn" ? "スタート" : label == "Exit" ? "ゴール" : label)
        }
        category.isEnabled = true
        selectCategory()
    }

    @objc private func selectCategory() {
        let index = category.indexOfSelectedItem
        guard categories.indices.contains(index), let map = canvas.document else { return }
        let selected = categories[index]
        variant.removeAllItems()
        variants = map.layers[selected]?.palette ?? []
        canvas.selectedKind = map.layers[selected] == nil ? nil : selected
        canvas.marker = map.markers[selected] == nil ? nil : selected
        let labels = map.layers[selected]?.labels ?? []
        variant.addItems(withTitles: variants.enumerated().map { index, id in
            let identifier = "\(id[0]) / \(id[1]),\(id[2]) / \(id[3])"
            guard labels.indices.contains(index), !labels[index].isEmpty else { return identifier }
            return "\(labels[index]) · \(identifier)"
        })
        variant.isEnabled = !variants.isEmpty
        selectVariant()
    }

    @objc private func selectVariant() {
        let index = variant.indexOfSelectedItem
        canvas.tile = variants.indices.contains(index) ? variants[index] : nil
        window.makeFirstResponder(canvas)
    }

    @objc private func fit() { canvas.fit() }
    @objc private func quit() { NSApp.terminate(nil) }
    @objc private func undo() { history.undo() }
    @objc private func redo() { history.redo() }

    private func remember(_ previous: MapDocument) {
        history.beginUndoGrouping()
        history.registerUndo(withTarget: self) { editor in
            guard let current = editor.canvas.document else { return }
            editor.remember(current)
            editor.canvas.document = previous
            editor.refreshTitle()
        }
        history.endUndoGrouping()
    }

    private func encode(_ map: MapDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var normalized = map
        normalized.cells.sort(by: Placement.ordered)
        return try encoder.encode(normalized)
    }

    private var dirty: Bool {
        guard let map = canvas.document else { return false }
        return (try? encode(map)) != baseline
    }

    private func refreshTitle() {
        let name = file?.lastPathComponent ?? canvas.document?.stage.split(separator: "/").last.map(String.init)
        window.title = name.map { "MapEdit — \($0)" } ?? "MapEdit"
        window.isDocumentEdited = dirty
    }

    private func replace(with data: Data, file: URL?) throws {
        var map = try JSONDecoder().decode(MapDocument.self, from: data)
        map.cells.sort(by: Placement.ordered)
        try map.validate()
        let normalized = try encode(map)
        guard allowReplacement() else { return }
        self.file = file
        baseline = normalized
        canvas.document = map
        history.removeAllActions()
        refreshPalette()
        refreshTitle()
        canvas.fit()
        window.makeFirstResponder(canvas)
    }

    @objc private func copyMap() {
        guard let map = canvas.document else { return }
        do {
            try map.validate()
            let data = try encode(map)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            guard pasteboard.setString(String(decoding: data, as: UTF8.self), forType: .string) else {
                throw MapError("クリップボードに書き込めませんでした。")
            }
            status.stringValue = "コピーしました"
        } catch { show(error) }
    }

    @objc private func pasteMap() {
        do {
            guard let value = NSPasteboard.general.string(forType: .string) else {
                throw MapError("クリップボードに配置データがありません。")
            }
            try replace(with: Data(value.utf8), file: nil)
        } catch { show(error) }
    }

    @objc private func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try replace(with: Data(contentsOf: url), file: url) } catch { show(error) }
    }

    @objc private func save() { _ = write(choosingFile: false) }
    @objc private func saveAs() { _ = write(choosingFile: true) }

    private func write(choosingFile: Bool) -> Bool {
        guard let map = canvas.document else { return false }
        var target = choosingFile ? nil : file
        if target == nil {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = "placements.mapedit.json"
            guard panel.runModal() == .OK else { return false }
            target = panel.url
        }
        guard let target else { return false }
        do {
            try map.validate()
            let data = try encode(map)
            try data.write(to: target, options: .atomic)
            baseline = data
            file = target
            refreshTitle()
            return true
        } catch {
            show(error)
            return false
        }
    }

    private func allowReplacement() -> Bool {
        guard dirty else { return true }
        let alert = NSAlert()
        alert.messageText = "編集中の配置を保存しますか？"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "キャンセル")
        alert.addButton(withTitle: "破棄")
        switch alert.runModal() {
        case .alertFirstButtonReturn: return write(choosingFile: false)
        case .alertThirdButtonReturn: return true
        default: return false
        }
    }

    private func show(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        allowReplacement() ? .terminateNow : .terminateCancel
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.terminate(nil)
        return false
    }
}

let app = NSApplication.shared
let editor = MapEdit()
app.setActivationPolicy(.regular)
app.delegate = editor
app.run()
