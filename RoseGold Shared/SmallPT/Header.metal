//
//  Header.metal
//  RoseGold
//
//  Created by Tatsuhiro Aoshima on 2019/01/11.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#ifndef SmallPT_Header_metal
#define SmallPT_Header_metal
float3 ray_trace(float2 position, float randseed);
#endif
