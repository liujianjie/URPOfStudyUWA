using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/CustomRenderPineAsset")]
public class CustomRenderPineAsset : RenderPipelineAsset
{
    // 定义合批状态字段
    [SerializeField]
    bool useDynamicBatching = true, useGPUInstancing = true, useSRPBathcer = true;

    // 是否使用逐对象光照
    [SerializeField]
    bool useLightsPerObject;

    // 阴影设置
    [SerializeField]
    ShadowSettings shadows = default;
    // 重写抽象方法，需要防护一个RenderPipeLine实例对象
    protected override RenderPipeline CreatePipeline()
    {
        return new CustomRenderPipeline(useDynamicBatching, useGPUInstancing, useSRPBathcer, useLightsPerObject, shadows);
    }

}
