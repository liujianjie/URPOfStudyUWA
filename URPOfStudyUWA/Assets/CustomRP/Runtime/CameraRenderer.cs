using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer
{
    // 声明这个方法
    partial void DrawUnsupportedShaders();
#if UNITY_EDITOR
    // SRP不支持的着色器标签类型
    static ShaderTagId[] legacyShaderTagIds =
    {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"), 
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM"),
    };
    // 绘制成使用错误材质的粉红颜色
    static Material errorMaterial;

    /// <summary>
    /// 绘制SRP不支持的着色器类型
    /// </summary>
    partial void DrawUnsupportedShaders()
    {
        // 不支持的ShaderTag类型我们使用错误材质专用Shader来渲染（粉色颜色）
        if (errorMaterial == null)
        {
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }


        // 数组第一个元素用来构造DrawingSettings对象的时候设置
        var drawingSettings = new DrawingSettings(legacyShaderTagIds[0], new SortingSettings(camera))
        {
            overrideMaterial = errorMaterial
        };
        for(int i = 1; i <legacyShaderTagIds.Length; i++)
        {
            // 遍历数组逐个设置着色器的PassName，从i=1开始
            drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
        }
        // 使用默认设置即可，反正画出来的都是不支持的
        var filteringSettings = FilteringSettings.defaultValue;
        // 绘制不支持的shadertag类型的物体
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }
#endif
}
