import SwiftUI

struct ContentView: View {

    @EnvironmentObject var worldManager: WorldManager

    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {

        if verticalSizeClass == .compact {
            HStack {
                MetalView().padding()
                Slider(value: $worldManager.planeWidth, in: 0.01...1.0)
                Text("Plane width \( worldManager.planeWidth * 100.0, specifier: "%.0f")) [cm].")
                Text("Number of Planes: \( worldManager.numOfPlanes)")
            }

        } else {
            VStack(alignment: .center) {
                MetalView().padding()
                Slider(value: $worldManager.planeWidth, in: 0.01...1.0).padding()
                Text("Plane width \( worldManager.planeWidth * 100.0, specifier: "%.0f") [cm].").padding()
                Text("Number of Planes: \( worldManager.numOfPlanes)")
            }
        }
    }
}
