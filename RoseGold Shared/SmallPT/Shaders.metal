//
//  Shaders.metal
//  SmallPT http://www.kevinbeason.com/smallpt/
//
//  Created by Tatsuhiro Aoshima on 2019/01/11.
//  Copyright © 2019 Tatsuhiro Aoshima. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include "../loki/Header.metal"
using namespace metal;

#define WIDTH  1024
#define HEIGHT 1024

#define NSAMPLE  1
#define MAXDEPTH 8
constant float EPS_F = 1e-3;
constant float DMAX_F = 1e+5;

enum class Refl {
    Diff, Spec, Refr
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
};

struct IntersectResult {
    int    id;
    float  t;
    Sphere s;

    IntersectResult(int id, float t, Sphere s) {
        this->id = id;
        this->t = t;
        this->s = s;
    }
};

#define NSPHERE 9
constant Sphere spheres[NSPHERE] = {
    {  1e5, float3(-1e5+1.0,   40.8,      81.6),       float3(0.0), float3(0.75, 0.25, 0.25), Refl::Diff},
    {  1e5, float3( 1e5+99.0,  40.8,      81.6),       float3(0.0), float3(0.25, 0.25, 0.75), Refl::Diff},
    {  1e5, float3(50.0,       40.8,      -1e5),       float3(0.0), float3(0.75, 0.75, 0.75), Refl::Diff},
    {  1e5, float3(50.0,       40.8,       1e5+170.0), float3(0.0), float3(0.00, 0.00, 0.00), Refl::Diff},
    {  1e5, float3(50.0,       -1e5,      81.6),       float3(0.0), float3(0.75, 0.75, 0.75), Refl::Diff},
    {  1e5, float3(50.0,        1e5+81.6, 81.6),       float3(0.0), float3(0.75, 0.75, 0.75), Refl::Diff},
    { 16.5, float3(27.0,       16.5,      47.0),       float3(0.0), float3(1.00, 1.00, 1.00), Refl::Spec},
    { 16.5, float3(73.0,       16.5,      78.0),       float3(0.0), float3(0.70, 1.00, 0.90), Refl::Refr},
    {600.0, float3(50.0,      681.33,     81.6),       float3(1.0), float3(0.00, 0.00, 0.00), Refl::Diff}
};

IntersectResult intersect(Ray r, int avoid) {
    int target_id = -1;
    float t = DMAX_F;
    Sphere target = spheres[0];
    for (int i = 0; i < NSPHERE; ++i) {
        Sphere sphere = spheres[i];
        float d = sphere.intersect(r);
        if (i != avoid && d != 0.0 && d < t) {
            t = d;
            target_id = i;
            target = sphere;
        }
    }
    IntersectResult ir(target_id, t, target);
    return ir;
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
        IntersectResult iray = intersect(ray, id);
        float t = iray.t;
        Sphere obj = iray.s;
        id = iray.id;
        if (id < 0) {
            break;
        }
        float3 x = t*ray.d + ray.o;
        float3 n = normalize(x - obj.p), nl = n*sign(-dot(n, ray.d));

        if (obj.refl == Refl::Diff) {
            float r = loki.rand();
            float3 d = jitter(nl, 2.0*M_PI_F*loki.rand(), sqrt(r), sqrt(1.0 - r));
            acc += mask*obj.e;
            mask *= obj.c;
            ray = Ray(x, d);
        } else if (obj.refl == Refl::Spec) {
            acc += mask*obj.e;
            mask *= obj.c;
            ray = Ray(x, reflect(ray.d, n));
        } else {
            float a = dot(n, ray.d), ddn = abs(a);
            float nc = 1.0, nt = 1.5, nnt = mix(nc/nt, nt/nc, float(a > 0.0));
            float cos2t = 1.0 - nnt*nnt*(1.0 - ddn*ddn);
            ray = Ray(x, reflect(ray.d, n));
            if (cos2t > 0.0) {
                float3 tdir = normalize(ray.d*nnt + sign(a)*n*(ddn*nnt + sqrt(cos2t)));
                float R0 = ((nt - nc)*(nt - nc))/((nt + nc)*(nt + nc)),
                c = 1.0 - mix(ddn, dot(tdir, n), float(a > 0.0));
                float Re = R0 + (1.0 - R0)*c*c*c*c*c;
                float P = 0.25 + 0.5*Re, RP = Re/P, TP=(1.0 - Re)/(1.0 - P);
                if (loki.rand() < P) {
                    mask *= RP;
                } else {
                    mask *= obj.c*TP;
                    ray = Ray(x, tdir);
                }
            }
        }
    }
    return acc;
}

float3 ray_trace(float2 position, float seed) {
    float2 uv = 2.0*position/float2(WIDTH, HEIGHT) - 1.0;
    float2 iResolution(WIDTH, HEIGHT);
    float3 camPos = float3(50.0, 40.8, 150.0);
    float3 cz = normalize(float3(50.0, 40.0, 81.6) - camPos);
    float3 cx = float3(1.0, 0.0, 0.0);
    float3 cy = normalize(cross(cx, cz));
    cx = cross(cz, cy);
    float3 color = float3(0.0);
    Loki loki(position.x, position.y, seed);
    for (int i = 0; i < NSAMPLE; ++i) {
        color += radiance(Ray(camPos, normalize((iResolution.x/iResolution.y*uv.x * cx + uv.y * cy) + cz)), loki);
    }
    return color/float(NSAMPLE);
}
