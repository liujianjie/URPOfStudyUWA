Shader "Hidden/Custom RP/Post FX Stack"
{
    SubShader
    {   
		Cull Off
		ZTest Always
		ZWrite Off

        HLSLINCLUDE
		#include "../ShaderLibrary/Common.hlsl"
		#include "PostFXStackPasses.hlsl"
		ENDHLSL
        Pass
        {
			Name "Bloom Combine"

           HLSLPROGRAM
		   #pragma target 3.5
           #pragma vertex DefaultPassVertex
           #pragma fragment BloomCombinePassFragment
           ENDHLSL
        }
        Pass
        {
			Name "Bloom Horizontal"

           HLSLPROGRAM
		   #pragma target 3.5
           #pragma vertex DefaultPassVertex
           #pragma fragment BloomHorizontalPassFragment
           #pragma fragment BloomVerticalPassFragment
           ENDHLSL
        }
        Pass
        {
			Name "Copy"

           HLSLPROGRAM
		   #pragma target 3.5
           #pragma vertex DefaultPassVertex
           #pragma fragment CopyPassFragment
           ENDHLSL
        }
    }
}