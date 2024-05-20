// 灯光数据相关库
#ifndef CUSTOM_GL_INCLUDED
#define CUSTOM_GL_INCLUDED
// 当需要渲染光照贴图对象时
#if defined(LIGHTMAP_ON)
#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
#define TRANSFER_GI_DATA(input, output) output.lightMapUV = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
#define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
// 否则这些宏都为空
#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
#define TRANSFER_GI_DATA(input, output) output.lightMapUV = input.lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
#define GI_FRAGMENT_DATA(input) input.lightMapUV
#endif

struct GI
{
    // 漫反射颜色
    float3 diffuse;
};

GI GetGI(float2 lightMapUV)
{
    GI gi;
    gi.diffuse = float3(lightMapUV, 0.0);
    return gi;
}

#endif