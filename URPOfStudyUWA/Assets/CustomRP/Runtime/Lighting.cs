using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class Lighting 
{
    const string bufferName = "Lighting";

    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName,
    };

    // 限制最大可见平行光的数量为4
    const int maxDirLightCount = 4;

    // 定义了2个着色器标志ID字段用于将灯光发送到GPU的对应属性中
    static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount");
    static int dirLightColorId = Shader.PropertyToID("_DirectionalLightColors");
    static int dirLightDirectionId = Shader.PropertyToID("_DirectionalLightDirections");
    static int dirLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowData");

    // 存储可见光的颜色和方向
    static Vector4[] dirLightColors = new Vector4[maxDirLightCount];
    static Vector4[] dirLightDirections = new Vector4[maxDirLightCount];
    // 存储阴影数据
    static Vector4[] dirLightShadowData = new Vector4[maxDirLightCount];

    // 存储相机剔除后的结果
    CullingResults cullingResults;
    Shadows shadows = new Shadows();

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
    {
        this.cullingResults = cullingResults;
        buffer.BeginSample(bufferName);
        // 传递阴影数据
        shadows.Setup(context, cullingResults, shadowSettings);
        // 发送光源数据
        //SetupDirectionalLight();
        SetupLights();

        shadows.Render();

        buffer.EndSample(bufferName);

        context.ExecuteCommandBuffer(buffer);

        buffer.Clear();
    }
    // 发送多个光源的数据
    void SetupLights()
    {
        // 得到所有可见光
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;

        int dirLightCount = 0;
        for(int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight visibleLight = visibleLights[i];
            // 如果是方向光，我们才进行数据存储
            if(visibleLight.lightType == LightType.Directional)
            {
                // visiblelight结构很大，我们改为传递引用不是传递值，这样不会有副本
                SetupDirectionalLight(dirLightCount++, ref visibleLight);
                // 当超过灯光限制数量中止循环
                if (dirLightCount >= maxDirLightCount)
                {
                    break;
                }
            }
        }

        buffer.SetGlobalInt(dirLightCountId, dirLightCount);
        buffer.SetGlobalVectorArray(dirLightColorId, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirectionId, dirLightDirections);
        buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
    }

    // 将场景主光源的光照颜色和方向传递给GPU
    void SetupDirectionalLight(int index, ref VisibleLight visibleLight)
    {
        dirLightColors[index] = visibleLight.finalColor;
        dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);// 第三列是光照方向，取反是来源方向

        shadows.ReserveDirectionalShadows(visibleLight.light, index);
        // 存储阴影数据
        dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, index);

        //Light light = RenderSettings.sun;
        //// 灯光的颜色我们再乘上光强作为最终颜色
        //buffer.SetGlobalVector(dirLightColorId, light.color.linear * light.intensity);  // 获取灯光的颜色要转到线性空间，并乘以光照强度
        ////buffer.SetGlobalVector(dirLightColorId, Color.yellow * light.intensity);  // 获取灯光的颜色要转到线性空间，并乘以光照强度
        //buffer.SetGlobalVector(dirLightDirectionId, -light.transform.forward);          // 正前方取反作为光照方向，用的是光线的来源方向，而不是光线的照射方向
    }
    // 释放阴影贴图RT内存
    public void Cleanup()
    {
        shadows.Cleanup();
    }

}
