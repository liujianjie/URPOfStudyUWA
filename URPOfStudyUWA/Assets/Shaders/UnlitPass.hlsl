#ifndef CUSTOM_UNLIT_PASS_INCLUDED
#define CUSTOM_UNLIT_PASS_INCLUDED

#include "ShaderLibrary/Common.hlsl"

// 顶点函数
float4 UnlitPassVertex(float3 positionOS : POSITION) : SV_POSITION
{
    float3 positionWS = TransformObjectToWorld(positionOS.xyz);
    return TransformWorldToHClip(positionWS);
}
float4 _BaseColor;
// 片元函数
float4 UnlitPassFragment() : SV_TARGET
{
    return _BaseColor;
}


#endif