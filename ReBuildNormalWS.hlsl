#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

#pragma region Variable
float4 _ViewSize;

TEXTURE2D(_MainTex);                            SAMPLER(sampler_MainTex);
TEXTURE2D_X_FLOAT(_CameraDepthTexture);         SAMPLER(sampler_CameraDepthTexture);
SamplerState sampler_LinearClamp;
SamplerState sampler_PointClamp;

struct VSInput
{
    float2 uv : TEXCOORD0;
    
    float4 positionOS : POSITION;
};

struct PSInput
{
    float2 uv : TEXCOORD0;

    float4 positionCS : SV_POSITION;
};
#pragma endregion 

PSInput ReBuildNormalVS(VSInput i)
{
    PSInput o = (PSInput)0;

    VertexPositionInputs vertexPosData = GetVertexPositionInputs(i.positionOS);
    o.positionCS = vertexPosData.positionCS;

    #if defined (UNITY_UV_STARTS_AT_TOP)
        i.uv = 1 - i.uv;
    #endif
    o.uv = i.uv;

    return o;
}

float GetDeviceDepth(float2 uv)
{
    return _CameraDepthTexture.SampleLevel(sampler_LinearClamp, uv, 0).r;
}
float3 ReBuildPosVS(float2 positionVP)
{
    positionVP *= _ViewSize.zw;
    
    float depth = GetDeviceDepth(positionVP);
    float3 positionNDC = float3(positionVP * 2.f - 1.f, depth);
    #if defined (UNITY_UV_STARTS_AT_TOP)
    positionNDC.y = - positionNDC.y;
    #endif
    
    float4 positionWS = mul(UNITY_MATRIX_I_P, float4(positionNDC, 1.f));
    positionWS.xyz /= positionWS.w;

    return positionWS;
}

float3 ReBuildNormalVS_Low(float2 uv)
{
    float3 positionVS = ReBuildPosVS(uv);
    
    return SafeNormalize(cross(ddx(positionVS), ddy(positionVS)));
}
float3 ReBuildNormalVS_Medium(float2 uv)
{
    float3 posVS_C = ReBuildPosVS(uv);
    float3 posVS_T = ReBuildPosVS(uv + float2(0, 1 ));
    float3 posVS_B = ReBuildPosVS(uv + float2(0, -1));
    float3 posVS_R = ReBuildPosVS(uv + float2(1, 0 ));
    float3 posVS_L = ReBuildPosVS(uv + float2(-1, 0));

    float3 depthDiffL = posVS_C - posVS_L;
    float3 depthDiffR = posVS_R - posVS_C;
    float3 depthDiffT = posVS_C - posVS_T;
    float3 depthDiffB = posVS_B - posVS_C;

    float3 horizionVec = abs(depthDiffL.z) < abs(depthDiffR.z) ? depthDiffL : depthDiffR;
    float3 verticalVec = abs(depthDiffT.z) < abs(depthDiffB.z) ? depthDiffT : depthDiffB;

    return SafeNormalize(cross(horizionVec, verticalVec));
}
float3 ReBuildNormalVS_High(float2 uv)
{
    float3 posVS_C = ReBuildPosVS(uv);
    float3 posVS_T = ReBuildPosVS(uv + float2(0, 1 ));
    float3 posVS_B = ReBuildPosVS(uv + float2(0, -1));
    float3 posVS_R = ReBuildPosVS(uv + float2(1, 0 ));
    float3 posVS_L = ReBuildPosVS(uv + float2(-1, 0));

    float3 depthDiff_L = posVS_C - posVS_L;
    float3 depthDiff_R = posVS_R - posVS_C;
    float3 depthDiff_T = posVS_C - posVS_T;
    float3 depthDiff_B = posVS_B - posVS_C;

    float centerDepth = GetDeviceDepth(uv * _ViewSize.zw);
    float4 horizionDepth = float4(
        GetDeviceDepth(uv + float2(-1.f, 0.f) * _ViewSize.zw),
        GetDeviceDepth(uv + float2(1.f, 0.f) * _ViewSize.zw),
        GetDeviceDepth(uv + float2(-2.f, 0.f) * _ViewSize.zw),
        GetDeviceDepth(uv + float2(2.f, 0.f) * _ViewSize.zw)
    );
    float4 verticalDepth = float4(
        GetDeviceDepth(uv + float2(0.f, -1.f) * _ViewSize.zw),
        GetDeviceDepth(uv + float2(0.f, 1.f) * _ViewSize.zw),
        GetDeviceDepth(uv + float2(0.f, -2.f) * _ViewSize.zw),
        GetDeviceDepth(uv + float2(0.f, 2.f) * _ViewSize.zw)
    );

    float2 horizionDepthDiff = abs(horizionDepth.xy * 2 - horizionDepth.zw - centerDepth);
    float2 verticalDepthDiff = abs(verticalDepth.xy * 2 - verticalDepth.zw - centerDepth);

    float3 horizionVec = horizionDepthDiff.x < horizionDepthDiff.y ? depthDiff_L : depthDiff_R;
    float3 verticalVec = verticalDepthDiff.x < verticalDepthDiff.y ? depthDiff_B : depthDiff_T;

    float3 normalVS = SafeNormalize(cross(horizionVec, verticalVec));

    return normalVS;
}

float4  ReBuildNormalPS(PSInput i) : SV_TARGET
{
    float2 uv = (i.positionCS.xy - 0.5f);

    float3 normalVS = 0.f;
    #ifdef _RebuildNormal_Quality_Low
    normalVS = ReBuildNormalVS_Low(uv);
    #elif defined(_RebuildNormal_Quality_Medium)
    normalVS = ReBuildNormalVS_Medium(uv);
    #elif defined(_RebuildNormal_Quality_High)
    normalVS = ReBuildNormalVS_High(uv);
    #endif
    
    return float4(normalVS, 0.f);
}
