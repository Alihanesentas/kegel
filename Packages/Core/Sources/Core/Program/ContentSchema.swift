import Foundation

/// Versioned shape of `content.json`. Level parameters and free/paid limits
/// live here, not in Swift code — see CLAUDE.md section 5.
public struct ContentSchema: Codable, Sendable {
    public let schemaVersion: Int
    public let freeLevelLimit: Int
    public let levels: [Level]

    public init(schemaVersion: Int, freeLevelLimit: Int, levels: [Level]) {
        self.schemaVersion = schemaVersion
        self.freeLevelLimit = freeLevelLimit
        self.levels = levels
    }

    public func level(id: Int) -> Level? {
        levels.first { $0.id == id }
    }
}
