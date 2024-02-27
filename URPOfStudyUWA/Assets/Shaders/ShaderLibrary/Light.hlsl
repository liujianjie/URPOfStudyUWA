// 灯光数据相关库
#ifndef CUSTOM_LIGHT_INCLUDED
#define CUSTOM_LIGHT_INCLUDED

// 方向光的数据
// 定义两个属性代表方向感的颜色和方向，用来接收后续从CPU传递来的灯光数据
CBUFFER_START(_CustomLight)
    float3 _DirectionalLightColor;
    float3 _DirectionalLightDirection;
CBUFFER_END

// 灯光的属性
struct Light
{
    float3 color;
    float3 direction;
};

// 获取方向光的数据
Light GetDirectionalLight()
{
    Light light;
    //light.color = float3(0.8, 1, 1);
    light.color = _DirectionalLightColor;
    light.direction =_DirectionalLightDirection;
    return light;
}
#endif