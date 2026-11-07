import Foundation

struct GridPoint: Hashable {
    let x: Int
    let y: Int
}

struct Placement: Codable, Equatable {
    let kind: String
    let x: Int
    let y: Int
    let tile: [Int]

    var point: GridPoint { GridPoint(x: x, y: y) }

    static func ordered(_ lhs: Placement, _ rhs: Placement) -> Bool {
        (lhs.kind, lhs.y, lhs.x) < (rhs.kind, rhs.y, rhs.x)
    }
}

struct Palette: Codable {
    let tileset: String
    let palette: [[Int]]
    let labels: [String]?
}

struct SourcePlacements: Codable {
    let cells: [Placement]
    let markers: [String: [Double]]
}

struct MapDocument: Codable {
    let version: Int
    let stage: String
    let width: Int
    let height: Int
    let tileSize: Int
    let base: String
    let layers: [String: Palette]
    var cells: [Placement]
    var markers: [String: [Double]]
    var source: SourcePlacements?

    static let order = ["TerrainTiles", "OneWayPlatforms", "GumPassBarriers",
                        "GumAnchors", "Spikes", "Foods", "Baguettes", "MusicNotes"]

    static let namedItemKinds: Set<String> = ["Foods", "Baguettes", "MusicNotes"]

    static let checkpointKind = "Checkpoints"
    static let checkpointPrefix = checkpointKind + "/"

    mutating func paintCheckpoints(in points: Set<GridPoint>, erase: Bool) {
        let size = Double(tileSize)
        var occupied: Set<GridPoint> = []
        for (path, position) in markers where path.hasPrefix(Self.checkpointPrefix) {
            let point = GridPoint(x: min(width - 1, Int(position[0] / size)),
                                  y: max(0, Int(ceil(position[1] / size)) - 1))
            if erase && points.contains(point) {
                markers.removeValue(forKey: path)
            } else {
                occupied.insert(point)
            }
        }
        guard !erase else { return }
        var number = 1
        for point in points.subtracting(occupied).sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
            while markers[Self.checkpointPrefix + "CheckpointMapEdit_\(number)"] != nil {
                number += 1
            }
            markers[Self.checkpointPrefix + "CheckpointMapEdit_\(number)"] = [
                (Double(point.x) + 0.5) * size, Double(point.y + 1) * size
            ]
            number += 1
        }
    }

    func contains(_ point: GridPoint) -> Bool {
        (0..<width).contains(point.x) && (0..<height).contains(point.y)
    }

    func validate() throws {
        let widths = ["res://scenes/stages/theater_stage.tscn": 160,
                      "res://scenes/stages/time_attack.tscn": 192]
        guard version == 1, widths[stage] == width, height == 24, tileSize == 32,
              base.count == 64, base.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }),
              layers["TerrainTiles"] != nil,
              Set(layers.keys).isSubset(of: Set(Self.order)),
              markers["PlacementMarkers/PlayerSpawn"] != nil, markers["PlacementMarkers/Exit"] != nil else {
            throw MapError("ステージ情報、形式バージョン、または必須の配置種別が不正です。")
        }
        for (name, layer) in layers {
            guard !layer.tileset.isEmpty, layer.palette.allSatisfy({ tile in
                tile.count == 4 && tile.allSatisfy { (0...Int(Int32.max)).contains($0) }
            }) else { throw MapError("タイルパレットが不正です: \(name)") }
        }
        var occupied: [String: Set<GridPoint>] = [:]
        for cell in cells {
            guard contains(cell.point), layers[cell.kind]?.palette.contains(cell.tile) == true,
                  occupied[cell.kind, default: []].insert(cell.point).inserted else {
                throw MapError("範囲外、重複、または未知のタイルがあります。")
            }
        }
        for (path, position) in markers {
            guard position.count == 2,
                  (0...Double(width * tileSize)).contains(position[0]),
                  (0...Double(height * tileSize)).contains(position[1]) else {
                throw MapError("マーカーの位置が不正です: \(path)")
            }
        }
    }
}

struct MapError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
