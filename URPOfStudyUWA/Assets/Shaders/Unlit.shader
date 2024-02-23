Shader "CustomeRP/Unlit"
{
    Properties{
        _BaseMap("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // 设置混合模式
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
        // 默认写入深度缓冲区
        [Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
    }

    SubShader
    {
        Pass{
            // 定义混合而陌生
            Blend[_SrcBlend][_DstBlend]
            // 是否写入深度
            ZWrite[_ZWrite]
	        HLSLPROGRAM
            #pragma multi_compile_instancing
	        #pragma vertex UnlitPassVertex
	        #pragma fragment UnlitPassFragment
            #include "ShaderLibrary/Common.hlsl"
	        #include "UnlitPass.hlsl"
	        ENDHLSL
        }
    }
}
