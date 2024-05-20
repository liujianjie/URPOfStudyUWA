using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{
    private const string bufferName = "Shadows";

    private CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };

    private ScriptableRenderContext context;

    private CullingResults cullingResults;

    private ShadowSettings settings;

    // 可投射阴影的定向光数量
    private const int maxShadowedDirectionalLightCount = 4;

    private struct ShadowedDirectionalLight
    {
        public int visibleLightIndex;

        // 斜度比例偏差值
        public float slopeScaleBias;

        // 阴影视椎体近裁剪平面偏移
        public float nearPlaneOffset;
    }

    // 存储可投射阴影的可见光源的索引
    private ShadowedDirectionalLight[] ShadowedDirectionalLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];

    // 已存储的可投射阴影的平行光数量
    private int ShadowedDirectionalLightCount;

    // 创建一张rendertexture
    private static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");

    private static int dirShadowMatricesId = Shader.PropertyToID("_DirectionalShadowMatrices");

    // 存储阴影转换矩阵-为了找到对应在世界空间的阴影纹理坐标。光源的级联阴影转换矩阵
    private static Matrix4x4[] dirShadowMatrices = new Matrix4x4[maxShadowedDirectionalLightCount * maxCascades];

    // 最大级联数量
    private const int maxCascades = 4;

    // 定义级联包围球和级联数量的着色器标志ID
    private static int cascadeCountId = Shader.PropertyToID("_CascadeCount");

    private static int cascadeCullingSpherersId = Shader.PropertyToID("_CascadeCullingSpheres");

    //static int shadowDistanceId = Shader.PropertyToID("_ShadowDistance");
    // 阴影过度距离
    private static int shadowDistanceFadeId = Shader.PropertyToID("_ShadowDistanceFade");

    private static Vector4[] cascadeCullingSpheres = new Vector4[maxCascades];

    // 级联数据
    private static int cascadeDataId = Shader.PropertyToID("_CascadeData");

    private static Vector4[] cascadeData = new Vector4[maxCascades];

    // PCF滤波模式
    private static string[] directionalFilterKeywords =
    {
        "_DIRECTIONAL_PCF3",
        "_DIRECTIONAL_PCF5",
        "_DIRECTIONAL_PCF7"
    };

    private static int shadowAtlasSizeId = Shader.PropertyToID("_ShadowAtlasSize");
    private static string[] cascadeBlendKeywords = { "_CASCADE_BLEND_SOFT", "_CASCADE_BLEND_DITHER" };

    // 设置关键字开启哪种PCF滤波模式
    private void SetKeywords(string[] keywords, int enabledIndex)
    {
        if (enabledIndex <= -1)
        {
            return;
        }
        //int enabledIndex = (int)settings.directional.filter - 1;
        for (int i = 0; i < keywords.Length; i++)
        {
            if (i == enabledIndex)
            {
                buffer.EnableShaderKeyword(keywords[i]);
            }
            else
            {
                buffer.DisableShaderKeyword(keywords[i]);
            }
        }
    }

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults,
        ShadowSettings settings)
    {
        this.context = context;
        this.cullingResults = cullingResults;
        this.settings = settings;
        ShadowedDirectionalLightCount = 0;
    }

    private void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    /// <summary>
    /// 存储可见光的阴影数据,需要知道阴影所在的图块索引
    /// </summary>
    /// <param name="light"></param>
    /// <param name="visibleLightIndex"></param>
    public Vector2 ReserveDirectionalShadows(Light light, int visibleLightIndex)
    {
        // 存储可见光源的索引，前提是光源开启了阴影投射并且阴影强度不能为0
        // 是否在阴影最大投射距离内，有被该光源影响并且需要投射的物体存在，如果没有就不需要渲染该光源的阴影贴图了
        if (ShadowedDirectionalLightCount < maxShadowedDirectionalLightCount
            && light.shadows != LightShadows.None && light.shadowStrength > 0f
            && cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b))
        {
            ShadowedDirectionalLights[ShadowedDirectionalLightCount] = new ShadowedDirectionalLight { visibleLightIndex = visibleLightIndex, slopeScaleBias = light.shadowBias, nearPlaneOffset = light.shadowNearPlane };
            // 返回阴影强度和阴影图块索引
            return new Vector3(light.shadowStrength, settings.directional.cascadeCount * ShadowedDirectionalLightCount++, light.shadowNormalBias);
        }
        return Vector2.zero;
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
    private void RenderDirectionalShadows()
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
        // 要分割的图块大小和数量
        int tiles = ShadowedDirectionalLightCount * settings.directional.cascadeCount;
        int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
        int tileSize = atlasSize / split;

        // 遍历所有方向光渲染阴影
        for (int i = 0; i < ShadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, split, tileSize);
        }
        // 级联数量和包围球数据发送到GPU
        buffer.SetGlobalInt(cascadeCountId, settings.directional.cascadeCount);
        buffer.SetGlobalVectorArray(cascadeCullingSpherersId, cascadeCullingSpheres);

        // 阴影转换矩阵传入GPU
        buffer.SetGlobalMatrixArray(dirShadowMatricesId, dirShadowMatrices);

        //buffer.SetGlobalFloat(shadowDistanceId, settings.maxDistance);
        buffer.SetGlobalVector(shadowDistanceFadeId, new Vector4(1f / settings.maxDistance, 1f / settings.distanceFade));

        // 级联数据发送GPU
        buffer.SetGlobalVectorArray(cascadeDataId, cascadeData);
        // 阴影转换矩阵传入GPU
        buffer.SetGlobalMatrixArray(dirShadowMatricesId, dirShadowMatrices);

        // 设置关键字
        SetKeywords(directionalFilterKeywords, (int)settings.directional.filter - 1);
        SetKeywords(cascadeBlendKeywords, (int)settings.directional.cascadeBlend - 1);
        //Debug.Log("shadowAtlasSizeId " + shadowAtlasSizeId);
        // 传递图集大小和纹素大小
        buffer.SetGlobalVector(shadowAtlasSizeId, new Vector4(atlasSize, 1f / atlasSize));

        buffer.EndSample(bufferName);

        ExecuteBuffer();
    }

    /// <summary>
    /// 渲染单个光源阴影
    /// </summary>
    /// <param name="index">投射阴影的灯光索引</param>
    /// <param name="tileSize">阴影贴图再阴影图集中所占的图块大小</param>
    private void RenderDirectionalShadows(int index, int split, int tileSize)
    {
        ShadowedDirectionalLight light = ShadowedDirectionalLights[index];
        var shadowSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);
        // 设置渲染视口
        SetTileViewport(index, split, tileSize);
        // 得到级联阴影贴图需要的参数
        int cascadeCount = settings.directional.cascadeCount;
        int tileOffset = index * cascadeCount;
        Vector3 ratios = settings.directional.CascadeRatios;
        float cullingFactor = Mathf.Max(0f, 0.8f - settings.directional.cascadeFade);
        for (int i = 0; i < cascadeCount; i++)
        {
            // 找出与光的方向匹配的视图与投影矩阵，并给我们一个裁剪空间的立方体，该立方体与包含光源阴影的摄像机的可见区域重叠
            cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(light.visibleLightIndex, i, cascadeCount, ratios, tileSize, light.nearPlaneOffset,
                out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData);

            // 拿到第一个光源的包围球数据 = 所有光源使用相同的级联
            if (index == 0)
            {
                // 设置级联数据
                SetCascadeData(i, splitData.cullingSphere, tileSize);
            }
            // 剔除偏差
            splitData.shadowCascadeBlendCullingFactor = cullingFactor;
            shadowSettings.splitData = splitData;

            // 调整图块索引，它等于光源的图块片元加上级联的索引
            int tileIndex = tileOffset + i;

            // 投影矩阵乘以视图矩阵，得到从世界空间到灯光空间的转换矩阵
            dirShadowMatrices[tileIndex] =
                ConvertToAtlasMatrix(projectionMatrix * viewMatrix, SetTileViewport(tileIndex, split, tileSize), split);

            // 设置视图投影矩阵
            buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix); // 应用获取的视图和投影矩阵

            // 设置深度偏差
            //buffer.SetGlobalDepthBias(50000f, 0f);
            //buffer.SetGlobalDepthBias(0, 3f);
            buffer.SetGlobalDepthBias(0, light.slopeScaleBias);
            // 绘制阴影
            ExecuteBuffer();
            context.DrawShadows(ref shadowSettings);
            // 设斜度比例偏差值
            buffer.SetGlobalDepthBias(0f, 0f);
        }
        //break;
    }

    // 设置级联数据
    private void SetCascadeData(int index, Vector4 cullingSphere, float tileSize)
    {
        //// 包围球直径除以阴影图块尺寸 = 纹理像素大小
        //float texelSize = 2f * cullingSphere.w / tileSize;
        //// 得到半径的平方值。这样可以避免在着色器中进行平方运算。像素点到包围球的距离小于半径的平方值就在包围球内
        //cullingSphere.w *= cullingSphere.w;
        //cascadeCullingSpheres[index] = cullingSphere;
        //cascadeData[index] = new Vector4(1f / cullingSphere.w, texelSize * 1.4142136f);

        // 包围球直径除以阴影图块尺寸 = 纹理像素大小
        float texelSize = 2f * cullingSphere.w / tileSize;
        float filterSize = texelSize * ((float)settings.directional.filter + 1f);

        // 得到半径的平方值。这样可以避免x在着色器中进行平方运算。像素点到包围球的距离小于半径的平方值就在包围球内
        cullingSphere.w -= filterSize;
        cullingSphere.w *= cullingSphere.w;
        cascadeCullingSpheres[index] = cullingSphere;

        cascadeData[index] = new Vector4(1f / cullingSphere.w, filterSize * 1.4142136f);
    }

    // 调整渲染视口来渲染单个图块
    private Vector2 SetTileViewport(int index, int split, float tileSize)
    {
        // 计算索引图块的偏移位置
        Vector2 offset = new Vector2(index % split, index / split);
        // 设置渲染视口，拆分多个图块
        buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
        return offset;
    }

    // 因为是图集，需要得到拆分后的转换矩阵
    // 返回一个从世界空间到阴影图块空间的转换矩阵
    private Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 m, Vector2 offset, int split)
    {
        // 如果使用了反向zbuffer
        if (SystemInfo.usesReversedZBuffer)
        {
            m.m20 = -m.m20;
            m.m21 = -m.m21;
            m.m22 = -m.m22;
            m.m23 = -m.m23;
        }
        // 设置矩阵坐标- 这里不要重复计算
        //m.m00 = 0.5f * (m.m00 + m.m30);
        //m.m01 = 0.5f * (m.m01 + m.m31);
        //m.m02 = 0.5f * (m.m02 + m.m32);
        //m.m03 = 0.5f * (m.m03 + m.m33);

        //m.m10 = 0.5f * (m.m10 + m.m30);
        //m.m11 = 0.5f * (m.m11 + m.m31);
        //m.m12 = 0.5f * (m.m12 + m.m32);
        //m.m13 = 0.5f * (m.m13 + m.m33);

        //m.m20 = 0.5f * (m.m20 + m.m30);
        //m.m21 = 0.5f * (m.m21 + m.m31);
        //m.m22 = 0.5f * (m.m22 + m.m32);
        //m.m23 = 0.5f * (m.m23 + m.m33);

        // 设置矩阵坐标 - 图块的偏移和缩放也放进去
        float scale = 1f / split;
        m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
        m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
        m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
        m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;

        m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
        m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
        m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
        m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;

        m.m20 = (0.5f * (m.m20 + m.m30));
        m.m21 = (0.5f * (m.m21 + m.m31));
        m.m22 = (0.5f * (m.m22 + m.m32));
        m.m23 = (0.5f * (m.m23 + m.m33));
        return m;
    }

    // 释放临时渲染纹理
    public void Cleanup()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }
}