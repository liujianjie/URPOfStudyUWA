Shader "CustomeRP/Unlit"
{
    Properties{

        _BaseColor("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader
    {
        Pass{
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
