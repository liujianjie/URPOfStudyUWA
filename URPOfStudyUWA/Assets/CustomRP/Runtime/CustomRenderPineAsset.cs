using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/CustomRenderPineAsset")]
public class CustomRenderPineAsset : RenderPipelineAsset
{
    // 重写抽象方法，需要防护一个RenderPipeLine实例对象
    protected override RenderPipeline CreatePipeline()
    {
        return new CustomRenderPipeline();
    }

}
