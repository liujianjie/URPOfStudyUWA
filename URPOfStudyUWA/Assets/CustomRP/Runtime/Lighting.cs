﻿using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 灯光管理类
/// </summary>
public class Lighting
{

	const string bufferName = "Lighting";

	CommandBuffer buffer = new CommandBuffer
	{
		name = bufferName
	};
    //设置最大可见定向光数量
    const int maxDirLightCount = 4;
    const int maxOtherLightCount = 64;


    static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount");
    static int dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors");
    static int dirLightDirectionsId = Shader.PropertyToID("_DirectionalLightDirections");
    static int dirLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowData");

    static int otherLightCountId = Shader.PropertyToID("_OtherLightCount");
    static int otherLightColorsId = Shader.PropertyToID("_OtherLightColors");
    static int otherLightPositionsId = Shader.PropertyToID("_OtherLightPositions");
    //存储定向光的颜色和方向
    static Vector4[] dirLightColors = new Vector4[maxDirLightCount];
    static Vector4[] dirLightDirections = new Vector4[maxDirLightCount];
    //存储定向光的阴影数据
    static Vector4[] dirLightShadowData = new Vector4[maxDirLightCount];

    //存储其它类型光源的颜色和位置数据
    static Vector4[] otherLightColors = new Vector4[maxOtherLightCount];
    static Vector4[] otherLightPositions = new Vector4[maxOtherLightCount];
    //存储相机剔除后的结果
    CullingResults cullingResults;

    Shadows shadows = new Shadows();
    //初始化设置
    public void Setup(ScriptableRenderContext context, CullingResults cullingResults,ShadowSettings shadowSettings)
	{
        this.cullingResults = cullingResults;
        buffer.BeginSample(bufferName);
        //阴影的初始化设置
        shadows.Setup(context, cullingResults, shadowSettings);
        //存储并发送所有光源数据
        SetupLights();
        //渲染阴影
        shadows.Render();
        buffer.EndSample(bufferName);
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}
	/// <summary>
    /// 存储定向光的数据
    /// </summary>
    /// <param name="index"></param>
    /// <param name="visibleIndex"></param>
    /// <param name="visibleLight"></param>
    /// <param name="light"></param>
	void SetupDirectionalLight(int index, ref VisibleLight visibleLight) {
        dirLightColors[index] = visibleLight.finalColor;
        //通过VisibleLight.localToWorldMatrix属性找到前向矢量,它在矩阵第三列，还要进行取反
        dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        //存储阴影数据
        dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, index);
    }
    /// <summary>
    /// 存储点光源的数据
    /// </summary>
    /// <param name="index"></param>
    /// <param name="visibleIndex"></param>
    /// <param name="visibleLight"></param>
    /// <param name="light"></param>
    void SetupPointLight(int index, ref VisibleLight visibleLight)
    {
        dirLightColors[index] = visibleLight.finalColor;
        //通过VisibleLight.localToWorldMatrix属性找到前向矢量,它在矩阵第三列，还要进行取反
        dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        //存储阴影数据
        dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, index);
    }
    /// <summary>
    /// 存储并发送所有光源数据
    /// </summary>
    /// <param name="useLightsPerObject"></param>
    /// <param name="renderingLayerMask"></param>
    void SetupLights() {
        //得到所有影响相机渲染物体的可见光数据
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
        
        int dirLightCount = 0, otherLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            int newIndex = -1;
            VisibleLight visibleLight = visibleLights[i];

            switch (visibleLight.lightType)
            {
                case LightType.Directional:
                    //VisibleLight结构很大,我们改为传递引用不是传递值，这样不会生成副本
                    if (dirLightCount < maxDirLightCount)
                    {
                        newIndex = otherLightCount;
                        SetupDirectionalLight(dirLightCount++, ref visibleLight);
                    }
                    break;
                case LightType.Point:
                    if (otherLightCount < maxOtherLightCount)
                    {
                        newIndex = otherLightCount;
                        SetupPointLight(dirLightCount++, ref visibleLight);
                    }
                    break;
                case LightType.Spot:
                    //if (otherLightCount < maxOtherLightCount)
                    //{
                    //    newIndex = otherLightCount;
                    //    SetupSpotLight(dirLightCount++, ref visibleLight);
                    //}
                    break;
            }
            if (visibleLight.lightType == LightType.Directional)
            {

            }
        }

        buffer.SetGlobalInt(dirLightCountId, dirLightCount);
        buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
        buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
    }
    //释放申请的RT内存
    public void Cleanup()
    {
        shadows.Cleanup();
    }
}
