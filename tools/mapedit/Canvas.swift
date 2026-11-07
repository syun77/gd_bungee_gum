import AppKit

struct PlacementStyle: Codable {
    let name: String
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let shortcut: String?
    let outlineRGB: [CGFloat]?

    init(name: String, color: NSColor, shortcut: String? = nil, outlineColor: NSColor? = nil) {
        self.name = name
        self.shortcut = shortcut
        let outline = outlineColor?.usingColorSpace(.sRGB)
        outlineRGB = outline.map { [$0.redComponent, $0.greenComponent, $0.blueComponent] }
        let rgb = color.usingColorSpace(.sRGB) ?? .black
        red = rgb.redComponent
        green = rgb.greenComponent
        blue = rgb.blueComponent
    }

    var outlineColor: NSColor? {
        guard let rgb = outlineRGB, rgb.count == 3 else { return nil }
        return NSColor(srgbRed: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
    }

    var color: NSColor { NSColor(srgbRed: red, green: green, blue: blue, alpha: 1) }
}

struct MapCamera: Codable {
    let zoom: CGFloat
    let origin: CGPoint
}

final class Canvas: NSView {
    var document: MapDocument? { didSet { refreshView() } }
    var placementStyles: [String: PlacementStyle] = [:] { didSet { refreshView() } }
    var onPlacementShortcut: ((String) -> Bool)?
    var onOverviewChange: (() -> Void)?
    var selectedKind: String? { didSet { needsDisplay = true } }
    var tile: [Int]?
    var marker: String? { didSet { needsDisplay = true } }
    var onCommit: ((MapDocument) -> Void)?
    var onHover: ((String) -> Void)?

    private var zoom: CGFloat = 0.3
    private var origin = CGPoint(x: 16, y: 16)
    private var start: MapDocument?
    private var previous: GridPoint?
    private var brush: Set<GridPoint> = []
    private var panning = false
    private var space = false
    private var tracking: NSTrackingArea?
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    private var step: CGFloat { CGFloat(document?.tileSize ?? 32) * zoom }

    private static let colors: [String: NSColor] = [
        MapDocument.breakableKind: .systemOrange, "TerrainTiles": .systemBrown, "OneWayPlatforms": .systemTeal,
        "GumPassBarriers": .systemCyan, "GumAnchors": .systemGreen,
        "Spikes": .systemRed, "GumBoxes": .systemMint, "Foods": .systemOrange, "Baguettes": .systemYellow, "MusicNotes": .systemPurple
    ]

    private static func routeMarkerColor(for path: String) -> NSColor? {
        switch path {
        case "PlacementMarkers/PlayerSpawn": return .systemGreen
        case "PlacementMarkers/Exit": return .systemPink
        default: return path == MapDocument.checkpointKind || path.hasPrefix(MapDocument.checkpointPrefix) ? .systemOrange : nil
        }
    }

    func placementStyle(for kind: String) -> PlacementStyle? {
        placementStyles[kind.hasPrefix(MapDocument.checkpointPrefix) ? MapDocument.checkpointKind : kind]
    }

    func placementColor(for kind: String) -> NSColor {
        placementStyle(for: kind)?.color ?? Self.colors[kind] ?? Self.routeMarkerColor(for: kind) ?? .systemBlue
    }

    func placementColor(for kind: String, tile: [Int]?) -> NSColor {
        placementColor(for: MapDocument.placementCategory(kind: kind, tile: tile))
    }

    func drawPlacementOutline(in rect: CGRect, kind: String, tile: [Int]? = nil, oval: Bool = false) {
        let category = MapDocument.placementCategory(kind: kind, tile: tile)
        guard let color = placementStyle(for: category)?.outlineColor else { return }
        let width = min(2, min(rect.width, rect.height) / 3)
        guard width > 0 else { return }
        color.setStroke()
        let inset = rect.insetBy(dx: width / 2, dy: width / 2)
        let path = oval ? NSBezierPath(ovalIn: inset) : NSBezierPath(rect: inset)
        path.lineWidth = width
        path.stroke()
    }

    static func placementRect(in cell: CGRect, kind: String) -> CGRect {
        guard kind == "GumAnchors" || MapDocument.namedItemKinds.contains(kind) else { return cell }
        return cell.insetBy(dx: cell.width * 0.1, dy: cell.height * 0.1)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero, options: [.activeInKeyWindow, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        tracking = area
    }

    var camera: MapCamera { MapCamera(zoom: zoom, origin: origin) }

    func restoreCamera(_ camera: MapCamera?) {
        guard let camera, camera.zoom.isFinite, camera.zoom > 0,
              camera.origin.x.isFinite, camera.origin.y.isFinite else {
            fit()
            return
        }
        zoom = camera.zoom
        origin = camera.origin
        refreshView()
    }

    var visibleMapRect: CGRect {
        CGRect(x: (bounds.minX - origin.x) / zoom, y: (bounds.minY - origin.y) / zoom,
               width: bounds.width / zoom, height: bounds.height / zoom)
    }

    func centerMap(on point: CGPoint) {
        origin = CGPoint(x: bounds.midX - point.x * zoom, y: bounds.midY - point.y * zoom)
        refreshView()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        onOverviewChange?()
    }

    private func refreshView() {
        needsDisplay = true
        onOverviewChange?()
    }

    func fit() {
        guard let document, bounds.width > 32, bounds.height > 32 else { return }
        zoom = min((bounds.width - 32) / CGFloat(document.width * document.tileSize),
                   (bounds.height - 32) / CGFloat(document.height * document.tileSize))
        origin = CGPoint(x: 16, y: 16)
        refreshView()
    }

    private func rect(_ point: GridPoint) -> CGRect {
        CGRect(x: origin.x + CGFloat(point.x) * step, y: origin.y + CGFloat(point.y) * step,
               width: step, height: step)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSBezierPath(rect: bounds).addClip()
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
        guard let document else {
            ("Godot で配置をコピーして ⌘V" as NSString).draw(at: CGPoint(x: 20, y: 20),
                withAttributes: [.foregroundColor: NSColor.labelColor, .font: NSFont.systemFont(ofSize: 16)])
            return
        }

        let map = CGRect(origin: origin, size: CGSize(width: CGFloat(document.width) * step,
                                                       height: CGFloat(document.height) * step))
        NSColor.controlBackgroundColor.setFill()
        map.fill()
        let grid = NSBezierPath()
        grid.lineWidth = 0.5
        for x in 0...document.width {
            let left = origin.x + CGFloat(x) * step
            grid.move(to: CGPoint(x: left, y: map.minY))
            grid.line(to: CGPoint(x: left, y: map.maxY))
        }
        for y in 0...document.height {
            let top = origin.y + CGFloat(y) * step
            grid.move(to: CGPoint(x: map.minX, y: top))
            grid.line(to: CGPoint(x: map.maxX, y: top))
        }
        NSColor.separatorColor.setStroke()
        grid.stroke()
        let occupied = Dictionary(grouping: document.cells, by: \.point)
        for (point, placements) in occupied {
            let cell = rect(point)
            guard dirtyRect.intersects(cell) else { continue }
            guard let visible = placements.first(where: { $0.kind == selectedKind }) ?? placements.last else {
                continue
            }
            placementColor(for: visible.kind, tile: visible.tile).setFill()
            let placement = Self.placementRect(in: cell, kind: visible.kind)
            placement.fill()
            drawPlacementOutline(in: placement, kind: visible.kind, tile: visible.tile)
            if step >= 24 && visible.kind == selectedKind {
                let id = visible.tile
                let label = MapDocument.namedItemKinds.contains(visible.kind) ? "\(id[3])" : "\(id[1]),\(id[2])"
                (label as NSString).draw(at: CGPoint(x: cell.minX + 2, y: cell.minY + 2),
                    withAttributes: [.foregroundColor: NSColor.white, .backgroundColor: NSColor.black.withAlphaComponent(0.65),
                                     .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .medium)])
            }
        }
        for path in document.markers.keys.sorted() {
            guard let position = document.markers[path] else { continue }
            let x = origin.x + position[0] * zoom
            let y = origin.y + position[1] * zoom
            let selected = path == marker || (selectedKind == MapDocument.checkpointKind
                && path.hasPrefix(MapDocument.checkpointPrefix))
            let label = placementStyle(for: path)?.name ?? String(path.split(separator: "/").last ?? "")
            let radius: CGFloat = Self.routeMarkerColor(for: path) == nil ? 4 : 7
            let dot = NSBezierPath(ovalIn: CGRect(x: x - radius, y: y - radius,
                                                 width: radius * 2, height: radius * 2))
            placementColor(for: path).setFill()
            dot.fill()
            drawPlacementOutline(in: dot.bounds, kind: path, oval: true)
            if selected {
                NSColor.systemYellow.setStroke()
                dot.stroke()
            }
            if path == marker || step >= 16 {
                (label as NSString).draw(at: CGPoint(x: x + radius + 2, y: y - 7),
                    withAttributes: [.foregroundColor: NSColor.labelColor, .backgroundColor: NSColor.controlBackgroundColor,
                                     .font: NSFont.systemFont(ofSize: 10)])
            }
        }
        if let hover, document.contains(hover) {
            let preview = NSBezierPath(rect: rect(hover).insetBy(dx: 1, dy: 1))
            if let selectedKind, tile != nil || selectedKind == MapDocument.checkpointKind {
                placementColor(for: selectedKind, tile: tile).withAlphaComponent(0.35).setFill()
                preview.fill()
                drawPlacementOutline(in: preview.bounds, kind: selectedKind, tile: tile)
            }
            NSColor.labelColor.setStroke()
            preview.stroke()
        }
    }

    private var hover: GridPoint?
    private func location(_ event: NSEvent) -> CGPoint { convert(event.locationInWindow, from: nil) }

    private func cell(at point: CGPoint) -> GridPoint? {
        guard let document else { return nil }
        let point = GridPoint(x: Int(floor((point.x - origin.x) / step)),
                              y: Int(floor((point.y - origin.y) / step)))
        return document.contains(point) ? point : nil
    }

    override func mouseMoved(with event: NSEvent) {
        hover = cell(at: location(event))
        onHover?(hover.map { "セル \($0.x), \($0.y)" } ?? "")
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        hover = nil
        onHover?("")
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 {
            space = true
            return
        }
        let modifiers: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        if event.modifierFlags.intersection(modifiers).isEmpty,
           let key = event.charactersIgnoringModifiers?.lowercased(), onPlacementShortcut?(key) == true {
            return
        }
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if event.keyCode == 49 { space = false } else { super.keyUp(with: event) }
    }

    override func resignFirstResponder() -> Bool {
        space = false
        return super.resignFirstResponder()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        panning = space
        if !panning { begin(event, erase: false) }
    }

    override func rightMouseDown(with event: NSEvent) { begin(event, erase: true) }
    override func mouseDragged(with event: NSEvent) {
        if panning { pan(event.deltaX, event.deltaY) } else { stroke(event, erase: false) }
    }
    override func rightMouseDragged(with event: NSEvent) { stroke(event, erase: true) }
    override func otherMouseDragged(with event: NSEvent) {
        if event.buttonNumber == 2 { pan(event.deltaX, event.deltaY) }
    }
    override func mouseUp(with event: NSEvent) { finish() }
    override func rightMouseUp(with event: NSEvent) { finish() }

    override func scrollWheel(with event: NSEvent) {
        if event.hasPreciseScrollingDeltas && !event.modifierFlags.contains(.command) {
            pan(event.scrollingDeltaX, event.scrollingDeltaY)
        } else {
            scale(by: exp(event.scrollingDeltaY * 0.045), at: location(event))
        }
    }

    override func magnify(with event: NSEvent) { scale(by: 1 + event.magnification, at: location(event)) }

    private func pan(_ x: CGFloat, _ y: CGFloat) {
        origin.x += x
        origin.y += y
        refreshView()
    }

    private func scale(by factor: CGFloat, at point: CGPoint) {
        let next = max(0.07, min(5, zoom * factor))
        origin = CGPoint(x: point.x - (point.x - origin.x) * next / zoom,
                         y: point.y - (point.y - origin.y) * next / zoom)
        zoom = next
        refreshView()
    }

    private func begin(_ event: NSEvent, erase: Bool) {
        start = document
        previous = nil
        brush.removeAll()
        stroke(event, erase: erase)
    }

    private func stroke(_ event: NSEvent, erase: Bool) {
        guard let start, let point = cell(at: location(event)) else {
            previous = nil
            return
        }
        var next = start
        next.source = document?.source
        if let marker, !erase, let position = start.markers[marker] {
            let size = Double(start.tileSize)
            next.markers[marker] = [
                Double(point.x) * size + position[0].truncatingRemainder(dividingBy: size),
                Double(point.y) * size + position[1].truncatingRemainder(dividingBy: size)
            ]
        } else if let selectedKind, erase || tile != nil || selectedKind == MapDocument.checkpointKind {
            let first = previous ?? point
            let dx = point.x - first.x
            let dy = point.y - first.y
            let length = max(1, abs(dx), abs(dy))
            for index in 0...length {
                let fraction = Double(index) / Double(length)
                brush.insert(GridPoint(x: first.x + Int((Double(dx) * fraction).rounded()),
                                       y: first.y + Int((Double(dy) * fraction).rounded())))
            }
            if selectedKind == MapDocument.checkpointKind {
                next.paintCheckpoints(in: brush, erase: erase)
            } else {
                next.cells.removeAll { $0.kind == selectedKind && brush.contains($0.point) }
                if !erase, let tile {
                    next.cells += brush.map { Placement(kind: selectedKind, x: $0.x, y: $0.y, tile: tile) }
                }
            }
        }
        previous = point
        next.cells.sort(by: Placement.ordered)
        document = next
    }

    private func finish() {
        defer { panning = false; start = nil }
        guard let start, let document, start.cells != document.cells || start.markers != document.markers else { return }
        onCommit?(start)
    }
}

final class Minimap: NSView {
    weak var canvas: Canvas?
    private var isNavigating = false
    override var isFlipped: Bool { true }

    private func mapFrame(for map: MapDocument) -> CGRect {
        let available = bounds.insetBy(dx: 8, dy: 8)
        guard available.width > 0, available.height > 0 else { return .zero }
        let scale = min(available.width / CGFloat(map.width), available.height / CGFloat(map.height))
        let size = CGSize(width: CGFloat(map.width) * scale, height: CGFloat(map.height) * scale)
        return CGRect(x: available.midX - size.width / 2, y: available.midY - size.height / 2,
                      width: size.width, height: size.height)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSBezierPath(rect: bounds).addClip()
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
        guard let canvas, let map = canvas.document else { return }
        let frame = mapFrame(for: map)
        guard !frame.isEmpty else { return }
        let step = frame.width / CGFloat(map.width)
        let scale = step / CGFloat(map.tileSize)
        NSColor.windowBackgroundColor.setFill()
        frame.fill()

        for cell in map.cells {
            canvas.placementColor(for: cell.kind, tile: cell.tile).setFill()
            let bounds = CGRect(x: frame.minX + CGFloat(cell.x) * step, y: frame.minY + CGFloat(cell.y) * step,
                                width: step, height: step)
            let placement = Canvas.placementRect(in: bounds, kind: cell.kind)
            placement.fill()
            canvas.drawPlacementOutline(in: placement, kind: cell.kind, tile: cell.tile)
        }
        for (path, point) in map.markers {
            canvas.placementColor(for: path).setFill()
            let x = frame.minX + point[0] * scale
            let y = frame.minY + point[1] * scale
            let markerRect = CGRect(x: x - 2, y: y - 2, width: 4, height: 4)
            markerRect.fill()
            canvas.drawPlacementOutline(in: markerRect, kind: path)
        }

        let visible = canvas.visibleMapRect
        let overview = CGRect(x: frame.minX + visible.minX * scale, y: frame.minY + visible.minY * scale,
                              width: visible.width * scale, height: visible.height * scale)
        let clipped = overview.intersection(frame)
        guard !clipped.isEmpty else { return }
        let outline = NSBezierPath(rect: clipped)
        NSColor.black.setStroke()
        outline.lineWidth = 3
        outline.stroke()
        NSColor.white.setStroke()
        outline.lineWidth = 1
        outline.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let canvas, let map = canvas.document, mapFrame(for: map).contains(point) else { return }
        isNavigating = true
        navigate(to: point)
        window?.makeFirstResponder(canvas)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isNavigating else { return }
        navigate(to: convert(event.locationInWindow, from: nil))
    }

    override func mouseUp(with event: NSEvent) {
        isNavigating = false
    }

    private func navigate(to point: CGPoint) {
        guard let canvas, let map = canvas.document else { return }
        let frame = mapFrame(for: map)
        guard !frame.isEmpty else { return }
        let scale = CGFloat(map.width * map.tileSize) / frame.width
        let x = min(max(point.x, frame.minX), frame.maxX)
        let y = min(max(point.y, frame.minY), frame.maxY)
        canvas.centerMap(on: CGPoint(x: (x - frame.minX) * scale, y: (y - frame.minY) * scale))
    }
}
