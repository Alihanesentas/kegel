import Foundation
import Testing
@testable import Core

struct ContentLoaderTests {

    @Test func loadsValidContent() {
        let json = """
        {"schemaVersion": 2, "freeLevelLimit": 1, "levels": [
            {"id": 1, "title": "T", "subtitle": "S", "contract": 1, "hold": 0, "relax": 1, "reps": 1, "sets": 1, "restBetweenSets": 0}
        ]}
        """.data(using: .utf8)!

        let schema = ContentLoader.load(json)
        #expect(schema.schemaVersion == 2)
        #expect(schema.levels.count == 1)
    }

    @Test func malformedJSONFallsBackToEmbedded() {
        let garbage = Data("{ not valid json".utf8)

        let schema = ContentLoader.load(garbage)
        let embedded = ContentLoader.loadEmbedded()

        #expect(schema.schemaVersion == embedded.schemaVersion)
        #expect(schema.levels.count == embedded.levels.count)
    }

    @Test func validJSONWithEmptyLevelsFallsBackToEmbedded() {
        let json = Data("""
        {"schemaVersion": 1, "freeLevelLimit": 0, "levels": []}
        """.utf8)

        let schema = ContentLoader.load(json)
        let embedded = ContentLoader.loadEmbedded()

        #expect(!schema.levels.isEmpty)
        #expect(schema.schemaVersion == embedded.schemaVersion)
    }

    @Test func zeroSchemaVersionIsInvalid() {
        let json = Data("""
        {"schemaVersion": 0, "freeLevelLimit": 0, "levels": [
            {"id": 1, "title": "T", "subtitle": "S", "contract": 1, "hold": 0, "relax": 1, "reps": 1, "sets": 1, "restBetweenSets": 0}
        ]}
        """.utf8)

        #expect(throws: ContentLoadError.self) {
            try ContentLoader.decode(json)
        }
    }

    @Test func embeddedContentIsAlwaysValid() {
        let embedded = ContentLoader.loadEmbedded()
        #expect(embedded.schemaVersion > 0)
        #expect(!embedded.levels.isEmpty)
    }
}
