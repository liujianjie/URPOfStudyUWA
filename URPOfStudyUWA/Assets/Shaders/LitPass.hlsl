#ifndef CUSTOM_UNLIT_PASS_INCLUDED
#define CUSTOM_UNLIT_PASS_INCLUDED

#include "ShaderLibrary/Common.hlsl"
#include "ShaderLibrary/Surface.hlsl"
#include "ShaderLibrary/Light.hlsl"
#include "ShaderLibrary/BRDF.hlsl"
#include "ShaderLibrary/Lighting.hlsl"

// 所有材质的属性我们需要在常量缓冲区里定义
//CBUFFER_START(UnityPerMaterial)
//    float4 _BaseColor;
//CBUFFER_END

// 纹理采样器
TEXTURE2D(_BaseMap);            // 定义一张纹理
SAMPLER(sampler_BaseMap);       // 为上一个定义的纹理提供采样器

// 供C#代码Shader.PropertyToID("_BaseColor");获取
UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST) // 提供纹理的缩放和平移
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

// 用作顶点函数的输入参数
struct Attributes
{
    float3 positionOS : POSITION;
    float2 baseUV : TEXCOORD;
    float3 normalOS : NORMAL;   // 表面法线
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
// 用作片元函数的输入参数
struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : VAR_POSITION;// 顶点在世界空间的位置
    float2 baseUV : VAR_BASE_UV;
    float3 normalWS : NORMAL; // 世界法线
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// 顶点函数
Varyings LitPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    // 计算世界空间的法线
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    // 计算缩放和偏移以后的UV坐标
    float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
    output.baseUV = input.baseUV * baseST.xy + baseST.zw;
    return output;
}

// 片元函数
float4 LitPassFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.baseUV); // 采样纹理
    float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
    float4 base = baseMap * baseColor;
    #if defined(_CLIPPING)
        // 透明度低于阙值的片元进行丢弃
        clip(base.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
    #endif
    // 定义哥surface并填充属性
    Surface surface;
    surface.normal = normalize(input.normalWS);
    surface.color = base.rgb;
    surface.alpha = base.a;
    surface.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic); // UnityPerMaterial,别写错成UnityPermaterial
    surface.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
    //surface.metallic = 0;
    //surface.smoothness = 0;
    // 得到视角方向
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionCS);
    // 通过表面属性计算最终光照结果
    #if defined(_PREMULTIPLY_ALPHA)
        BRDF brdf = GetBRDF(surface, true);
    #else
        BRDF brdf = GetBRDF(surface); // 这里得到表面得BRDF数据：漫反射颜色、镜面反射颜色、粗糙度
    #endif
    float3 color = GetLighting(surface, brdf);  // 然后用BRDF数据计算光照结果
    return float4(color, surface.alpha);
}


#endif