// unity标准输入库
#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// 根据物体的表面信息获取最终的光照结果
float3 GetLighting(Surface surface)
{
    return surface.normal.y;
}

#endif