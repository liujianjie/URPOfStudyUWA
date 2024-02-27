using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting 
{
    const string bufferName = "Lighting";

    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName,
    };
    // 定义了2个着色器标志ID字段用于将灯光发送到GPU的对应属性中
    static int dirLightColorId = Shader.PropertyToID("_DirectionalLightColor");
    static int dirLightDirectionId = Shader.PropertyToID("_DirectionalLightDirection");

    public void Setup(ScriptableRenderContext context)
    {
        buffer.BeginSample(bufferName);
        // 发送光源数据
        SetupDirectionalLight();
        buffer.EndSample(bufferName);

        context.ExecuteCommandBuffer(buffer);

        buffer.Clear();
    }
    // 将场景主光源的光照颜色和方向传递给GPU
    void SetupDirectionalLight()
    {
        Light light = RenderSettings.sun;
        // 灯光的颜色我们再乘上光强作为最终颜色
        buffer.SetGlobalVector(dirLightColorId, light.color.linear * light.intensity);  // 获取灯光的颜色要转到线性空间，并乘以光照强度
        //buffer.SetGlobalVector(dirLightColorId, Color.yellow * light.intensity);  // 获取灯光的颜色要转到线性空间，并乘以光照强度
        buffer.SetGlobalVector(dirLightDirectionId, -light.transform.forward);          // 正前方取反作为光照方向，用的是光线的来源方向，而不是光线的照射方向
    }
}
