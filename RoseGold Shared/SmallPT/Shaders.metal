//
//  Shaders.metal
//  SmallPT http://www.kevinbeason.com/smallpt/
//
//  Created by Tatsuhiro Aoshima on 2019/01/11.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../loki/Header.metal"

constant float EPS_F  = 1e-8;
constant float DMAX_F = 1e+8;

constant float WIDTH  = 1024.0;
constant float HEIGHT = 1024.0;
constant int NSAMPLE  = 1;
constant int MAXDEPTH = 4;

enum class Refl {
    None, Diff, Spec, Refr
};

struct Ray {
    float3 o, d;

    Ray(float3 o, float3 d) {
        this->o = o;
        this->d = d;
    }
};

struct Sphere {
    float  r;
    float3 p, e, c;
    Refl   refl;

    float intersect(Ray ray) {
        float3 op = p - ray.o;
        float b = dot(op, ray.d);
        float det = b*b - dot(op, op) + r*r;
        if (det < 0.0) {
            return 0.0;
        } else {
            det = sqrt(det);
        }
        float t = b - det;
        if (t > EPS_F) {
            return t;
        }
        t = b + det;
        if (t > EPS_F) {
            return t;
        }
        return 0.0;
    }
    float3 normal(float3 x) {
        return normalize(x - p);
    }
};

struct Intersection {
    int    id;
    float  t;
    Sphere s;

    Intersection(int id, float t, Sphere s) {
        this->id = id;
        this->t = t;
        this->s = s;
    }
};

constant Sphere spheres[] = {
    // Walls
    {  1e5, float3(-1e5+1.0,   40.8,      81.6),       float3(0.0), float3(0.75, 0.25, 0.25), Refl::Diff},
    {  1e5, float3( 1e5+99.0,  40.8,      81.6),       float3(0.0), float3(0.25, 0.25, 0.75), Refl::Diff},
    {  1e5, float3(50.0,       40.8,      -1e5),       float3(0.0), float3(0.75, 0.75, 0.75), Refl::Diff},
    {  1e5, float3(50.0,       40.8,       1e5+170.0), float3(0.0), float3(0.00, 0.00, 0.00), Refl::Diff},
    {  1e5, float3(50.0,       -1e5,      81.6),       float3(0.0), float3(0.75, 0.75, 0.75), Refl::Diff},
    {  1e5, float3(50.0,        1e5+81.6, 81.6),       float3(0.0), float3(0.75, 0.75, 0.75), Refl::Diff},
    // A specular reflecting ball
    { 16.5, float3(27.0,       16.5,      47.0),       float3(0.0), float3(1.00, 1.00, 1.00), Refl::Spec},
    // A refracting ball
    { 16.5, float3(73.0,       16.5,      98.0),       float3(0.0), float3(1.00, 1.00, 1.00), Refl::Refr},
    // A kixby
    { 16.5, float3(77.0,       16.5,      47.0),       float3(0.0), float3(255.0/255.0, 141.0/255.0, 198.0/255.0), Refl::Diff},
    {  6.5, float3(67.0,        6.5,      47.0),       float3(0.0), float3(181.0/255.0,  23.0/255.0,   0.0/255.0), Refl::Diff},
    {  6.5, float3(87.0,        6.5,      47.0),       float3(0.0), float3(181.0/255.0,  23.0/255.0,   0.0/255.0), Refl::Diff},
    {  6.5, float3(62.0,       21.5,      47.0),       float3(0.0), float3(255.0/255.0, 141.0/255.0, 198.0/255.0), Refl::Diff},
    {  6.5, float3(92.0,       21.5,      47.0),       float3(0.0), float3(255.0/255.0, 141.0/255.0, 198.0/255.0), Refl::Diff},
    {  2.5, float3(72.0,       21.5,      62.0),       float3(0.0), float3(  0.0/255.0,   0.0/255.0,   0.0/255.0), Refl::Refr},
    {  2.5, float3(82.0,       21.5,      62.0),       float3(0.0), float3(  0.0/255.0,   0.0/255.0,   0.0/255.0), Refl::Refr},
    // A light source
    {600.0, float3(50.0,      681.33,     81.6),       float3(4.0), float3(0.00, 0.00, 0.00), Refl::Diff},
    // The empty object
    {  0.0, float3( 0.0,        0.0,       0.0),       float3(0.0), float3(0.00, 0.00, 0.00), Refl::None}
};

Intersection intersect(Ray r, int avoid) {
    int target_id = -1;
    float t = DMAX_F;
    Sphere target = spheres[0];
    for (int i = 0; spheres[i].refl != Refl::None; ++i) {
        Sphere sphere = spheres[i];
        float d = sphere.intersect(r);
        if (i != avoid && d != 0.0 && d < t) {
            t = d;
            target_id = i;
            target = sphere;
        }
    }
    Intersection isect(target_id, t, target);
    return isect;
}

float3 jitter(float3 d, float phi, float sina, float cosa) {
    float3 w = normalize(d), u = normalize(cross(w.yzx, w)), v = cross(w, u);
    return (u*cos(phi) + v*sin(phi))*sina + w*cosa;
}

float3 radiance(Ray ray, Loki loki) {
    float3 acc = float3(0.0);
    float3 mask = float3(1.0);
    int id = -1;
    for (int depth = 0; depth < MAXDEPTH; ++depth) {
        Intersection isect = intersect(ray, id);
        float t = isect.t;
        Sphere obj = isect.s;
        id = isect.id;
        if (id < 0) {
            break;
        }
        float3 x = ray.o + t*ray.d;
        float3 n = obj.normal(x), nl = n*sign(-dot(n, ray.d));
        float3 f = obj.c;
        // Calculate the material.
        if (obj.refl == Refl::Diff) {
            float r = loki.rand();
            float3 d = jitter(nl, 2.0*M_PI_F*loki.rand(), sqrt(r), sqrt(1.0 - r));
            acc += mask*obj.e;
            mask *= f;
            ray = Ray(x, d);
        } else if (obj.refl == Refl::Spec) {
            acc += mask*obj.e;
            mask *= f;
            ray = Ray(x, reflect(ray.d, n));
        } else {
            float a = dot(n, ray.d), ddn = abs(a);
            float nc = 1.0, nt = 1.5, nnt = mix(nc/nt, nt/nc, float(a > 0.0));
            float cos2t = 1.0 - nnt*nnt*(1.0 - ddn*ddn);
            ray = Ray(x, reflect(ray.d, n));
            if (cos2t > 0.0) {
                float3 tdir = normalize(ray.d*nnt + sign(a)*n*(ddn*nnt + sqrt(cos2t)));
                float R0 = ((nt - nc)*(nt - nc))/((nt + nc)*(nt + nc)), c = 1.0 - mix(ddn, dot(tdir, n), float(a > 0.0));
                float Re = R0 + (1.0 - R0)*c*c*c*c*c;
                float P = 0.25 + 0.5*Re, RP = Re/P, TP=(1.0 - Re)/(1.0 - P);
                if (loki.rand() < P) {
                    mask *= RP;
                } else {
                    mask *= f*TP;
                    ray = Ray(x, tdir);
                }
            }
        }
    }
    return acc;
}

float3 ray_trace(float2 position, float3 camPos, float2 camDir, float seed) {
    float3 cz = float3(cos(camDir.y)*sin(camDir.x), sin(camDir.y), -cos(camDir.y)*cos(camDir.x));
    float3 cx = float3(sin(camDir.x + 0.5*M_PI_F), 0.0, -cos(camDir.x + 0.5*M_PI_F));
    float3 cy = normalize(cross(cx, cz));
    cx = cross(cz, cy);
    float3 color = float3(0.0);
    Loki loki(position.x + 1, position.y + 1, seed);
    for (int i = 0; i < NSAMPLE; ++i) {
        float2 e = float2(loki.rand(), loki.rand());
        float3 d = 2.0*((position.x + e.x)/WIDTH - 0.5)*cx + 2.0*((position.y + e.y)/HEIGHT - 0.5)*cy + cz;
        color += radiance(Ray(camPos, normalize(d)), loki);
    }
    return color/float(NSAMPLE);
}
