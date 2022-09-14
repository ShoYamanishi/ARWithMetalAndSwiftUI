import Foundation
import MetalKit

extension SIMD4 where Scalar == Float {

    var xyzNormalized: SIMD3<Float> {
        get {
            SIMD3<Float>( x/w, y/w, z/w )
        }
    }

    var xyz: SIMD3<Float> {
        get {
            SIMD3<Float>( x, y, z )
        }
    }

}

extension float4x4 {

    var rotation: float3x3 {

        let x = columns.0.xyz
        let y = columns.1.xyz
        let z = columns.2.xyz

        return float3x3(columns: (x, y, z))
    }

}
