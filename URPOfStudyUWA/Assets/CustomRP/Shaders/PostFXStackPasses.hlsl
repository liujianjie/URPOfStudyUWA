﻿#ifndef CUSTOM_POST_FX_PASSES_INCLUDED
#define CUSTOM_POST_FX_PASSES_INCLUDED
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

struct Varyings
{
    float4 positionCS : SV_POSITION;    // 裁剪空间位置
    float2 screenUV : VAR_SCREEN_UV;    // 屏幕空间uv坐标
};

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_linear_clamp);

TEXTURE2D(_PostFXSource2);

float4 _PostFXSource_TexelSize;
bool _BloomBicubicUpsampling;
float4 _BloomThreshold;
float _BloomIntensity;
//采样源纹理
float4 GetSource(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD(_PostFXSource, sampler_linear_clamp, screenUV, 0);
    //return SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, screenUV);
}
//采样第二个源纹理
float4 GetSource2(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD(_PostFXSource2, sampler_linear_clamp, screenUV, 0);
}
//双三次滤波上采样
float4 GetSourceBicubc(float2 screenUV)
{
    return SampleTexture2DBicubic(TEXTURE2D_ARGS(_PostFXSource, sampler_linear_clamp), screenUV, _PostFXSource_TexelSize.zwxy, 1.0, 0.0);
}

float3 ApplyBloomThreshold(float3 color)
{
    float brightness = Max3(color.r, color.g, color.b);
    float soft = brightness + _BloomThreshold.y;
    soft = clamp(soft, 0.0, _BloomThreshold.z);
    soft = soft * soft * _BloomThreshold.w;
    float contribution = max(soft, brightness - _BloomBicubicUpsampling.x);
    contribution /= max(brightness, 0.00001);
    return color * contribution;
}

float4 GetSourceTexelSize()
{
    return _PostFXSource_TexelSize;
}
float4 BloomCombinePassFragment(Varyings input) : SV_TARGET
{
    float3 lowRes;
    if (_BloomBicubicUpsampling)
    {
        lowRes = GetSourceBicubc(input.screenUV).rgb;
    }
    else
    {
        lowRes = GetSource(input.screenUV).rgb;
    }
    float3 hightRes = GetSource2(input.screenUV).rgb;
    return float4(lowRes * _BloomIntensity + hightRes, 1.0);
}
//在水平方向的进行滤波
float4 BloomHorizontalPassFragment(Varyings input) : SV_TARGET
{
    float3 color = 0.0;
    float offsets[] = { -4.0, 3.0, -2.0f, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0 };
    float weights[] =
    {
        0.01621622, 0.05405405, 0.12162162, 0.19459459, 0.22702703,
		0.19459459, 0.12162162, 0.05405405, 0.01621622
    };
    for (int i = 0; i < 9; i++)
    {
        float offset = offsets[i] * 2.0 * GetSourceTexelSize().x;
        color += GetSource(input.screenUV + float2(offset, 0.0)).rgb * weights[i];
    }
    return float4(color, 1.0);

}
//在竖直方向的进行滤波
float4 BloomVerticalPassFragment(Varyings input) : SV_TARGET
{
    float3 color = 0.0;
    //float offsets[] = { -4.0, 3.0, -2.0f, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0 };
    //float weights[] =
    //{
    //    0.01621622, 0.05405405, 0.12162162, 0.19459459, 0.22702703,
	//	0.19459459, 0.12162162, 0.05405405, 0.01621622
    //};
    float offsets[] =
    {
        -3.23076923, -1.38461538, 0.0, 1.38461538, 3.23076923
    };
    float weights[] =
    {
        0.07027027, 0.31621622, 0.22702703, 0.31621622, 0.07027027
    };
    for (int i = 0; i < 5; i++)
    {
        float offset = offsets[i] *  GetSourceTexelSize().y;
        color += GetSource(input.screenUV + float2(0.0, offset)).rgb * weights[i];
    }
    return float4(color, 1.0);

}

Varyings DefaultPassVertex(uint vertexID :SV_VertexID)
{
    Varyings output;
    output.positionCS = float4(vertexID <= 1 ? -1.0 : 3.0, vertexID == 1 ? 3.0 : -1.0, 0.0, 1.0);
    output.screenUV = float2(vertexID <= 1 ? 0.0 : 2.0, vertexID == 1 ? 2.0 : 0.0);
    // 手动翻转屏幕UV坐标
    if (_ProjectionParams.x < 0.0)
    {
        output.screenUV.y = 1.0 - output.screenUV.y;
    }
    return output;
}
float4 CopyPassFragment(Varyings input) : SV_TARGET{
    //return float4(input.screenUV, 0.0, 1.0);
    return GetSource(input.screenUV);
}

float4 BloomPrefilterPassFragment(Varyings input) :SV_TARGET
{
    float3 color = ApplyBloomThreshold(GetSource(input.screenUV).rgb);
    return float4(color, 1.0);
}

// 淡化屏幕光硕
float4 BloomPrefilterFirefliesPassFragment(Varyings input) : SV_TARGET
{
    float3 color = 0.0;
    float weightSum = 0.0;
   // float2 offsets[] =
   // {
    //    float2(0.0, 0.0),
    //    float2(-1.0, -1.0), float2(-1.0, 1.0), float2(1.0, -1.0),float2(1.0, 1.0),
    //    float2(-1.0, 0.0), float2(1.0, 0.0), float2(0.0, -1.0), float2(0.0, 1.0),
   // };
    float2 offsets[] =
    {
        float2(0.0, 0.0),
        float2(-1.0, -1.0), float2(-1.0, 1.0), float2(1.0, -1.0), float2(1.0, 1.0)
    };
    
    for (int i = 0; i < 5; i++)
    {
        float3 c = GetSource(input.screenUV + offsets[i] * GetSourceTexelSize().xy * 2.0).rbg;
        float w = 1.0 / (Luminance(c) + 1.0);
        color += c * w;
        weightSum += w;
        //c = ApplyBloomThreshold(c);
        //color += c;
    }
    color /= weightSum;
    //color *= 1.0 / 9.0;
    
    return float4(color, 1.0);
}


#endif
