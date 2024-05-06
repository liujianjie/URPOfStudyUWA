#ifndef CUSTOM_SURFACE_INCLUDED
#define CUSTOM_SURFACE_INCLUDED

struct Surface
{
    // 表面位置
    float3 position;
    float3 normal;
    float3 color;
    float alpha;
    float metallic;
    float smoothness;
    float3 viewDirection;
    // 表面深度。阴影的最大距离是基于视图空间的深度，而不是与相机的距离
    float depth;
    float dither;
};

#endif