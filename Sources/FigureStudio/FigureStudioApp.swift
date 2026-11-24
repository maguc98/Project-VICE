import SwiftUI

@main
struct FigureStudioApp: App {
    @State private var profile = BodyProfile.defaultProfile

    var body: some Scene {
        WindowGroup {
            ContentView(profile: $profile)
                .preferredColorScheme(.light)
        }
    }
}
