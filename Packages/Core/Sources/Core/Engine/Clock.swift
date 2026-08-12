import Foundation

/// Injected time source. Production uses `SystemClock`; tests use `TestClock`
/// so phase timing can be verified without waiting on real time.
public protocol Clock: Sendable {
    func now() -> Date
}

public struct SystemClock: Clock {
    public init() {}
    public func now() -> Date {
        Date()
    }
}

/// Test double with manually advanced time. Never sleeps.
public final class TestClock: Clock, @unchecked Sendable {
    private var current: Date

    public init(startingAt date: Date = Date(timeIntervalSince1970: 0)) {
        current = date
    }

    public func now() -> Date {
        current
    }

    public func advance(by seconds: TimeInterval) {
        current = current.addingTimeInterval(seconds)
    }
}
