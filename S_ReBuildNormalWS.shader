Shader "S_ReBuildNormalVS"
{
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        Cull Off
        ZWrite Off
        ZTest Always
        
        HLSLINCLUDE
        #include "ReBuildNormalWS.hlsl"
        ENDHLSL
        
        Pass
        {
            Name "ReBuild Position WS"
            
            HLSLPROGRAM
            #pragma shader_feature _RebuildNormal_Quality_Low _RebuildNormal_Quality_Medium _RebuildNormal_Quality_High
            
            #pragma vertex ReBuildNormalVS
            #pragma fragment ReBuildNormalPS
            ENDHLSL

            
        }
    }
}
