import SwiftUI

@main
struct NebulaNXApp: App {
    @StateObject var V = Variable() // Shared across all scenes

    var body: some Scene {
        // Main coding window
        WindowGroup {
            ContentView()
                .environmentObject(V)
        }

        // Graphics rendering window
        Window("Graphics", id: "graphics") {
            Graphics()
                .environmentObject(V)
        }
    }
}
