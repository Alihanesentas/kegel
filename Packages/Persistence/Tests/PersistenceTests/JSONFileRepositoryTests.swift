import Foundation
import Testing
@testable import Persistence

private struct Item: Codable, Sendable, Equatable {
    let id: Int
    let name: String
}

struct JSONFileRepositoryTests {

    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("items.json")
    }

    @Test func missingFileLoadsAsEmpty() async throws {
        let repo = JSONFileRepository<Item>(fileURL: tempFileURL())
        let items = try await repo.loadAll()
        #expect(items.isEmpty)
    }

    @Test func saveThenLoadRoundTrips() async throws {
        let url = tempFileURL()
        let repo = JSONFileRepository<Item>(fileURL: url)
        let items = [Item(id: 1, name: "a"), Item(id: 2, name: "b")]

        try await repo.save(items)
        let loaded = try await repo.loadAll()

        #expect(loaded == items)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    @Test func saveOverwritesPreviousContent() async throws {
        let url = tempFileURL()
        let repo = JSONFileRepository<Item>(fileURL: url)

        try await repo.save([Item(id: 1, name: "a")])
        try await repo.save([Item(id: 2, name: "b")])
        let loaded = try await repo.loadAll()

        #expect(loaded == [Item(id: 2, name: "b")])
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
