using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.GlobalIllumination;
using LightType = UnityEngine.LightType;
using Unity.Collections;
/// <summary>
/// 自定义渲染管线实例
/// </summary>
public partial class CustomRenderPipeline
{
    partial void InitializeForEditor();

#if UNITY_EDITOR
    static Lightmapping.RequestLightsDelegate lightsDelegate = (Light[] lights, NativeArray<LightDataGI> output) => 
    {
        var lightData = new LightDataGI();
        for(int i =0; i < lights.Length; i++)
        {
            Light light = lights[i];
            switch (light.type)
            {
                case LightType.Directional:
                    var directionalLight = new DirectionalLight();
                    LightmapperUtils.Extract(light, ref directionalLight);
                    lightData.Init(ref directionalLight);
                    break;
                case LightType.Point:
                    var pointLight = new PointLight();
                    LightmapperUtils.Extract(light, ref pointLight);
                    lightData.Init(ref pointLight);
                    break;
                case LightType.Spot:
                    var spotLight = new SpotLight();
                    LightmapperUtils.Extract(light, ref spotLight);
                    spotLight.innerConeAngle = light.innerSpotAngle * Mathf.Deg2Rad;
                    spotLight.angularFalloff = AngularFalloffType.AnalyticAndInnerAngle;
                    lightData.Init(ref spotLight);
                    break;

                case LightType.Area:
                    var rectangleLight = new RectangleLight();
                    LightmapperUtils.Extract(light, ref rectangleLight);
                    rectangleLight.mode = LightMode.Baked;
                    lightData.Init(ref rectangleLight);
                    break;

                // 默认调用光照数据的InitNoBake方法，传入光源的实例ID，指示Unity不要烘焙光照
                default:
                    lightData.InitNoBake(light.GetInstanceID());
                    break;
            }
            // 所有的灯光数据的衰减类型设置为
            lightData.falloff = FalloffType.InverseSquared;
            output[i] = lightData;
        }
    };
    // 通过unity编辑器中执行光照烘焙之前提供一个委托方法，来告诉unity使用不同的衰减
    partial void InitializeForEditor()
    {
        Lightmapping.SetDelegate(lightsDelegate);
    }
    // 清理和重置委托
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        Lightmapping.ResetDelegate();
    }
#endif
}