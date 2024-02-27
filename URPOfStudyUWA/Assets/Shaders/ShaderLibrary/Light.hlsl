// 灯光数据相关库
#ifndef CUSTOM_LIGHT_INCLUDED
#define CUSTOM_LIGHT_INCLUDED

// 灯光的属性
struct Light
{
    float color;
    float3 direction;
};
// 获取平行光的属性
Light GetDirectionalLight()
{
    Light light;
    light.color = 1.0f;
    light.direction = float3(0.0, 1.0, 0.0);
    return light;
}

#endif