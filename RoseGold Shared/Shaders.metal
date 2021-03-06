//
//  Shaders.metal
//  RoseGold
//
//  Created by Tatsuhiro Aoshima on 2019/01/10.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#include <simd/simd.h>

#include "ShaderTypes.h"
#include "SmallPT/Header.metal"

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} RenderData;

vertex RenderData vertexShader(uint vertexID [[vertex_id]],
                               constant Vertex *vertices [[buffer(BufferIndexVertices)]],
                               constant vector_uint2 *viewportSizePointer  [[buffer(BufferIndexViewpointSize)]])
{
    RenderData data;
    float2 position = vertices[vertexID].position;
    float2 viewportSize = float2(*viewportSizePointer);
    data.position.xy = position/(viewportSize/2.0);
    data.position.y = -data.position.y;
    data.position.z = 0;
    data.position.w = 1.0;
    data.texCoord = vertices[vertexID].texCoord;
    return data;
}

fragment float4 fragmentShader(RenderData data [[stage_in]],
                               texture2d<half> output [[texture(TextureIndexOutput)]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    const half4 colorSample = output.sample(textureSampler, data.texCoord);
    return float4(colorSample);
}

kernel void roseGoldKernel(constant Environment *env [[buffer(BufferIndexEnvironment)]],
                           texture2d<half, access::read_write> output [[texture(TextureIndexOutput)]],
                           uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if ((gid.x >= output.get_width()) || (gid.y >= output.get_height())) {
        // Return early if the pixel is out of bounds
        return;
    }
    float2 position = float2(gid.x, output.get_height() - gid.y);
    float3 gamma = ray_trace(position, env->cameraPosition, env->cameraDirection, env->nframe);
    gamma /= env->nframe;
    gamma += pow(float3(output.read(gid).xyz), float3(2.2))*((env->nframe - 1)/env->nframe);
    float4 color = float4(pow(clamp(gamma, 0.0, 1.0), float3(1.0/2.2)), 1.0);
    output.write(half4(color), gid);
}
