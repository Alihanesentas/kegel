import Foundation

/// Generic JSON-file-backed `ValueStore`.
///
/// A missing or unreadable file yields `defaultValue` instead of throwing:
/// that's the first-launch state, and a corrupt preferences file should not
/// stop the app from opening. Writes still throw so callers can surface a
/// genuine save failure.
public actor JSONFileStore<Value: Codable & Sendable>: ValueStore {
    private let fileURL: URL
    private let defaultValue: @Sendable () -> Value

    public init(fileURL: URL, defaultValue: @escaping @Sendable () -> Value) {
        self.fileURL = fileURL
        self.defaultValue = defaultValue
    }

    public func load() async -> Value {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(Value.self, from: data) else {
            return defaultValue()
        }
        return decoded
    }

    public func save(_ value: Value) async throws {
        let data = try JSONEncoder().encode(value)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}
