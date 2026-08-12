import Core
import Foundation

/// Implements the loading order from CLAUDE.md section 5:
/// 1. the embedded bundled copy is always available (works offline on first launch)
/// 2. on launch, the remote file is fetched
/// 3. if the remote schema version is newer than the embedded one, it's used and cached
/// 4. content that fails validation is silently ignored — the app falls back to the
///    embedded copy, so a broken publish to the CDN can never crash a running app
public actor RemoteContentStore {
    private let remoteURL: URL
    private let cacheFileURL: URL
    private let session: URLSession

    public init(remoteURL: URL, cacheFileURL: URL, session: URLSession = .shared) {
        self.remoteURL = remoteURL
        self.cacheFileURL = cacheFileURL
        self.session = session
    }

    /// Best content available right now, without any network access: the
    /// cached remote copy if it's present and still valid, else embedded.
    public func currentContent() -> ContentSchema {
        guard let data = try? Data(contentsOf: cacheFileURL),
              let cached = try? ContentLoader.decode(data)
        else {
            return ContentLoader.loadEmbedded()
        }
        return cached
    }

    /// Fetches the remote catalog and caches it only if it validates and is
    /// newer than the embedded copy. Never throws — network or content
    /// problems just mean the app keeps using what it already has.
    public func refresh() async {
        guard let (data, _) = try? await session.data(from: remoteURL),
              let remote = try? ContentLoader.decode(data) else { return }

        let embedded = ContentLoader.loadEmbedded()
        guard remote.schemaVersion > embedded.schemaVersion else { return }

        try? FileManager.default.createDirectory(
            at: cacheFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: cacheFileURL, options: .atomic)
    }
}
