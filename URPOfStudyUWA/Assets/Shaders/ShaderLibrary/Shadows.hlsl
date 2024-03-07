// 阴影采样
#ifndef CUSTOM_SHADOWS_INCLUDED
#define CUSTOM_SHADOWS_INCLUDED

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4

// 阴影图集
TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
    // 阴影转换矩阵
    float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

// 阴影的数据信息
struct DirectionalShadowData
{
    float strength;
    int tileIndex;
};

// 对阴影图集采样
float SampleDirectionalShadowAtlas(float3 positionSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);

}
// 计算阴影衰减
float GetDirectionalShadowAttenuation(DirectionalShadowData data, Surface surfaceWS)
{
    // 如果灯光的阴影强度为0，直接返回1
    if (data.strength <= 0.0)
    {
        return 1.0;
    }
    
    // 通过阴影转换矩阵和表面位置得到在阴影纹理（图块）空间的位置，然后对图集进行采样
    float3 positionSTS = mul(_DirectionalShadowMatrices[data.tileIndex], float4(surfaceWS.position, 1.0)).xyz;
    float shadow = SampleDirectionalShadowAtlas(positionSTS);
    
    // 最终阴影衰减值是阴影强度和衰减因子的插值
    return lerp(1.0, shadow, data.strength);
}

#endif