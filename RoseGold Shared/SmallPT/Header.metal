//
//  Header.metal
//  RoseGold
//
//  Created by Tatsuhiro Aoshima on 2019/01/11.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

#ifndef SmallPT_Header_metal
#define SmallPT_Header_metal
#include <metal_stdlib>
using namespace metal;

float3 ray_trace(float2 position, float3 camPos, float2 camDir, float randseed);
#endif
