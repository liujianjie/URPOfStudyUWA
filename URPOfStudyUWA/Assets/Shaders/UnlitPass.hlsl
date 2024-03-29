#ifndef CUSTOM_UNLIT_PASS_INCLUDED
#define CUSTOM_UNLIT_PASS_INCLUDED

#include "ShaderLibrary/Common.hlsl"

// 所有材质的属性我们需要在常量缓冲区里定义
//CBUFFER_START(UnityPerMaterial)
//    float4 _BaseColor;
//CBUFFER_END

// 纹理采样器
TEXTURE2D(_BaseMap);            // 定义一张纹理
SAMPLER(sampler_BaseMap);       // 为上一个定义的纹理提供采样器

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST) // 提供纹理的缩放和平移
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

// 用作顶点函数的输入参数
struct Attributes
{
    float3 positionOS : POSITION;
    float2 baseUV : TEXCOORD;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
// 用作片元函数的输入参数
struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 baseUV : VAR_BASE_UV;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// 顶点函数
Varyings UnlitPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(positionWS);
    // 计算缩放和偏移以后的UV坐标
    float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
    output.baseUV = input.baseUV * baseST.xy + baseST.zw;
    return output;
}

// 片元函数
float4 UnlitPassFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV); // 采样纹理
    float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
    float4 base = baseMap * baseColor;
    #if defined(_CLIPPING)
        // 透明度低于阙值的片元进行丢弃
        clip(base.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
    #endif
    return base;
}


#endif