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

    CullingResults cullingResults;

    ShadowSettings settings;

    // 可投射阴影的定向光数量
    const int maxShadowedDirectionalLightCount = 4;

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
        this.cullingResults = cullingResults;
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
            && cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b))
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

        buffer.BeginSample(bufferName);
        ExecuteBuffer();
        // 遍历所有方向光渲染阴影
        //for (int i = 0; i < ShadowedDirectionalLightCount; i++)
        //{
        //    RenderDirectionalShadows(i, atlasSize);
        //}
        // 要分割的图块大小和数量
        int split = ShadowedDirectionalLightCount <= 1 ? 1 : 2;
        int tileSize = atlasSize / split;

        for (int i = 0; i < ShadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, split, tileSize);
        }
        buffer.EndSample(bufferName);

        ExecuteBuffer();


    }
    /// <summary>
    /// 渲染单个光源阴影
    /// </summary>
    /// <param name="index">投射阴影的灯光索引</param>
    /// <param name="tileSize">阴影贴图再阴影图集中所占的图块大小</param>
    void RenderDirectionalShadows(int index, int split, int tileSize)
    {
        ShadowedDirectionalLight light = ShadowedDirectionalLights[index];
        var shadowSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);
        // 找出与光的方向匹配的视图与投影矩阵，并给我们一个裁剪空间的立方体，该立方体与包含光源阴影的摄像机的可见区域重叠
        cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(light.visibleLightIndex, 0, 1, Vector3.zero, tileSize, 0f,
            out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData);

        shadowSettings.splitData = splitData;

        // 设置渲染视口
        SetTileViewport(index, split, tileSize);
        // 设置视图投影矩阵
        buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix); // 应用获取的视图和投影矩阵
        ExecuteBuffer();
        context.DrawShadows(ref shadowSettings);
    }
    // 调整渲染视口来渲染单个图块
    void SetTileViewport(int index, int split, float tileSize)
    {
        // 计算索引图块的偏移位置
        Vector2 offset = new Vector2(index % split, index / split);
        // 设置渲染视口，拆分多个图块
        buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
    }
    // 释放临时渲染纹理
    public void Cleanup()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }
}
