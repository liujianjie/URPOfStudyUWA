// 灯光数据相关库
#ifndef CUSTOM_LIGHT_INCLUDED
#define CUSTOM_LIGHT_INCLUDED

#define MAX_DIRECTIONAL_LIGHT_COUNT 4
// 方向光的数据
// 定义两个属性代表方向感的颜色和方向，用来接收后续从CPU传递来的灯光数据
CBUFFER_START(_CustomLight)
    //float3 _DirectionalLightColor;
    //float3 _DirectionalLightDirection;
    int _DirectionalLightCount;
    float4 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float4 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
    // 阴影数据
    float4 _DirectionalLightShadowData[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

// 灯光的属性
struct Light
{
    float3 color;
    float3 direction;
    float attenuation;  // 光源的阴影衰减属性
};
// 获取方向光的阴影数据
DirectionalShadowData GetDirectinalShadowData(int lightIndex)
{
    DirectionalShadowData data;
    data.strength = _DirectionalLightShadowData[lightIndex].x;
    data.tileIndex = _DirectionalLightShadowData[lightIndex].y;
    return data;
}

// 获取方向光的数量
int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}
// 获取指定索引的方向光的数据
Light GetDirectionalLight(int index, Surface surfaceWS)
{
    Light light;
    light.color = _DirectionalLightColors[index].rgb;
    // light.color = float3(0.8, 0.5, 1);
    light.direction = _DirectionalLightDirections[index].xyz;
    // 得到阴影数据
    DirectionalShadowData shadowData = GetDirectinalShadowData(index);
    // 得到阴影衰减
    light.attenuation = GetDirectionalShadowAttenuation(shadowData, surfaceWS);
    return light;
}

#endif