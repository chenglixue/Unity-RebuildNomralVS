using System.Collections.Generic;
using Unity.Mathematics;

namespace UnityEngine.Rendering.Universal
{
    class ReBuildNormalVSRenderPass : ScriptableRenderPass
    {
        #region  Variable
        private ReBuildNormalVSRenderFeature.PassSetting m_passSetting;
        private ProfilingSampler m_profilingSampler;
        private ReBuildNormalVolume m_volume;
        private Shader m_shader;
        private Material m_material;
        
        private RenderTargetIdentifier m_cameraRT;
        private RenderTextureDescriptor m_descriptor;
        private int m_tempRT = Shader.PropertyToID("_TempRT1");
        private Vector4 m_texSize;
        #endregion

        #region Setup
        public ReBuildNormalVSRenderPass(ReBuildNormalVSRenderFeature.PassSetting passSetting)
        {
            m_passSetting = passSetting;
            renderPassEvent = m_passSetting.m_passEvent;
            m_profilingSampler = new ProfilingSampler(m_passSetting.m_profilerTag);
            if (m_passSetting.m_shader == null)
            {
                Debug.LogError("Compute Shader is missing");
            }
            else
            {
                m_shader = m_passSetting.m_shader;
                m_material = new Material(m_shader);
            }
        }

        public void Setup(ReBuildNormalVolume volume)
        {
            m_volume = volume;
        }
        
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            m_descriptor = renderingData.cameraData.cameraTargetDescriptor;
            m_descriptor.msaaSamples = 1;
            m_descriptor.depthBufferBits = 0;

            m_texSize = new Vector4(m_descriptor.width, m_descriptor.height, 1f / m_descriptor.width, 1f / m_descriptor.height);
            
            m_cameraRT = renderingData.cameraData.renderer.cameraColorTarget;
            cmd.GetTemporaryRT(m_tempRT, m_descriptor);
            cmd.Blit(m_cameraRT, m_tempRT);
        }
        
        #endregion

        #region Execute
        void DoRebuildNormal(CommandBuffer cmd, RenderTargetIdentifier sourceRT, RenderTargetIdentifier targetRT, Material material)
        {
            if (material == null) return;
            
            material.SetVector("_ViewSize", m_texSize);
            
            CoreUtils.SetKeyword(cmd, "_RebuildNormal_Quality_Low", m_volume.m_quality.value == NormalQuality.Low);
            CoreUtils.SetKeyword(cmd, "_RebuildNormal_Quality_Medium", m_volume.m_quality.value == NormalQuality.Medium);
            CoreUtils.SetKeyword(cmd, "_RebuildNormal_Quality_High", m_volume.m_quality.value == NormalQuality.High);
            
            cmd.Blit(sourceRT, targetRT, material, 0);
        }
        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();

            using (new ProfilingScope(cmd, new ProfilingSampler(m_passSetting.m_profilerTag)))
            {
                
                DoRebuildNormal(cmd, m_tempRT, m_cameraRT, m_material);
            }
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
        
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_tempRT);
        }
        #endregion
    }
}

