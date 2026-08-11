import Core
import Foundation
import Testing
@testable import RemoteContent

/// Serves canned responses so `refresh()` can be exercised without a network.
private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var shouldFail = false

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if Self.shouldFail {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = Self.responseData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func stubbedSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSession(configuration: configuration)
}

/// Content shaped like the real file, at an arbitrary schema version.
private func contentJSON(schemaVersion: Int) -> Data {
    Data("""
    {"schemaVersion": \(schemaVersion), "freeLevelLimit": 1, "weeklySessionGoal": 5,
     "levels": [{"id": 1, "title": {"en": "Remote"}, "subtitle": {"en": "S"},
                 "prepare": 5, "contract": 1, "hold": 0, "relax": 1,
                 "reps": 1, "sets": 1, "restBetweenSets": 0}]}
    """.utf8)
}

private func tempCacheURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("content-cache.json")
}

private func makeStore(cacheURL: URL) -> RemoteContentStore {
    RemoteContentStore(
        remoteURL: URL(string: "https://example.invalid/content.json") ?? URL(fileURLWithPath: "/"),
        cacheFileURL: cacheURL,
        session: stubbedSession()
    )
}

private func writeCache(_ data: Data, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(), withIntermediateDirectories: true
    )
    try data.write(to: url)
}

/// Serialized: the URL stub is process-wide, so parallel tests would clobber
/// each other's canned response.
@Suite(.serialized)
struct RemoteContentStoreTests {

    // MARK: Reading what's already on disk

    @Test func fallsBackToEmbeddedWhenNoCacheExists() async {
        let content = await makeStore(cacheURL: tempCacheURL()).currentContent()
        #expect(content.schemaVersion == ContentLoader.loadEmbedded().schemaVersion)
    }

    @Test func fallsBackToEmbeddedWhenTheCacheIsCorrupt() async throws {
        let url = tempCacheURL()
        try writeCache(Data("{ not valid json".utf8), to: url)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let content = await makeStore(cacheURL: url).currentContent()
        #expect(content.schemaVersion == ContentLoader.loadEmbedded().schemaVersion)
    }

    @Test func usesCachedContentWhenValid() async throws {
        let url = tempCacheURL()
        try writeCache(contentJSON(schemaVersion: 99), to: url)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let content = await makeStore(cacheURL: url).currentContent()
        #expect(content.schemaVersion == 99)
        #expect(content.levels.first?.title.resolved() == "Remote")
    }

    // MARK: Refreshing from the network
    //
    // CLAUDE.md section 5: a newer valid version wins, anything else is
    // silently ignored and the app keeps what it had.

    @Test func newerRemoteVersionIsCachedAndUsed() async throws {
        let url = tempCacheURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let newerVersion = ContentLoader.loadEmbedded().schemaVersion + 1
        StubURLProtocol.shouldFail = false
        StubURLProtocol.responseData = contentJSON(schemaVersion: newerVersion)

        let store = makeStore(cacheURL: url)
        await store.refresh()

        #expect(await store.currentContent().schemaVersion == newerVersion)
    }

    @Test func olderRemoteVersionIsIgnored() async throws {
        let url = tempCacheURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        StubURLProtocol.shouldFail = false
        StubURLProtocol.responseData = contentJSON(schemaVersion: 1)

        let store = makeStore(cacheURL: url)
        await store.refresh()

        // Embedded content is version 2, so a version 1 publish must not win.
        #expect(await store.currentContent().schemaVersion == ContentLoader.loadEmbedded().schemaVersion)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    /// The headline requirement: publishing a broken file must not break the app.
    @Test func invalidRemoteContentIsSilentlyIgnored() async throws {
        let url = tempCacheURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        StubURLProtocol.shouldFail = false
        StubURLProtocol.responseData = Data(#"{"schemaVersion": 999, "levels": "not an array"}"#.utf8)

        let store = makeStore(cacheURL: url)
        await store.refresh()

        #expect(await store.currentContent().schemaVersion == ContentLoader.loadEmbedded().schemaVersion)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func networkFailureLeavesExistingContentAlone() async throws {
        let url = tempCacheURL()
        try writeCache(contentJSON(schemaVersion: 99), to: url)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        StubURLProtocol.shouldFail = true
        StubURLProtocol.responseData = nil

        let store = makeStore(cacheURL: url)
        await store.refresh()

        #expect(await store.currentContent().schemaVersion == 99)
    }
}
