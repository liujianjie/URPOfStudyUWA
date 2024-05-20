// 灯光数据相关库
#ifndef CUSTOM_GL_INCLUDED
#define CUSTOM_GL_INCLUDED

struct GI
{
    // 漫反射颜色
    float3 diffuse;
};

GI GetGI(float2 lightMapUV)
{
    GI gi;
    gi.diffuse = float3(lightMapUV, 0.0);
    return gi;
}

#endif