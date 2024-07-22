using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenuForRenderPipeline("Elysia/Rebuild Normal", typeof(UniversalRenderPipeline))]
    public class ReBuildNormalVolume : VolumeComponent, IPostProcessComponent
    {
        public BoolParameter enable = new BoolParameter(true);
        public NormalParameter m_quality = new NormalParameter(NormalQuality.High);
        
        public bool IsTileCompatible() => false;
        public bool IsActive() => enable == true; 
    }

    #region Variable
    public enum NormalQuality
    {
        Low,
        Medium,
        High
    }

    [System.Serializable]
    public sealed class NormalParameter : VolumeParameter<NormalQuality>
    {
        public NormalParameter(NormalQuality quality, bool overrideState = false) : base(quality, overrideState) {}
    }
    #endregion
}
