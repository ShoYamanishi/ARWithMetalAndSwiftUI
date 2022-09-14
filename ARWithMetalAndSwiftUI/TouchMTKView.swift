import Foundation
import MetalKit

protocol TouchMTKViewDelegate {
    func touchesBegan( location: CGPoint, size: CGRect )
    func touchesMoved( location: CGPoint, size: CGRect )
    func touchesEnded( location: CGPoint, size: CGRect )
}


// Decorator to MTKView in order to forward touches to the delegate
class TouchMTKView: MTKView {

    var touchDelegate : TouchMTKViewDelegate?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 0 {
            let loc = touches.first!.location( in: self )
            touchDelegate?.touchesBegan( location: loc, size: self.frame )
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 0 {
            let loc = touches.first!.location( in: self )
            touchDelegate?.touchesMoved( location: loc, size: self.frame )
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 0 {
            let loc = touches.first!.location( in: self )
            touchDelegate?.touchesEnded( location: loc, size: self.frame )
        }
    }
}
