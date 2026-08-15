import SwiftUI

/// A thicker capsule progress bar with a visible track.
///
/// The stock `ProgressView` linear style renders as a ~4pt hairline that
/// reads as decoration rather than a data point a user glances at across the
/// room — out of step with the large-typography, high-contrast brief
/// (CLAUDE.md section 1). This keeps the same `ProgressView(value:)` API
/// call sites already use, just with a track you can actually see.
public struct AccentProgressViewStyle: ProgressViewStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(ColorToken.cardBorder)
                Capsule()
                    .fill(ColorToken.accent)
                    .frame(width: proxy.size.width * CGFloat(configuration.fractionCompleted ?? 0))
            }
        }
        .frame(height: 10)
    }
}

public extension ProgressViewStyle where Self == AccentProgressViewStyle {
    static var accentBar: AccentProgressViewStyle {
        AccentProgressViewStyle()
    }
}
