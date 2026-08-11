/// The guided introduction to locating the pelvic floor muscles.
///
/// This is exercise instruction, so it lives in `content.json` and can be
/// reworded without a release (CLAUDE.md section 5).
///
/// Content rule, not a style preference: these steps describe *how to perform
/// a movement*. They must never name a condition, promise an outcome, or
/// comment on the user's body — CLAUDE.md section 1. `ContentLoader` can't
/// enforce that, so it's on whoever edits the file.
public struct MuscleGuide: Codable, Hashable, Sendable {
    public let title: LocalizedText
    public let intro: LocalizedText
    public let steps: [Step]
    public let closing: LocalizedText

    public struct Step: Codable, Hashable, Sendable, Identifiable {
        public let id: Int
        public let title: LocalizedText
        public let body: LocalizedText

        public init(id: Int, title: LocalizedText, body: LocalizedText) {
            self.id = id
            self.title = title
            self.body = body
        }
    }

    public init(title: LocalizedText, intro: LocalizedText, steps: [Step], closing: LocalizedText) {
        self.title = title
        self.intro = intro
        self.steps = steps
        self.closing = closing
    }

    var isValid: Bool {
        title.hasBaseLanguage
            && intro.hasBaseLanguage
            && closing.hasBaseLanguage
            && !steps.isEmpty
            && steps.allSatisfy { $0.title.hasBaseLanguage && $0.body.hasBaseLanguage }
    }
}
