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
CBUFFER_END

// 灯光的属性
struct Light
{
    float3 color;
    float3 direction;
};
// 获取方向光的数量
int GetDirectionalLightCount()
{
    return _DirectionalLightCount;
}
// 获取指定索引的方向光的数据
Light GetDirectionalLight(int index)
{
    Light light;
    light.color = _DirectionalLightColors[index].rgb;
    // light.color = float3(0.8, 0.5, 1);
    light.direction = _DirectionalLightDirections[index].xyz;
    return light;
}

// 获取方向光的数据
//Light GetDirectionalLight()
//{
//    Light light;
    //light.color = float3(0.8, 1, 1);
//    light.color = _DirectionalLightColor;
//    light.direction =_DirectionalLightDirection;
//    return light;
//}
#endif