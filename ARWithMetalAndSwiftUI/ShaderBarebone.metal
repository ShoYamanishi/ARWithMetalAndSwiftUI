#include <metal_stdlib>
using namespace metal;

struct VertexInPositionUV {
    float4 position  [[ attribute( 0 ) ]];
    float2 uv        [[ attribute( 1 ) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float2 uv;
};

vertex VertexOut vertex_barebone(

    const    VertexInPositionUV   vertex_in         [[ stage_in    ]],
    constant float&               width             [[ buffer( 1 ) ]],
    constant float4*              coms              [[ buffer( 2 ) ]],
    constant float4x4&            view_matrix       [[ buffer( 3 ) ]],
    constant float4x4&            projection_matrix [[ buffer( 4 ) ]],
    const    ushort               iid               [[ instance_id ]]
) {
    return VertexOut {
        .position = projection_matrix * view_matrix * ( ( vertex_in.position * width ) + coms[ iid ] ),
        .uv       = vertex_in.uv
    };
}

fragment float4 fragment_barebone(
    VertexOut        in       [[ stage_in ]],
    texture2d<float> texture  [[ texture( 0 ) ]]
) {
    constexpr sampler s( mip_filter::linear, mag_filter::linear,  min_filter::linear );
    const auto p = texture.sample( s, in.uv );
    if ( p.a < 0.5 ) {
        discard_fragment();
    }
    return p;
}
    


