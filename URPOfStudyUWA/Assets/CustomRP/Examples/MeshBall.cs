using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MeshBall : MonoBehaviour
{
    static int baseColorId = Shader.PropertyToID("_BaseColor");
    static int metallicId = Shader.PropertyToID("_Metallic");
    static int smoothnessId = Shader.PropertyToID("_Smoothness");

    static int cutoffId = Shader.PropertyToID("_Cutoff");

    [SerializeField]
    Mesh mesh = default;
    [SerializeField]
    Material material = default;

    Matrix4x4[] matrices = new Matrix4x4[1023];
    Vector4[] baseColors = new Vector4[1023];

    // 添加金属度和光滑度属性调节参数
    float[] metallic = new float[1023];
    float[] smoothness = new float[1023];

    [SerializeField, Range(0f, 1f)]
    float cutoff = 0.5f;

    MaterialPropertyBlock block;

    // LPPV代理
    [SerializeField]
    LightProbeProxyVolume lightProbeVolume = null;

    private void Awake()
    {
        for (int i = 0; i < matrices.Length; i++)
        {
            matrices[i] = Matrix4x4.TRS(Random.insideUnitSphere * 10f, 
                Quaternion.Euler(Random.value * 360f, Random.value * 360f, Random.value * 360f),
                Vector3.one * Random.Range(0.5f, 1.5f));
            baseColors[i] = new Vector4(Random.value, Random.value, Random.value, Random.Range(0.5f, 1f));

            // 金属度和光滑度按条件随机
            metallic[i] = Random.value < 0.25f ? 1f : 0f;
            smoothness[i] = Random.Range(0.05f, 0.95f);
        }
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
            block.SetVectorArray(baseColorId, baseColors);

            block.SetFloatArray(metallicId, metallic);
            block.SetFloatArray(smoothnessId, smoothness);
            if (!lightProbeVolume)
            {
                //给每个小球添加光照探针
                var positions = new Vector3[1023];
                for (int i = 0; i < matrices.Length; i++)
                {
                    positions[i] = matrices[i].GetColumn(3);    // 得到实例位置
                }
                // 创建每个对象实例的光照探针
                var lightProbes = new SphericalHarmonicsL2[1023];
                // 填充数据
                LightProbes.CalculateInterpolatedLightAndOcclusionProbes(positions, lightProbes, null);
                // 将光照探针数据复制到材质属性块
                block.CopySHCoefficientArraysFrom(lightProbes);
            }
            block.SetFloat(cutoffId, cutoff);
        }
        // 添加5个参数来使用光照探针
        Graphics.DrawMeshInstanced(mesh, 0, material, matrices, 1023, block, ShadowCastingMode.On, true, 0, null, lightProbeVolume ? LightProbeUsage.UseProxyVolume : LightProbeUsage.CustomProvided, lightProbeVolume);
    }
}
