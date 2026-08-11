import Foundation

public enum ContentLoadError: Error, Equatable {
    case decodingFailed
    case invalidSchema
}

/// Parses and validates `content.json`. Content that fails validation is
/// never allowed to reach the app — `load(_:)` silently falls back to the
/// bundled copy so a broken publish to the CDN can't break a running app.
public enum ContentLoader {

    /// Decodes and validates raw data, throwing on any problem. Callers that
    /// need to know *whether* the data was usable (e.g. `RemoteContent`,
    /// deciding whether to cache it) should use this.
    public static func decode(_ data: Data) throws -> ContentSchema {
        let schema: ContentSchema
        do {
            schema = try JSONDecoder().decode(ContentSchema.self, from: data)
        } catch {
            throw ContentLoadError.decodingFailed
        }
        guard isValid(schema) else {
            throw ContentLoadError.invalidSchema
        }
        return schema
    }

    /// Decodes data, falling back to the embedded copy on any failure. Never throws.
    public static func load(_ data: Data) -> ContentSchema {
        (try? decode(data)) ?? loadEmbedded()
    }

    /// The copy shipped inside the app bundle — always available, no network required.
    public static func loadEmbedded() -> ContentSchema {
        guard let decoded = try? decode(embeddedData) else {
            fatalError("Embedded content.json is missing or invalid — this is a build-time bug")
        }
        return decoded
    }

    /// A level that renders as gibberish or runs for zero seconds is worse
    /// than no update at all, so structural sanity is checked here rather
    /// than trusted from the wire.
    private static func isValid(_ schema: ContentSchema) -> Bool {
        guard schema.schemaVersion > 0,
              schema.weeklySessionGoal > 0,
              schema.freeLevelLimit >= 0,
              !schema.levels.isEmpty,
              Set(schema.levels.map(\.id)).count == schema.levels.count else {
            return false
        }
        return schema.levels.allSatisfy(isValid)
    }

    private static func isValid(_ level: Level) -> Bool {
        level.reps > 0
            && level.sets > 0
            && level.contract > 0
            && level.relax > 0
            && level.hold >= 0
            && level.prepare >= 0
            && level.restBetweenSets >= 0
            && level.title.hasBaseLanguage
            && level.subtitle.hasBaseLanguage
    }

    private static var embeddedData: Data {
        guard let url = Bundle.module.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Embedded content.json is missing from the Core bundle — this is a build-time bug")
        }
        return data
    }
}
