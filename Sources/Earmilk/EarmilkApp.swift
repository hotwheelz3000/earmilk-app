import SwiftUI

@main
struct EarmilkApp: App {
    init() {
        AppLog.installCrashHandlers()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
