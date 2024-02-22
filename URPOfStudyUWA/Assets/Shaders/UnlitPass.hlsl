#ifndef CUSTOM_UNLIT_PASS_INCLUDED
#define CUSTOM_UNLIT_PASS_INCLUDED

#include "ShaderLibrary/Common.hlsl"

// 用作顶点函数的输入参数
struct Attributes
{
    float3 positionOS : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
// 用作片元函数的输入参数
struct Varyings
{
    float4 positionCS : SV_Position;
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
    return output;
}
// 所有材质的属性我们需要在常量缓冲区里定义
//CBUFFER_START(UnityPerMaterial)
//    float4 _BaseColor;
//CBUFFER_END

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

// 片元函数
float4 UnlitPassFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
}


#endif