import Foundation

/// Deployment settings that differ per environment or aren't decided yet.
///
/// Kept in one place so it's obvious what still needs filling in before the
/// app can ship, rather than having placeholders scattered through the code.
enum AppConfiguration {

    /// RevenueCat public SDK key.
    ///
    /// Read from the Info.plist so it isn't committed and can differ per
    /// build configuration. Set `REVENUECAT_API_KEY` in the build settings.
    /// While it's empty the app falls back to `NoOpSubscriptionProvider`,
    /// which offers nothing to buy — that's deliberate: a paywall with a dead
    /// button is an App Store rejection (Guideline 2.1).
    static var revenueCatAPIKey: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String
        return value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Entitlement that every paid plan grants, as configured in RevenueCat.
    static let entitlementID = "pro"

    /// Where the remotely updatable `content.json` lives.
    ///
    /// Not decided yet. Until a real CDN URL is set, content refresh is
    /// skipped entirely and the app runs on its embedded copy — which is the
    /// documented fallback anyway (CLAUDE.md section 5), so nothing breaks.
    static let remoteContentURL: URL? = nil
}
