import SwiftUI

@main
struct ARWithMetalAndSwiftUIApp: App {

    let worldManager : WorldManager!
    
    init() {
        worldManager = WorldManager( device: MTLCreateSystemDefaultDevice()! )
    }

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject( worldManager )
        }
    }
}

