﻿//公共方法库
#ifndef CUSTOM_COMMON_INCLUDED
#define CUSTOM_COMMON_INCLUDED
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"
//定义一些宏取代常用的转换矩阵
#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_P glstate_matrix_projection
#define UNITY_PREV_MATRIX_M glstate_matrix_projection
#define UNITY_PREV_MATRIX_I_M glstate_matrix_projection
//获取值的平方
float Square (float v) {
	return v * v;
}
//计算两点间距离的平方
float DistanceSquared(float3 pA, float3 pB) {
	return dot(pA - pB, pA - pB);
}
void ClipLOD(float2 positionCS, float fade)
{
	#if defined(LOD_FADE_CROSSFADE)
		//float dither = (positionCS.y % 32) / 32;
		float dither = InterleavedGradientNoise(positionCS.xy, 0);
		clip(fade + (fade < 0.0 ? dither : -dither));
#endif
}
#if defined(_SHADOW_MASK_ALWAYS) ||  defined(_SHADOW_MASK_DISTANCE) 
	#define SHADOWS_SHADOWMASK
#endif
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#endif
