// 计算光照相关库
#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED



// 根据物体的表面信息获取最终的光照结果
// float3 GetLighting(Surface surface)
// {
//     return surface.normal.y;
// }
// 使用的函数必须先定义
// 计算入射光照
float3 IncomingLight(Surface surface, Light light)
{
    return saturate(dot(surface.normal, light.direction)) * light.color;
}
// 入射光照乘以表面颜色，得到最终的照明颜色
float GetLighting(Surface surface, Light light)
{
    return IncomingLight(surface, light) * surface.color;
}
// 获取最终照明结果
float3 GetLighting(Surface surface)
{
    return GetLighting(surface, GetDirectionalLight());
}




#endif