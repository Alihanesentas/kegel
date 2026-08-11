import Core
import Foundation
import Testing
@testable import RemoteContent

struct RemoteContentStoreTests {

    private func tempCacheURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("content-cache.json")
    }

    @Test func fallsBackToEmbeddedWhenNoCacheExists() async {
        let store = RemoteContentStore(
            remoteURL: URL(string: "https://example.com/content.json")!,
            cacheFileURL: tempCacheURL()
        )

        let content = await store.currentContent()
        let embedded = ContentLoader.loadEmbedded()

        #expect(content.schemaVersion == embedded.schemaVersion)
        #expect(content.levels.count == embedded.levels.count)
    }

    @Test func fallsBackToEmbeddedWhenCacheIsCorrupt() async throws {
        let cacheURL = tempCacheURL()
        try FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("{ not valid json".utf8).write(to: cacheURL)

        let store = RemoteContentStore(
            remoteURL: URL(string: "https://example.com/content.json")!,
            cacheFileURL: cacheURL
        )

        let content = await store.currentContent()
        #expect(content.schemaVersion == ContentLoader.loadEmbedded().schemaVersion)

        try? FileManager.default.removeItem(at: cacheURL.deletingLastPathComponent())
    }

    @Test func usesCachedContentWhenValid() async throws {
        let cacheURL = tempCacheURL()
        try FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let json = Data("""
        {"schemaVersion": 99, "freeLevelLimit": 1, "levels": [
            {"id": 1, "title": "T", "subtitle": "S", "contract": 1, "hold": 0, "relax": 1, "reps": 1, "sets": 1, "restBetweenSets": 0}
        ]}
        """.utf8)
        try json.write(to: cacheURL)

        let store = RemoteContentStore(
            remoteURL: URL(string: "https://example.com/content.json")!,
            cacheFileURL: cacheURL
        )

        let content = await store.currentContent()
        #expect(content.schemaVersion == 99)

        try? FileManager.default.removeItem(at: cacheURL.deletingLastPathComponent())
    }
}
