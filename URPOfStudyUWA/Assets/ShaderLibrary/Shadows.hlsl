// 阴影采样
#ifndef CUSTOM_SHADOWS_INCLUDED
#define CUSTOM_SHADOWS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
// 如果使用的是PCF 3X3
#if defined(_DIRECTIONAL_PCF3)
    // 需要4个滤波样本
    #define DIRECTIONAL_FILTER_SAMPLES 4
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_DIRECTIONAL_PCF5)
    // 如果使用的是PCF 5X5
    #define DIRECTIONAL_FILTER_SAMPLES 9
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_DIRECTIONAL_PCF7)
    // 如果使用的是PCF 7X7
    #define DIRECTIONAL_FILTER_SAMPLES 16
    #define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

// 阴影图集
TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
    // 级联数量和包围球数据
    int _CascadeCount;
    float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
    // 级联数据
    float4 _CascadeData[MAX_CASCADE_COUNT];
    // 阴影转换矩阵
    float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
    // 阴影最大距离
    //float _ShadowDistance;
    // 阴影过渡距离
    float4 _ShadowDistanceFade;
    // 图集大小
    float4 _ShadowAtlasSize;
CBUFFER_END

// 阴影的数据信息
struct DirectionalShadowData
{
    float strength;
    int tileIndex;
    // 法线偏差
    float normalBias;
};
// 阴影数据
struct ShadowData
{
    // 级联索引
    int cascadeIndex;
    // 是否采样阴影的标志
    float strength;
    // 混合级联
    float cascadeBlend;
};


// 公式计算阴影过度时的强度
float FadedShadowStrength(float distance, float scale, float fade)
{
    return saturate((1.0 - distance * scale) * fade);
}
// 得到世界空间的表面阴影数据
ShadowData GetShadowData(Surface surfaceWS)
{
    ShadowData data;
    data.cascadeBlend = 1.0;
    //data.strength = 1.0;
    //data.strength = surfaceWS.depth < _ShadowDistance ? 1.0 : 0.0;
    // 通过公式得到有线性过度的阴影强度
    data.strength = FadedShadowStrength(surfaceWS.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
    int i;
    // 如果物体表面到球心的平方距离小于球体半径的平方，就说明在包围球内，得到合适的级联层级索引
    float distanceSqr;
    for (i = 0; i < _CascadeCount; i++)
    {
        float4 sphere = _CascadeCullingSpheres[i];
        distanceSqr = DistanceSquared(surfaceWS.position, sphere.xyz);
        if (distanceSqr < sphere.w)
        {
            // 计算级联阴影的过度强度
            float fade = FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
            // 如果对象处在最后一个级联范围中
            if (i == _CascadeCount - 1)
            {
                data.strength *= fade;
            }
            else
            {
                data.cascadeBlend = 1;
            }
            break;
        }
    }
    // 如果超出最后一个级联的范围，标志符设置为0，不对阴影进行采样
    if (i == _CascadeCount)
    {
        data.strength = 0.0;            // 不知道为什么，这里一直返回0，导致阴影一直不显示
    }
    // 抖动模式，且不在最后一个级联，且当级联混合值小于抖动值时，则跳到下一个级联：为了级联过度
#if defined(_CASCADE_BLEND_DITHER)
    else if (data.cascadeBlend < surfaceWS.dither)
    {
        i += 1;
    }
#endif

#if !defined(_CASCADE_BLEND_SOFT)
    data.cascadeBlend = 1.0f;
#endif

    data.cascadeIndex = i; // 默认级联索引为0，使用第一个包围球
    return data;
}

// 对阴影图集采样
float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);

}

// DIRECTIONAL_FILTER_SETUP 4个参数，第一个xy图集纹理大小，zw图集尺寸，第二个是原始样本位置，后两个是样本的权重和样本的位置
float FilterDirectionalShadow(float3 positionSTS)
{
#if defined(DIRECTIONAL_FILTER_SETUP)
    // 样本权重
    float weights[DIRECTIONAL_FILTER_SAMPLES];
    // 样本位置
    float2 positions[DIRECTIONAL_FILTER_SAMPLES];
    float4 size = _ShadowAtlasSize.yyxx;            // 这里写错过，导致CPU无法传值过来
    DIRECTIONAL_FILTER_SETUP(size, positionSTS.xy, weights, positions);
    float shadow = 0;
    for (int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; i++)
    {
        // 遍历所有样本得到权重和
        shadow += weights[i] * SampleDirectionalShadowAtlas(float3(positions[i].xy, positionSTS.z));
    }
    return shadow;
#else  
    return SampleDirectionalShadowAtlas(positionSTS);
#endif
}

// 计算阴影衰减
float GetDirectionalShadowAttenuation(DirectionalShadowData directional, ShadowData global, Surface surfaceWS)
{
    // 如果材质没有定义接受阴影的宏
    #if !defined(_RECEIVE_SHADOWS)
    return 1.0;
    #endif
    // 如果灯光的阴影强度为0，直接返回1
    if (directional.strength <= 0.0)
    {
        return 1.0;
    }
    // 计算法线偏差
    //float3 normalBias = surfaceWS.normal * _CascadeData[global.cascadeIndex].y;
    float3 normalBias = surfaceWS.normal * (directional.normalBias * _CascadeData[global.cascadeIndex].y);
    // 通过阴影转换矩阵和表面位置得到在阴影纹理（图块）空间的位置，然后对图集进行采样
    // 通过加上法线偏移后的表面顶点位置，得到在阴影纹理空间的新位置，然后对图集进行采样
    float3 positionSTS = mul(_DirectionalShadowMatrices[directional.tileIndex], float4(surfaceWS.position + normalBias, 1.0)).xyz;
    
    float shadow = FilterDirectionalShadow(positionSTS);
    // 如果级联混合小于1代表在级联层级过度区域中，必须从下一个级联中采样并在两个值之间进行插值
    if (global.cascadeBlend < 1.0)
    {
        normalBias = surfaceWS.normal * (directional.normalBias * _CascadeData[global.cascadeIndex + 1].y);
        positionSTS = mul(_DirectionalShadowMatrices[directional.tileIndex + 1], float4(surfaceWS.position + normalBias, 1.0)).xyz;
        shadow = lerp(FilterDirectionalShadow(positionSTS), shadow, global.cascadeBlend);
    }
    // 最终阴影衰减值是阴影强度和衰减因子的插值
    return lerp(1.0, shadow, directional.strength);
}

#endif