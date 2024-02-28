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

#endif