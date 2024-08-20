#ifndef CUSTOM_POST_FX_PASSES_INCLUDED
#define CUSTOM_POST_FX_PASSES_INCLUDED

struct Varyings
{
    float4 positionCS : SV_POSITION;    // 裁剪空间位置
    float2 screenUV : VAR_SCREEN_UV;    // 屏幕空间uv坐标
};

TEXTURE2D(_PostFXSource);
SAMPLER(sampler_linear_clamp);

float4 GetSource(float2 screenUV)
{
    return SAMPLE_TEXTURE2D_LOD(_PostFXSource, sampler_linear_clamp, screenUV, 0);
    //return SAMPLE_TEXTURE2D(_PostFXSource, sampler_linear_clamp, screenUV);
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


#endif
