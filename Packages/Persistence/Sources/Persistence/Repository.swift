// Storage abstractions so the app never talks to `FileManager`/JSON directly.
// Per CLAUDE.md section 2: `Codable` + JSON file behind these protocols, no
// SwiftData. Swapping the storage mechanism later is a single-file change.

/// A collection of items, e.g. session history.
public protocol Repository<Item>: Sendable {
    associatedtype Item: Codable & Sendable

    func loadAll() async throws -> [Item]
    func save(_ items: [Item]) async throws
}

/// A single value that always exists, e.g. user preferences. Reading before
/// anything has been written yields the default rather than an error.
public protocol ValueStore<Value>: Sendable {
    associatedtype Value: Codable & Sendable

    func load() async -> Value
    func save(_ value: Value) async throws
}
