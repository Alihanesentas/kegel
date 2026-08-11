import Foundation

/// Generic JSON-file-backed `Repository`. A missing file is treated as an
/// empty collection — this is the state on first launch, not an error.
public actor JSONFileRepository<Item: Codable & Sendable>: Repository {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func loadAll() throws -> [Item] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Item].self, from: data)
    }

    public func save(_ items: [Item]) throws {
        let data = try JSONEncoder().encode(items)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}
