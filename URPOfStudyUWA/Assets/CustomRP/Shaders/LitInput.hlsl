﻿#ifndef CUSTOM_LIT_INPUT_INCLUDED
#define CUSTOM_LIT_INPUT_INCLUDED

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

TEXTURE2D(_EmissionMap);

// 缓冲区
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

float GetFresnel(float2 baseUV)
{
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Fresnel);
}

//基础纹理UV转换
float2 TransformBaseUV(float2 baseUV) {
	float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	return baseUV * baseST.xy + baseST.zw;
}

//获取基础纹理的采样数据
float4 GetBase(float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	return map * color;
}

float GetCutoff(float2 baseUV) {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
}

float GetMetallic(float2 baseUV) {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
}

float GetSmoothness(float2 baseUV) {
	return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
}
//获取自发光纹理的采样数据。与颜色值相乘得到最终的自发光颜色
float3 GetEmission (float2 baseUV) {
	float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, baseUV);
	float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
	return map.rgb * color.rgb;
}

#endif
