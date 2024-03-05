using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows 
{
    const string bufferName = "Shadows";
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };
    ScriptableRenderContext context;

    CullingResults culllingResults;

    ShadowSettings settings;

    // 可投射阴影的定向光数量
    const int maxShadowedDirectionalLightCount = 1;

    struct ShadowedDirectionalLight
    {
        public int visibleLightIndex;
    }
    // 存储可投射阴影的可见光源的索引
    ShadowedDirectionalLight[] ShadowedDirectionalLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];

    // 已存储的可投射阴影的平行光数量
    int ShadowedDirectionalLightCount;

    // 创建一张rendertexture
    static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults,
        ShadowSettings settings)
    {
        this.context = context;
        this.culllingResults = cullingResults;
        this.settings = settings;
        ShadowedDirectionalLightCount = 0;
    }
    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    // 存储可见光的阴影数据
    public void ReserveDirectionalShadows(Light light, int visibleLightIndex)
    {
        // 存储可见光源的索引，前提是光源开启了阴影投射并且阴影强度不能为0
        // 是否在阴影最大投射距离内，有被该光源影响并且需要投射的物体存在，如果没有就不需要渲染该光源的阴影贴图了
        if (ShadowedDirectionalLightCount < maxShadowedDirectionalLightCount && light.shadows != LightShadows.None && light.shadowStrength > 0f
            && culllingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b))
        {
            ShadowedDirectionalLights[ShadowedDirectionalLightCount++] = new ShadowedDirectionalLight { visibleLightIndex = visibleLightIndex };
        }
    }
    // 阴影渲染
    public void Render()
    {
        if (ShadowedDirectionalLightCount > 0)
        {
            RenderDirectionalShadows();
        }
    }
    // 渲染定向光阴影
    void RenderDirectionalShadows()
    {
        // 创建rendertexture，并指定该类型是阴影贴图
        int atlasSize = (int)settings.directional.atlasSize;
        buffer.GetTemporaryRT(dirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        // 指定渲染数据存储到RT中
        buffer.SetRenderTarget(dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);

        // 清除深度缓冲区
        buffer.ClearRenderTarget(true, false, Color.clear);
        ExecuteBuffer();

    }
    // 释放临时渲染纹理
    public void Cleanup()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }
}
