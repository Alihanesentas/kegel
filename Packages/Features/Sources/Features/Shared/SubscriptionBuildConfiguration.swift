import Foundation

/// Compile-time switch for the "everything unlocked" build.
///
/// This exists for App Store review and trusted demo builds that must never
/// hit a paywall or a locked level. It is decided entirely at compile time
/// by the `SUBSCRIPTION_BUILD` Swift active compilation condition, which the
/// `Subscription Build` Xcode configuration defines (see `project.yml`).
/// A normal Debug or Release build never defines that flag, so
/// ``isSubscriptionBuild`` compiles down to the constant `false` and the
/// compiler is free to strip every branch guarded by it — no runtime cost,
/// no remote config, no feature flag service.
///
/// Nothing here touches ``SubscriptionStore`` directly. Callers (``AppModel``)
/// read this flag and drive the store from it, so this type stays a pure,
/// dependency-free compile-time constant.
public enum SubscriptionBuildConfiguration {
    /// Which configuration produced this binary. Deliberately not named
    /// after Debug/Release — this is orthogonal to that axis. A
    /// `Subscription Build` can be built in either optimization mode.
    public enum BuildConfig {
        case subscriptionBuild
        case normal
    }

    /// `true` when this binary was compiled with the `SUBSCRIPTION_BUILD`
    /// flag. Every entitlement check in the app treats this as "always
    /// subscribed, everything unlocked".
    public static var isSubscriptionBuild: Bool {
        #if SUBSCRIPTION_BUILD
            true
        #else
            false
        #endif
    }

    /// Convenience form of ``isSubscriptionBuild`` for call sites that want
    /// to switch on the configuration rather than branch on a `Bool`.
    public static var current: BuildConfig {
        isSubscriptionBuild ? .subscriptionBuild : .normal
    }
}
