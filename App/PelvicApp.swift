import Features
import SwiftUI

@main
struct PelvicApp: App {
    @State private var model = AppEnvironment.makeModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(model)
        }
    }
}
