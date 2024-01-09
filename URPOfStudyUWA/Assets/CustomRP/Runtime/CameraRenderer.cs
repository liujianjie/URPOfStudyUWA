using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CameraRenderer
{

    ScriptableRenderContext context;
    Camera camera;
    public void Render(ScriptableRenderContext context, Camera camera)
    {
        this.context = context;
        this.camera = camera;

        Setup();
        DrawVisibleGeometry();
        Submit();
    }
    /// <summary>
    /// 设置相机的属性和矩阵
    /// </summary>
    void Setup()
    {
        // 设置相机的属性和矩阵
        context.SetupCameraProperties(camera);

        // 为保证下一帧渲染正确，需要清除上一帧的渲染结果
        buffer.ClearRenderTarget(true, true, Color.clear);

        // 自定义渲染
        buffer.BeginSample(bufferName); // 开始采样
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
    /// <summary>
    /// 绘制可见物
    /// </summary>
    void DrawVisibleGeometry()
    {
        context.DrawSkybox(camera);
    }
    /// <summary>
    /// 提交缓冲区渲染命令
    /// </summary>
    void Submit()
    {
        buffer.EndSample(bufferName);
        ExecuteBuffer();
        context.Submit();       // 提交缓冲区渲染命令才进行这一帧的渲染
    }
    // 缓冲区，用来绘制场景的其它几何图像
    const string bufferName = "My Render Camera";
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };
}
