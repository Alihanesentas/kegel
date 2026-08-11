import Foundation

/// Text that ships inside `content.json` in every supported language.
///
/// Level titles and exercise copy are *content*, not UI chrome — CLAUDE.md
/// section 5 requires them to be updatable without a release, so they can't
/// live in a String Catalog. Carrying every translation in the content file
/// keeps that property while still honouring section 1 (English base, Turkish
/// second) and section 8 (nothing user-visible is English-only).
///
/// Encoded shape is a plain language-code map: `{"en": "Starter", "tr": "Başlangıç"}`.
public struct LocalizedText: Codable, Hashable, Sendable {
    public static let baseLanguage = "en"

    private let values: [String: String]

    public init(_ values: [String: String]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String: String].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    /// True when the base-language string is present. `ContentLoader` rejects
    /// content missing it, so `resolved(for:)` can never come back empty.
    public var hasBaseLanguage: Bool {
        values[Self.baseLanguage]?.isEmpty == false
    }

    /// Best available string for `locale`, falling back to the base language.
    public func resolved(for locale: Locale = .current) -> String {
        if let code = locale.language.languageCode?.identifier, let match = values[code] {
            return match
        }
        return values[Self.baseLanguage] ?? ""
    }
}
