// 灯光数据相关库
#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_BRDF_INCLUDED

// 电介质的反射率平均约0.04
#define MIN_REFLECTIVITY 0.04

// 计算不反射的值
float OneMinusReflectivity(float metallic)
{
    float range = 1.0 - MIN_REFLECTIVITY;
    return range - metallic * range;
}

struct BRDF
{
    float3 diffuse;
    float3 specular;
    float roughness;
};
// 获取给定表面的BRDF数据
BRDF GetBRDF(Surface surface)
{
    BRDF brdf;
    //float oneMinusReflectivity = 1.0 - surface.metallic;              // 反射率
    //brdf.diffuse = surface.color;
    // brdf.specular =  surface.color - brdf.diffuse;        // 能量守恒 
    // brdf.roughness = 1.0f;
    
    float oneMinusReflectivity = OneMinusReflectivity(surface.metallic); // 反射率
    brdf.diffuse = surface.color * oneMinusReflectivity;
    brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic); // 非金属的镜面为白色，金属影响镜面反射的额颜色
    // 光滑度转为实际粗糙度
    float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
    brdf.roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
    return brdf;
}
// 根据公式得到镜面反射强度
float SpecularStrength(Surface surface, BRDF brdf, Light light)
{
    float3 h = SafeNormalize(light.direction + surface.viewDirection);  // 半角向量，H：归一化的L+V（光线方向+视角方向）
    float nh2 = Square(saturate(dot(surface.normal, h)));               // 法线、  ，nh2: N·H的平方
    float lh2 = Square(saturate(dot(light.direction, h)));              // 光线方向、，lh2: L·H的平方
    float r2 = Square(brdf.roughness);                                  // 粗糙度的平方
    float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);                      // D函数的平方
    float normalization = brdf.roughness * 4.0 + 2.0;                   // 归一化因子：n = 4r + 2
    return r2 / (d2 * max(0.1, lh2) * normalization);                   // 镜面反射强度
}

#endif