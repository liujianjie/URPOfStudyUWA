// 全局照明相关库
#ifndef CUSTOM_GL_INCLUDED
#define CUSTOM_GL_INCLUDED
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

TEXTURE2D(unity_Lightmap);
SAMPLER(samplerunity_Lightmap);

// 当需要渲染光照贴图对象时
#if defined(LIGHTMAP_ON)
#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
#define TRANSFER_GI_DATA(input, output) output.lightMapUV = input.lightMapUV;
#define GI_FRAGMENT_DATA(input) input.lightMapUV
#else
// 否则这些宏都为空
#define GI_ATTRIBUTE_DATA float2 lightMapUV : TEXCOORD1;
#define GI_VARYINGS_DATA float2 lightMapUV : VAR_LIGHT_MAP_UV;
#define TRANSFER_GI_DATA(input, output) output.lightMapUV = input.lightMapUV;
#define GI_FRAGMENT_DATA(input) input.lightMapUV

#endif

struct GI
{
    // 漫反射颜色
    float3 diffuse;
};

// 采样光照贴图
float3 SampleLightMap(float2 lightMapUV)
{
    //return float3(1.0, 1.0, 1.0);
    return SampleSingleLightmap(TEXTURE2D_ARGS(unity_Lightmap, samplerunity_Lightmap), lightMapUV, float4(1.0, 1.0f, 0.0, 0.0),
#if defined(UNITY_LIGHTMAP_FULL_HDR)
    false,
#else
    true,
#endif
    float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0));
}

GI GetGI(float2 lightMapUV)
{
    GI gi;
    gi.diffuse = SampleLightMap(lightMapUV);
    return gi;
}

#endif


/*
#define GI_ATTRIBUTE_DATA
#define GI_VARYINGS_DATA 
#define TRANSFER_GI_DATA(input, output)
#define GI_FRAGMENT_DATA(input) 0.0
*/
