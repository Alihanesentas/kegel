/// Storage abstraction so the app never talks to `FileManager`/JSON directly.
/// Per CLAUDE.md section 2: `Codable` + JSON file behind this protocol, no SwiftData.
/// Swapping the storage mechanism later is a single-file change.
public protocol Repository<Item>: Sendable {
    associatedtype Item: Codable & Sendable

    func loadAll() async throws -> [Item]
    func save(_ items: [Item]) async throws
}
