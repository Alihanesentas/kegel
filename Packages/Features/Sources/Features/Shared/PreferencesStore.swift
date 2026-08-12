import Foundation
import Observation
import Persistence

/// Observable wrapper around persisted `UserPreferences`.
@MainActor
@Observable
public final class PreferencesStore {
    public private(set) var preferences: UserPreferences
    public private(set) var isLoaded = false

    private let store: any ValueStore<UserPreferences>

    public init(store: any ValueStore<UserPreferences>, initial: UserPreferences = UserPreferences()) {
        self.store = store
        preferences = initial
    }

    public func load() async {
        preferences = await store.load()
        isLoaded = true
        // First launch: persist immediately so the anonymous ID shown in
        // Settings stays stable across relaunches.
        try? await store.save(preferences)
    }

    public func update(_ mutate: (inout UserPreferences) -> Void) async {
        var updated = preferences
        mutate(&updated)
        preferences = updated
        try? await store.save(updated)
    }
}
