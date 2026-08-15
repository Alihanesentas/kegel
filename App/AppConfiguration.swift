import Foundation

/// Deployment settings that differ per environment or aren't decided yet.
///
/// Kept in one place so it's obvious what still needs filling in before the
/// app can ship, rather than having placeholders scattered through the code.
enum AppConfiguration {
    /// RevenueCat public SDK key for real purchase validation.
    ///
    /// **What it is:**
    /// A public SDK key from RevenueCat (https://app.revenuecat.io) that allows
    /// the app to validate App Store receipts and manage subscriptions.
    /// Format: `appl_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
    ///
    /// **Security note:**
    /// This is a PUBLIC SDK key (safe to commit), not a Secret key (server-only).
    /// It's read from Info.plist to allow different keys per build configuration.
    ///
    /// **Deployment:**
    /// 1. Create account at https://app.revenuecat.io
    /// 2. Set up iOS app in RevenueCat dashboard
    /// 3. Go to Settings → Projects → Your Project → API Keys
    /// 4. Copy the iOS API key (starts with `appl_`)
    /// 5. Set REVENUECAT_API_KEY in build settings:
    ///    - Via CI/CD secret: `export REVENUECAT_API_KEY=appl_xxx`
    ///    - Via Config/Secrets.xcconfig (gitignored): `REVENUECAT_API_KEY = appl_xxx`
    ///    - Via project.yml build settings
    /// 6. Build and run — purchases will now work
    ///
    /// **Current state:**
    /// If empty, app falls back to `NoOpSubscriptionProvider` (no purchases).
    /// This prevents App Store rejection (Guideline 2.1: no dead buttons).
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
