using UnityEngine.Rendering.Universal;

namespace UnityEngine.Rendering.Universal
{
    public class ReBuildNormalVSRenderFeature : ScriptableRendererFeature
    {
        #region Variable
        [System.Serializable]
        public class PassSetting
        { 
            public string m_profilerTag = "ReBuildNormalWS";
            public RenderPassEvent m_passEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            public Shader m_shader;
        }

        public PassSetting m_passSetting = new PassSetting();
        ReBuildNormalVSRenderPass m_renderPass;
        #endregion
        
        public override void Create()
        {
            if (m_renderPass == null)
            {
                m_renderPass = new ReBuildNormalVSRenderPass(m_passSetting);
            }
        }
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var volume = VolumeManager.instance.stack.GetComponent<ReBuildNormalVolume>();

            if (volume != null && volume.enable == true)
            {
                m_renderPass.Setup(volume);
                renderer.EnqueuePass(m_renderPass);
            }
        }
    }   
}


