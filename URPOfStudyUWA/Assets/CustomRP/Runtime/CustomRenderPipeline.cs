﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 自定义渲染管线实例
/// </summary>
public partial class CustomRenderPipeline : RenderPipeline
{
    CameraRenderer renderer = new CameraRenderer();
    bool useDynamicBatching, useGPUInstancing;
    //阴影的配置
    ShadowSettings shadowSettings;
    // 是否使用逐对象光照
    bool useLightsPerObject;
    bool allowHDR;

    PostFXSettings postFXSettings;

    public CustomRenderPipeline(bool allowHDR, bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, bool useLightsPerObject, 
        ShadowSettings shadowSettings, PostFXSettings postFXSettings)
    {
        this.allowHDR = allowHDR;
        this.shadowSettings = shadowSettings;

        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        this.useLightsPerObject = useLightsPerObject;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        //灯光使用线性强度
        GraphicsSettings.lightsUseLinearIntensity = true;
        this.postFXSettings = postFXSettings;

        InitializeForEditor();
    }
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        //遍历所有相机单独渲染
        foreach (Camera camera in cameras)
        {
            renderer.Render(context, camera, allowHDR,useDynamicBatching, useGPUInstancing, useLightsPerObject, shadowSettings, postFXSettings);
        }
    }
}
