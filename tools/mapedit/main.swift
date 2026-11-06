import AppKit

private struct SavedSession: Codable {
    let map: MapDocument
    let baseline: Data?
    let file: URL?
}

private final class PaletteGrid: NSGridView {
    override var isFlipped: Bool { true }
}

final class MapEdit: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1180, height: 620),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                                  backing: .buffered, defer: false)
    private let canvas = Canvas()
    private let palette = PaletteGrid()
    private let paletteScroll = NSScrollView()
    private var categoryButtons: [NSButton] = []
    private let variant = NSPopUpButton(frame: .zero, pullsDown: false)
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

        variant.target = self
        variant.action = #selector(selectVariant)
        let fitButton = NSButton(title: "全体表示", target: self, action: #selector(fit))
        let categoryLabel = NSTextField(labelWithString: "配置種別")
        let variantLabel = NSTextField(labelWithString: "タイル")
        variant.bezelStyle = .rounded
        variant.isBordered = true
        palette.columnSpacing = 6
        palette.rowSpacing = 4
        paletteScroll.documentView = palette
        paletteScroll.hasVerticalScroller = true
        paletteScroll.autohidesScrollers = true
        paletteScroll.drawsBackground = false
        let tools = NSStackView(views: [categoryLabel, paletteScroll, variantLabel, variant, fitButton, status])
        tools.orientation = .vertical
        tools.alignment = .leading
        tools.spacing = 8
        let sidebar = NSBox()
        sidebar.boxType = .custom
        sidebar.fillColor = .controlBackgroundColor
        sidebar.contentViewMargins = .zero
        sidebar.contentView?.addSubview(tools)
        tools.translatesAutoresizingMaskIntoConstraints = false

        let hint = NSTextField(labelWithString: "左ドラッグで配置・移動　右ドラッグで消去　Space + ドラッグでパン　ホイール／ピンチでズーム")
        hint.textColor = .secondaryLabelColor
        hint.lineBreakMode = .byTruncatingTail
        let root = NSView()
        root.wantsLayer = true
        window.contentView = root
        let minimap = Minimap()
        minimap.canvas = canvas
        minimap.toolTip = "ミニマップをクリックして表示位置を移動"
        canvas.onOverviewChange = { [weak minimap] in minimap?.needsDisplay = true }
        for view in [canvas, sidebar, minimap, hint] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            sidebar.topAnchor.constraint(equalTo: root.topAnchor),
            sidebar.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            sidebar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            sidebar.widthAnchor.constraint(equalToConstant: 270),
            tools.topAnchor.constraint(equalTo: sidebar.topAnchor, constant: 12),
            tools.bottomAnchor.constraint(equalTo: sidebar.bottomAnchor, constant: -12),
            tools.leadingAnchor.constraint(equalTo: sidebar.leadingAnchor, constant: 12),
            tools.trailingAnchor.constraint(equalTo: sidebar.trailingAnchor, constant: -12),
            paletteScroll.widthAnchor.constraint(equalTo: tools.widthAnchor),
            variant.widthAnchor.constraint(equalTo: tools.widthAnchor),
            canvas.topAnchor.constraint(equalTo: root.topAnchor),
            canvas.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: sidebar.leadingAnchor),
            minimap.topAnchor.constraint(equalTo: canvas.bottomAnchor),
            minimap.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
            minimap.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
            minimap.heightAnchor.constraint(equalToConstant: 84),
            hint.topAnchor.constraint(equalTo: minimap.bottomAnchor, constant: 6),
            hint.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            hint.trailingAnchor.constraint(equalTo: canvas.trailingAnchor, constant: -12),
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
        restoreSession()
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
        while palette.numberOfRows > 0 { palette.removeRow(at: palette.numberOfRows - 1) }
        categoryButtons.removeAll()
        palette.setFrameSize(.zero)
        guard let map = canvas.document else {
            variant.isEnabled = false
            return
        }
        let labels = ["TerrainTiles": "地形", "OneWayPlatforms": "片方向床", "GumPassBarriers": "バリア",
                      "GumAnchors": "ガムアンカー", "Spikes": "トゲ", "Foods": "食べ物", "MusicNotes": "音符"]
        categories = MapDocument.order.filter { map.layers[$0] != nil } + map.markers.keys.sorted()
        for (index, kind) in categories.enumerated() {
            let name = String(kind.split(separator: "/").last ?? "")
            let title = labels[kind] ?? (name == "PlayerSpawn" ? "スタート" : name == "Exit" ? "ゴール" : name)
            let button = NSButton(title: title, target: self, action: #selector(chooseCategory(_:)))
            let label = NSMutableAttributedString(string: "■  " + title)
            label.addAttribute(.foregroundColor, value: Canvas.placementColor(for: kind),
                               range: NSRange(location: 0, length: 1))
            button.attributedTitle = label
            button.tag = index
            button.toolTip = title
            button.setButtonType(.pushOnPushOff)
            button.bezelStyle = .rounded
            button.lineBreakMode = .byTruncatingTail
            button.widthAnchor.constraint(equalToConstant: 112).isActive = true
            categoryButtons.append(button)
        }
        let columns = 2
        for start in stride(from: 0, to: categoryButtons.count, by: columns) {
            let end = min(start + columns, categoryButtons.count)
            palette.addRow(with: Array(categoryButtons[start..<end]))
        }
        palette.setFrameSize(palette.fittingSize)
        palette.scroll(.zero)
        selectCategory(at: 0)
    }

    @objc private func chooseCategory(_ sender: NSButton) {
        selectCategory(at: sender.tag)
    }

    private func selectCategory(at index: Int) {
        guard categories.indices.contains(index), let map = canvas.document else { return }
        for button in categoryButtons { button.state = button.tag == index ? .on : .off }
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
        load(map, file: file, baseline: normalized)
    }

    private func load(_ map: MapDocument, file: URL?, baseline: Data?) {
        self.file = file
        self.baseline = baseline
        canvas.document = map
        history.removeAllActions()
        refreshPalette()
        refreshTitle()
        window.contentView?.layoutSubtreeIfNeeded()
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

    private func sessionURL() throws -> URL {
        try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                    appropriateFor: nil, create: false)
            .appendingPathComponent("BungeeGumMapEdit", isDirectory: true)
            .appendingPathComponent("session.json")
    }

    private func restoreSession() {
        do {
            let url = try sessionURL()
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let session = try JSONDecoder().decode(SavedSession.self, from: Data(contentsOf: url))
            try session.map.validate()
            var map = session.map
            map.cells.sort(by: Placement.ordered)
            let file = session.file.flatMap { url in
                url.isFileURL && FileManager.default.fileExists(atPath: url.path) ? url : nil
            }
            load(map, file: file, baseline: session.baseline)
        } catch {
            show(MapError("前回の作業を復元できませんでした。\n\(error.localizedDescription)"))
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let map = canvas.document else { return .terminateNow }
        do {
            try map.validate()
            let url = try sessionURL()
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            let session = SavedSession(map: map, baseline: baseline, file: file)
            try JSONEncoder().encode(session).write(to: url, options: .atomic)
            return .terminateNow
        } catch {
            show(MapError("作業を自動保存できませんでした。\n\(error.localizedDescription)"))
            return .terminateCancel
        }
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
