// 阴影采样
#ifndef CUSTOM_SHADOWS_INCLUDED
#define CUSTOM_SHADOWS_INCLUDED

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
CBUFFER_END

// 阴影的数据信息
struct DirectionalShadowData
{
    float strength;
    int tileIndex;
};
// 阴影数据
struct ShadowData
{
    // 级联索引
    int cascadeIndex;
    // 是否采样阴影的标志
    float strength;
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
            break;
        }
    }
    // 如果超出最后一个级联的范围，标志符设置为0，不对阴影进行采样
    if (i == _CascadeCount - 1)
    {
        //data.strength = 0.0;            // 不知道为什么，这里一直返回0，导致阴影一直不显示
        data.strength *= FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
    }
    data.cascadeIndex = i; // 默认级联索引为0，使用第一个包围球
    return data;
}

// 对阴影图集采样
float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);

}
// 计算阴影衰减
float GetDirectionalShadowAttenuation(DirectionalShadowData directional, ShadowData global, Surface surfaceWS)
{
    // 如果灯光的阴影强度为0，直接返回1
    if (directional.strength <= 0.0)
    {
        return 1.0;
    }
    // 计算法线偏差
    float3 normalBias = surfaceWS.normal * _CascadeData[global.cascadeIndex].y;
    // 通过阴影转换矩阵和表面位置得到在阴影纹理（图块）空间的位置，然后对图集进行采样
    // 通过加上法线偏移后的表面顶点位置，得到在阴影纹理空间的新位置，然后对图集进行采样
    float3 positionSTS = mul(_DirectionalShadowMatrices[directional.tileIndex], float4(surfaceWS.position + normalBias, 1.0)).xyz;
    float shadow = SampleDirectionalShadowAtlas(positionSTS);
    
    // 最终阴影衰减值是阴影强度和衰减因子的插值
    return lerp(1.0, shadow, directional.strength);
}

#endif