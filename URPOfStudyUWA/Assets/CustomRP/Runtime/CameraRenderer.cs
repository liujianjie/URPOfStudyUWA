using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer
{
    ScriptableRenderContext context;
    Camera camera;
    Lighting lighting = new Lighting();

    public void Render(ScriptableRenderContext context, Camera camera,
        bool useDynamicBatching, bool useGPUInstancing,
        ShadowSettings shadowSettings)
    {
        this.context = context;
        this.camera = camera;
        // 设置缓冲区的名字
        PrepareBuffer();

        // 在game视图绘制的几何体也绘制到scene视图中
        PrepareForSceneWindow();

        if (!Cull(shadowSettings.maxDistance))
        {
            return;
        }

        Setup();
        // 光源数据和阴影数据发送到GPU计算光照
        lighting.Setup(context, cullingResults, shadowSettings);
        // 绘制几何体
        DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
        // 绘制SRP不支持的着色器类型
        DrawUnsupportedShaders();
        // 绘制Gizmos
        DrawGizmos();
        Submit();
    }
    /// <summary>
    /// 设置相机的属性和矩阵
    /// </summary>
    void Setup()
    {
        // 设置相机的属性和矩阵
        context.SetupCameraProperties(camera);

        // 得到相机的clear flags
        CameraClearFlags flags = camera.clearFlags;

        // 设置相机的清除状态
        buffer.ClearRenderTarget(flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color, 
            flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.white);
        // 为保证下一帧渲染正确，需要清除上一帧的渲染结果
        //buffer.ClearRenderTarget(true, true, Color.clear);

        // 自定义渲染
        buffer.BeginSample(SampleName); // 开始采样
        ExecuteBuffer();    // 执行缓冲区命令

    }
    /// <summary>
    /// 执行缓冲区命令：使用和清除缓冲区通常是配套使用的
    /// </summary>
    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
    static ShaderTagId litShaderTagId = new ShaderTagId("CustomLit");


    /// <summary>
    /// 绘制可见物
    /// </summary>
    void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing)
    {
        // 设置绘制顺序和指定渲染相机
        var sortingSettings = new SortingSettings(camera)
        {
            criteria = SortingCriteria.CommonOpaque
        };
        // 设置绘制的shader Pass 和排序模式
        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings)
        {
            // 设置渲染时批处理的使用状态
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing
        };
        // 渲染customelit表示的pass块
        drawingSettings.SetShaderPassName(1, litShaderTagId);

        // 设置哪些类型的渲染队列可以被绘制
        var filteringSettings = new FilteringSettings(RenderQueueRange.all);

        // 1.绘制不透明物体
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

        // 2.绘制天空盒
        context.DrawSkybox(camera);

        sortingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortingSettings;
        // 只绘制RenderQueue为Transparent的物体
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        // 3.绘制透明物体
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }
    /// <summary>
    /// 提交缓冲区渲染命令
    /// </summary>
    void Submit()
    {
        buffer.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();       // 提交缓冲区渲染命令才进行这一帧的渲染
    }
    // 缓冲区，用来绘制场景的其它几何图像
    const string bufferName = "My Render Camera";
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };

    // 存储剔除后的结果数据
    CullingResults cullingResults;
    /// <summary>
    /// 剔除
    /// </summary>
    /// <returns></returns>
    bool Cull(float maxShadowDistance)
    {
        // 获取相机的剔除参数
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            // 得到最大阴影距离，和相机远截面作比较，取最小的那个作为阴影距离
            p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
            // 剔除
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }


    
}
