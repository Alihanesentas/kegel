import Foundation
import Testing
@testable import Core

struct ContentLoaderTests {
    /// A minimal but *valid* document. Individual tests override one field to
    /// prove that field is what makes the document unusable.
    static let validGuide = #"""
    {"title": {"en": "G"}, "intro": {"en": "I"}, "closing": {"en": "C"},
     "steps": [{"id": 1, "title": {"en": "S"}, "body": {"en": "B"}}]}
    """#

    private func json(
        schemaVersion: Int = 3,
        freeLevelLimit: Int = 1,
        weeklySessionGoal: Int = 5,
        lockedFeatures: String = #"["dimMode", "progress"]"#,
        muscleGuide: String = validGuide,
        levels: String = #"""
        [{"id": 1, "title": {"en": "T"}, "subtitle": {"en": "S"},
          "prepare": 5, "contract": 1, "hold": 0, "relax": 1,
          "reps": 1, "sets": 1, "restBetweenSets": 0}]
        """#
    ) -> Data {
        Data("""
        {"schemaVersion": \(schemaVersion), "freeLevelLimit": \(freeLevelLimit),
         "weeklySessionGoal": \(weeklySessionGoal), "lockedFeatures": \(lockedFeatures),
         "muscleGuide": \(muscleGuide), "levels": \(levels)}
        """.utf8)
    }

    @Test func loadsValidContent() {
        let schema = ContentLoader.load(json())
        #expect(schema.schemaVersion == 3)
        #expect(schema.levels.count == 1)
        #expect(schema.weeklySessionGoal == 5)
        #expect(!schema.muscleGuide.steps.isEmpty)
    }

    // MARK: Paid feature boundary

    //
    // CLAUDE.md section 6: which features are paid must be tunable from
    // content.json, so it can be changed after launch without a release.

    @Test func lockedFeaturesComeFromContent() {
        let schema = ContentLoader.load(json(lockedFeatures: #"["dimMode"]"#))
        #expect(schema.requiresSubscription(.dimMode))
        #expect(!schema.requiresSubscription(.progress))
    }

    @Test func everythingIsFreeWhenNothingIsLocked() {
        let schema = ContentLoader.load(json(lockedFeatures: "[]"))
        #expect(PaidFeature.allCases.allSatisfy { !schema.requiresSubscription($0) })
    }

    /// A newer content file may name a feature this build has never heard of.
    /// That must not invalidate the whole document.
    @Test func unknownLockedFeaturesAreIgnoredNotRejected() throws {
        let schema = try ContentLoader.decode(json(lockedFeatures: #"["dimMode", "timeTravel"]"#))
        #expect(schema.requiresSubscription(.dimMode))
        #expect(schema.lockedFeatures.count == 1)
    }

    @Test func missingLockedFeaturesKeyMeansNothingIsLocked() throws {
        let data = Data("""
        {"schemaVersion": 3, "freeLevelLimit": 1, "weeklySessionGoal": 5,
         "muscleGuide": \(Self.validGuide),
         "levels": [{"id": 1, "title": {"en": "T"}, "subtitle": {"en": "S"},
                     "prepare": 5, "contract": 1, "hold": 0, "relax": 1,
                     "reps": 1, "sets": 1, "restBetweenSets": 0}]}
        """.utf8)

        let schema = try ContentLoader.decode(data)
        #expect(schema.lockedFeatures.isEmpty)
    }

    // MARK: Muscle guide

    @Test func guideWithNoStepsIsRejected() {
        let empty = #"{"title": {"en": "G"}, "intro": {"en": "I"}, "closing": {"en": "C"}, "steps": []}"#
        #expect(throws: ContentLoadError.self) {
            try ContentLoader.decode(json(muscleGuide: empty))
        }
    }

    @Test func guideStepMissingBaseLanguageIsRejected() {
        let guide = #"""
        {"title": {"en": "G"}, "intro": {"en": "I"}, "closing": {"en": "C"},
         "steps": [{"id": 1, "title": {"tr": "S"}, "body": {"en": "B"}}]}
        """#
        #expect(throws: ContentLoadError.self) {
            try ContentLoader.decode(json(muscleGuide: guide))
        }
    }

    @Test func embeddedGuideIsTranslatedIntoTurkish() {
        let guide = ContentLoader.loadEmbedded().muscleGuide
        let turkish = Locale(identifier: "tr_TR")
        #expect(guide.title.resolved(for: turkish) != guide.title.resolved(for: Locale(identifier: "en_US")))
        #expect(guide.steps.allSatisfy { !$0.body.resolved(for: turkish).isEmpty })
    }

    @Test func malformedJSONFallsBackToEmbedded() {
        let schema = ContentLoader.load(Data("{ not valid json".utf8))
        #expect(schema.schemaVersion == ContentLoader.loadEmbedded().schemaVersion)
    }

    @Test func embeddedContentIsAlwaysValid() {
        let embedded = ContentLoader.loadEmbedded()
        #expect(embedded.schemaVersion > 0)
        #expect(!embedded.levels.isEmpty)
        #expect(embedded.levels.allSatisfy { $0.title.hasBaseLanguage })
    }

    // MARK: Rejected documents

    //
    // Each of these decodes fine as JSON but describes content the app can't
    // sensibly run, so it must be refused rather than shown to the user.

    @Test(arguments: [
        ("empty level list", #"[]"#),
        ("zero reps", #"""
        [{"id": 1, "title": {"en": "T"}, "subtitle": {"en": "S"}, "prepare": 5, "contract": 1,
          "hold": 0, "relax": 1, "reps": 0, "sets": 1, "restBetweenSets": 0}]
        """#),
        ("zero-length contraction", #"""
        [{"id": 1, "title": {"en": "T"}, "subtitle": {"en": "S"}, "prepare": 5, "contract": 0,
          "hold": 0, "relax": 1, "reps": 1, "sets": 1, "restBetweenSets": 0}]
        """#),
        ("duplicate level ids", #"""
        [{"id": 1, "title": {"en": "T"}, "subtitle": {"en": "S"}, "prepare": 5, "contract": 1,
          "hold": 0, "relax": 1, "reps": 1, "sets": 1, "restBetweenSets": 0},
         {"id": 1, "title": {"en": "T"}, "subtitle": {"en": "S"}, "prepare": 5, "contract": 1,
          "hold": 0, "relax": 1, "reps": 1, "sets": 1, "restBetweenSets": 0}]
        """#),
        ("title missing the base language", #"""
        [{"id": 1, "title": {"tr": "T"}, "subtitle": {"en": "S"}, "prepare": 5, "contract": 1,
          "hold": 0, "relax": 1, "reps": 1, "sets": 1, "restBetweenSets": 0}]
        """#)
    ])
    func invalidLevelsAreRejected(reason: String, levels: String) {
        #expect(throws: ContentLoadError.self, "should reject \(reason)") {
            try ContentLoader.decode(json(levels: levels))
        }
    }

    @Test func zeroSchemaVersionIsRejected() {
        #expect(throws: ContentLoadError.self) {
            try ContentLoader.decode(json(schemaVersion: 0))
        }
    }

    @Test func zeroWeeklyGoalIsRejected() {
        #expect(throws: ContentLoadError.self) {
            try ContentLoader.decode(json(weeklySessionGoal: 0))
        }
    }

    @Test func rejectedContentFallsBackToEmbeddedRatherThanFailing() {
        let schema = ContentLoader.load(json(levels: "[]"))
        #expect(!schema.levels.isEmpty)
        #expect(schema.schemaVersion == ContentLoader.loadEmbedded().schemaVersion)
    }

    // MARK: Free/paid boundary

    @Test func freeLimitComesFromContentNotCode() {
        let schema = ContentLoader.load(json(freeLevelLimit: 3))
        #expect(schema.isFree(levelID: 3))
        #expect(!schema.isFree(levelID: 4))
    }
}

struct LocalizedTextTests {
    @Test func resolvesTheRequestedLanguage() {
        let text = LocalizedText(["en": "Starter", "tr": "Başlangıç"])
        #expect(text.resolved(for: Locale(identifier: "tr_TR")) == "Başlangıç")
        #expect(text.resolved(for: Locale(identifier: "en_US")) == "Starter")
    }

    @Test func fallsBackToBaseLanguageForUnknownLocales() {
        let text = LocalizedText(["en": "Starter", "tr": "Başlangıç"])
        #expect(text.resolved(for: Locale(identifier: "de_DE")) == "Starter")
    }

    @Test func roundTripsThroughJSON() throws {
        let original = LocalizedText(["en": "Hold", "tr": "Tutuş"])
        let decoded = try JSONDecoder().decode(LocalizedText.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }
}
