using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public partial class PostFXStack 
{
    const string bufferName = "Post FX";
    
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };

    ScriptableRenderContext context;
    Camera camera;
    PostFXSettings settings;

    // 判断是否需要应用后处理效果
     public bool IsActive => settings != null;

    enum Pass
    {
        Copy
    }

    int fxSourceId = Shader.PropertyToID("_PostFXSource");

    const int maxBloomPyramidLevels = 16;

    // 纹理标志符
    int bloomPyramidId;
    public PostFXStack()
    {
        bloomPyramidId = Shader.PropertyToID("_BloomPyramid0");
        for (int i = 1; i < maxBloomPyramidLevels; i++)
        {
            Shader.PropertyToID("_BloomPyramid" + i);
        }
    }

    public void Setup(ScriptableRenderContext context, Camera camera, PostFXSettings settings)
    {
        this.context = context;
        this.camera = camera;
        this.settings = camera.cameraType <= CameraType.SceneView ? settings : null;
        ApplySceneViewState();

    }
    void Draw(RenderTargetIdentifier from, RenderTargetIdentifier to, Pass pass)
    {
        buffer.SetGlobalTexture(fxSourceId, from);
        buffer.SetRenderTarget(to, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.DrawProcedural(Matrix4x4.identity, settings.Material, (int) pass, MeshTopology.Triangles, 3);
    }
    /// <summary>
    /// 渲染后处理特效
    /// </summary>
    /// <param name="sourceId"></param>
    public void Render(int sourceId)
    {
        //Draw(sourceId, BuiltinRenderTextureType.CameraTarget, Pass.Copy);
        DoBloom(sourceId);
        //buffer.Blit(sourceId, BuiltinRenderTextureType.CameraTarget);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    /// <summary>
    /// 渲染bloom
    /// </summary>
    void DoBloom(int sourceId)
    {
        buffer.BeginSample("Bloom");
        PostFXSettings.BloomSettings bloom = settings.Bloom;
        int width = camera.pixelWidth / 2, height = camera.pixelHeight / 2;
        RenderTextureFormat format = RenderTextureFormat.Default;
        int fromId = sourceId;
        int toId = bloomPyramidId;
        int i;
        for (i = 0; i < bloom.maxIterations; i++)
        {
            if (height < bloom.downscaleLimit || width < bloom.downscaleLimit)
            {
                break;
            }
            buffer.GetTemporaryRT(toId, width, height, 0, FilterMode.Bilinear, format);
            Draw(fromId, toId, Pass.Copy);
            fromId = toId;
            toId += 1;
            width /= 2;
            height /= 2;
        }
        Draw(fromId, BuiltinRenderTextureType.CameraTarget, Pass.Copy);
        for(i -= 1; i >= 0; i--)
        {
            buffer.ReleaseTemporaryRT(bloomPyramidId + i);
        }
        buffer.EndSample("Bloom");

    }
}
