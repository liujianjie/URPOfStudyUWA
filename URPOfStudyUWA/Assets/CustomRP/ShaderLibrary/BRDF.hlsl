﻿//BRDF相关库
#ifndef CUSTOM_BRDF_INCLUDED
#define CUSTOM_BRDF_INCLUDED

//BRDF属性
struct BRDF {
    //漫反射
	float3 diffuse;
	//镜面反射
	float3 specular;
	//粗糙度
	float roughness;
	
    float perceptualRoughness;
	
    float fresnel;
};

//电介质的反射率平均约0.04
#define MIN_REFLECTIVITY 0.04
//计算不反射的值，将范围从 0-1 调整到 0-0.96，保持和URP中一样
float OneMinusReflectivity (float metallic) {
	float range = 1.0 - MIN_REFLECTIVITY;
	return range - metallic * range;
}

//得到表面的BRDF数据
BRDF GetBRDF (Surface surface, bool applyAlphaToDiffuse = false) {
	BRDF brdf;
	//乘以表面颜色得到BRDF的漫反射
	float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);
	brdf.diffuse = surface.color * oneMinusReflectivity;
	//透明度预乘
	if (applyAlphaToDiffuse) {
		brdf.diffuse *= surface.alpha;
	}
	brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
	// 光滑度转为实际粗糙度
	brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
    brdf.roughness = PerceptualRoughnessToRoughness(brdf.perceptualRoughness);
    brdf.fresnel = saturate(surface.smoothness + 1.0 - oneMinusReflectivity);
	return brdf;
}
//根据公式得到镜面反射强度
float SpecularStrength (Surface surface, BRDF brdf, Light light) {
	float3 h = SafeNormalize(light.direction + surface.viewDirection);
	float nh2 = Square(saturate(dot(surface.normal, h)));
	float lh2 = Square(saturate(dot(light.direction, h)));
	float r2 = Square(brdf.roughness);
	float d2 = Square(nh2 * (r2 - 1.0) + 1.00001);
	float normalization = brdf.roughness * 4.0 + 2.0;
	return r2 / (d2 * max(0.1, lh2) * normalization);
}
//获取基于BRDF的直接照明
float3 DirectBRDF (Surface surface, BRDF brdf, Light light) {
	return SpecularStrength(surface, brdf, light) * brdf.specular + brdf.diffuse;
}
// 间接brdf
float3 IndirectBRDF(Surface surface, BRDF brdf, float3 diffuse, float3 specular)
{
    float fresnelStrength = surface.fresnelStrength * Pow4(1.0 - saturate(dot(surface.normal, surface.viewDirection)));
    float3 reflection = specular * lerp(brdf.specular, brdf.fresnel, fresnelStrength);
    //float3 reflection = specular * brdf.specular;			// 全局照明的镜面发射*brdf中的镜面反射 = 镜面反射
    reflection /= brdf.roughness * brdf.roughness + 1.0; // 镜面反射 / (SampleEnvironment表面粗糙度^2 + 1)，对高粗糙度的表面使得表面反射减半
    return diffuse * brdf.diffuse + reflection;
}

#endif
