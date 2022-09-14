import SwiftUI
import MetalKit


// This is based on https://developer.apple.com/forums/thread/119112?answerId=654964022#654964022
struct MetalView: UIViewRepresentable {

    @EnvironmentObject var worldManager: WorldManager

    class Coordinator : NSObject, MTKViewDelegate {

        let arCoordinator  : ARCoordinator
        let parent         : MetalView

        init( _ parent: MetalView ) {
        
            self.arCoordinator  = ARCoordinator( worldManager : parent.worldManager, device: parent.worldManager.device )
            self.parent         = parent

            super.init()

            parent.worldManager.arCoordinator = arCoordinator
        }

        func mtkView( _ view: MTKView, drawableSizeWillChange size: CGSize ) {

            arCoordinator.mtkView( view, drawableSizeWillChange: size )
        }

        func draw( in view: MTKView ) {
            arCoordinator.draw( in: view )
        }
    }

    func makeCoordinator() -> Coordinator {
        
        return Coordinator( self )
    }

    func makeUIView( context: UIViewRepresentableContext<MetalView> ) -> MTKView {
    
        let mtkView = TouchMTKView()

        mtkView.delegate                 = context.coordinator
        mtkView.touchDelegate            = worldManager
        mtkView.preferredFramesPerSecond = 60
        mtkView.device                   = context.coordinator.arCoordinator.device
        mtkView.framebufferOnly          = true
        mtkView.clearColor               = MTLClearColor( red: 0, green: 0, blue: 0, alpha: 0 )
        mtkView.drawableSize             = mtkView.frame.size
        mtkView.enableSetNeedsDisplay    = false
        mtkView.depthStencilPixelFormat  = .depth32Float

        context.coordinator.arCoordinator.createPipelineStates( mtkView: mtkView )
        context.coordinator.mtkView( mtkView, drawableSizeWillChange: mtkView.frame.size )

        return mtkView
    }
    
    func updateUIView( _ uiView: MTKView, context: UIViewRepresentableContext<MetalView> ) {

    }
}
