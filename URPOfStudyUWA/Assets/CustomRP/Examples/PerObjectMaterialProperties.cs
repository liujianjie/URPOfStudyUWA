using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    static int baseColorID = Shader.PropertyToID("_BaseColor");
    static int cutoffId = Shader.PropertyToID("_Cutoff");

    static int metallicId = Shader.PropertyToID("_Metallic");
    static int smoothnessId = Shader.PropertyToID("_Smoothness");

    static MaterialPropertyBlock block;

    [SerializeField]
    Color baseColor = Color.white;

    [SerializeField, Range(0f, 1f)]
    float cutoff = 0.5f;

    // 金属度和光滑度
    [SerializeField, Range(0f, 1f)]
    float metallic = 0f;
    [SerializeField, Range(0f, 1f)]
    float smoothness = 0.5f;

    private void OnValidate()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
        }
        // 设置材质属性
        block.SetColor(baseColorID, baseColor);
        block.SetFloat(cutoffId, cutoff);

        block.SetFloat(metallicId, metallic);
        block.SetFloat(smoothnessId, smoothness);

        GetComponent<Renderer>().SetPropertyBlock(block);
    }
    private void Awake()
    {
        OnValidate();
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
