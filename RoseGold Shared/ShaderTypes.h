//
//  ShaderTypes.h
//  RoseGold
//
//  Created by Tatsuhiro Aoshima on 2019/01/10.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex) {
    BufferIndexVertices      = 0,
    BufferIndexViewpointSize = 1,
    BufferIndexEnvironment   = 2,
};

typedef NS_ENUM(NSInteger, TextureIndex) {
    TextureIndexOutput = 0,
};

typedef struct {
    // Positions in pixel space (i.e. a value of 100 indicates 100 pixels from the origin/center)
    vector_float2 position;
    // 2D texture coordinate
    vector_float2 texCoord;
} Vertex;

typedef struct {
    float         nframe;
    float         timestamp;
    vector_float3 cameraPosition;
    vector_float2 cameraDirection;
} Environment;

#endif /* ShaderTypes_h */

