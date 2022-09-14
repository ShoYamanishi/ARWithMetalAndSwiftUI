import Foundation
import MetalKit
import SwiftUI
import ARKit

class WorldManager : ObservableObject, TouchMTKViewDelegate {

    let planeVertexData: [Float] = [

        // y
        // ^
        // | v2  v3
        // |
        // | v0  v1
        // +-------> x

        // x     y     z    w    u    v
        -0.5,  0.0, -0.5, 1.0, 0.0, 0.0, // v0
         0.5,  0.0, -0.5, 1.0, 1.0, 0.0, // v1
        -0.5,  0.0,  0.5, 1.0, 0.0, 1.0, // v2
         0.5,  0.0,  0.5, 1.0, 1.0, 1.0  // v3
    ]

    let planeIndexData: [Int32] = [ // Two adjacent triangles.
        0, 1, 3, 0, 3, 2
    ]

    var device:             MTLDevice!
    var arCoordinator:      ARCoordinator?
    var screenSize:         CGSize

    var pipelineState:      MTLRenderPipelineState!
    var depthState:         MTLDepthStencilState!

    var planeVertexBuffer:  MTLBuffer!
    var planeIndexBuffer:   MTLBuffer!
    let planeTexture:       MTLTexture!

    var coms:               [SIMD4<Float>]
    var viewMatrix:         float4x4
    var projectionMatrix:   float4x4

    @Published var planeWidth: Double = 0.01 // in meter
    @Published var numOfPlanes: Int = 0

    public init( device : MTLDevice ) {

        self.device            = device
        self.screenSize        = CGSize( width: 0.0, height: 0.0 )
        self.viewMatrix        = matrix_identity_float4x4
        self.projectionMatrix  = matrix_identity_float4x4
        self.planeVertexBuffer = device.makeBuffer(bytes: planeVertexData, length: planeVertexData.count * MemoryLayout<Float>.stride, options: [] )
        self.planeIndexBuffer  = device.makeBuffer(bytes: planeIndexData,  length: planeIndexData.count * MemoryLayout<Int32>.stride, options: [] )
        self.coms              = []
        self.depthState        = WorldManager.buildDepthStencilState( device: device )
        // pipelineState will be initialized when MTKView becomes available

        let textureLoader = MTKTextureLoader( device: device )
        do {
            planeTexture = try textureLoader.newTexture( name: "texture01", scaleFactor: 1.0, bundle: Bundle.main, options: nil )
        } catch {
            print("Texture not found.")
            planeTexture = nil
        }
    }

    static func buildDepthStencilState( device: MTLDevice ) -> MTLDepthStencilState? {

        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState( descriptor: descriptor )
    }

    func createPipelineStates( mtkView: MTKView ) {

        // Load all the shader files with a metal file extension in the project
        let defaultLibrary = device.makeDefaultLibrary()!
        
        let vertexFunction   = defaultLibrary.makeFunction(name: "vertex_barebone")!
        let fragmentFunction = defaultLibrary.makeFunction(name: "fragment_barebone")!
        
        // Create a vertex descriptor for our image plane vertex buffer
        let vertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // Texture coordinates.
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 16
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // Buffer Layout
        vertexDescriptor.layouts[0].stride = 24
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Create a pipeline state for rendering the captured image
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction                  = vertexFunction
        pipelineDescriptor.fragmentFunction                = fragmentFunction
        pipelineDescriptor.vertexDescriptor                = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat      = mtkView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat    = .invalid

        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }

    func updateScreenSizes( size: CGSize ) {
        screenSize = size
    }

    func updateViewAndProjectionMatrixForCamera( viewMatrix: float4x4, projectionMatrix: float4x4 ) {

        var coordinateSpaceTransform = matrix_identity_float4x4

        // MARK: - Coordinate conversion
        // Flip the Z axis to convert geometry from right handed to left handed
        // ARKit uses the right-hand coordinate system, while Metal uses the left-hand coordinate system.
        coordinateSpaceTransform.columns.2.z = -1.0

        self.viewMatrix = viewMatrix * coordinateSpaceTransform
        self.projectionMatrix = projectionMatrix
    }
   
    func updateWorld( anchors: [SIMD4<Float>] ) {

        coms = []
        for anchor in anchors {

            var com = anchor
            // MARK: - Coordinate conversion
            // Flipping the polarity of Z to convert from the left hand coordinate system (ARKit)
            // to the right hand coordinate system (Metal)
            com.z *= -1.0
            coms.append( com )
        }
        numOfPlanes = coms.count
    }
   
    func draw( in view: MTKView, commandBuffer: MTLCommandBuffer ) {

        if coms.count == 0 {
            return
        }

        let descriptor = view.currentRenderPassDescriptor

        // At this point, the image from the camera has been drawn to the drawable, and we should not clear it.
        let oldAction = descriptor!.colorAttachments[0].loadAction
        descriptor!.colorAttachments[0].loadAction = .load

        guard
            let encoder = commandBuffer.makeRenderCommandEncoder( descriptor: descriptor! )
        else {
            return
        }
    
        encoder.setRenderPipelineState( pipelineState )
        encoder.setDepthStencilState( depthState )
        encoder.setViewport( MTLViewport( originX: 0.0, originY: 0.0, width: screenSize.width, height: screenSize.height, znear: 0.0, zfar: 1.0 ))

        encoder.setVertexBuffer( planeVertexBuffer, offset: 0, index: 0 )
        var planeWidthFloat = Float(planeWidth)
        encoder.setVertexBytes( &planeWidthFloat,  length: MemoryLayout<Float>.stride,                     index: 1 )
        encoder.setVertexBytes( &coms,             length: MemoryLayout<SIMD4<Float>>.stride * coms.count, index: 2 )
        encoder.setVertexBytes( &viewMatrix,       length: MemoryLayout<float4x4>.stride,                  index: 3 )
        encoder.setVertexBytes( &projectionMatrix, length: MemoryLayout<float4x4>.stride,                  index: 4 )

        encoder.setFragmentTexture( planeTexture, index: 0 )

        encoder.drawIndexedPrimitives(
            type:              .triangle,
            indexCount:        planeIndexData.count,
            indexType:         .uint32,
            indexBuffer:       planeIndexBuffer,
            indexBufferOffset: 0,
            instanceCount:     coms.count,
            baseVertex:        0,
            baseInstance:      0
        )
    
        encoder.endEncoding()

        descriptor!.colorAttachments[0].loadAction = oldAction
    }

    func touchesBegan( location: CGPoint, size: CGRect ) {
        print ( "toutchesBegan at ( \(location.x), \(location.y) ).")
    }

    func touchesMoved( location: CGPoint, size: CGRect ) {
        print ( "toutchesMoved at ( \(location.x), \(location.y) ).")
    }

    func touchesEnded( location: CGPoint, size: CGRect ) {
        print ( "toutchesEnded at ( \(location.x), \(location.y) ).")
    }
}
