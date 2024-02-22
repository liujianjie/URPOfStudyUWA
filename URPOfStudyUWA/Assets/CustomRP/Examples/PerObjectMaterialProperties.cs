using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    static int baseColorID = Shader.PropertyToID("_BaseColor");

    [SerializeField]
    Color baseColor = Color.white;
    static MaterialPropertyBlock block;

    private void OnValidate()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
        }
        // 设置材质属性
        block.SetColor(baseColorID, baseColor);

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
