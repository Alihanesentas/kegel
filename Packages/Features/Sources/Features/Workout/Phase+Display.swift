import Core
import SwiftUI

/// Presentation for `Phase`. Kept out of `Core`, which stays free of display
/// concerns and of user-visible strings.
extension Phase {
    /// Looked up from this package's String Catalog via the phase's stable key.
    var label: LocalizedStringKey {
        LocalizedStringKey(localizationKey)
    }
}
