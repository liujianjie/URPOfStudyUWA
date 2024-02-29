// 计算光照相关库
#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// 根据物体的表面信息获取最终的光照结果
// float3 GetLighting(Surface surface)
// {
//     return surface.normal.y;
// }
// 直接光照的表面颜色
float3 DirectBRDF(Surface surface, BRDF brdf, Light light)
{
    // 通过镜面反射强度乘以镜面反射颜色 + 漫反射颜色
    return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}
// 使用的函数必须先定义
// 计算入射光照
float3 IncomingLight(Surface surface, Light light)
{
    return saturate(dot(surface.normal, light.direction)) * light.color;
}
// 入射光照乘以表面颜色，得到最终的照明颜色
float3 GetLighting(Surface surface, BRDF brdf, Light light)
{
    return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);    // 入射光*表面颜色
}
// 获取最终照明结果
float3 GetLighting(Surface surface, BRDF brdf)
{
    // 可见方向光的照明结果进行累加得到最终照明结果
    float3 color = 0.0;
    for (int i = 0; i < GetDirectionalLightCount(); i++)
    {
        color += GetLighting(surface, brdf, GetDirectionalLight(i));
    }
    return color;
}




#endif