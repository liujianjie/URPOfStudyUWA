using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class CustomShaderGUI : ShaderGUI
{
    MaterialEditor editor;
    Object[] materials;
    MaterialProperty[] properties;

    bool showPresets;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        editor = materialEditor;
        materials = materialEditor.targets;
        this.properties = properties;

        EditorGUILayout.Space();
        showPresets = EditorGUILayout.Foldout(showPresets, "Presets", true);
        if (showPresets)
        {
            OpaquePreset();
            ClipPreset();
            FadePreset();
            TransparentPreset();
        }
    }
    // 设置材质属性
    void SetProperty(string name, float value)
    {
        FindProperty(name, properties).floatValue = value;
    }
    // 同时设置关键字和属性
    void SetProperty(string name, string keyword, bool value)
    {
        SetProperty(name, value ? 1f :0f);
        SetKeyword(keyword, value);
    }
    // 设置关键字状态
    void SetKeyword(string keyword, bool enabled)
    {
        if (enabled)
        {
            foreach(Material m in materials)
            {
                m.EnableKeyword(keyword);
            }
        }
        else
        {
            foreach(Material m in materials)
            {
                m.DisableKeyword(keyword);
            }
        }
    }
    // 定义一些属性来设置材质上对应的属性值
    bool Clipping
    {
        set => SetProperty("_Clipping", "_CLIPPING", value);
    }
    bool PremultiplyAlpha
    {
        set => SetProperty("_PremulAlpha", "_PREMULTIPLY_ALPHA", value);
    }
    BlendMode SrcBlend
    {
        set => SetProperty("_SrcBlend", (float)value);
    }
    BlendMode DstBlend
    {
        set => SetProperty("_DstBlend", (float)value);
    }
    bool ZWrite
    {
        set => SetProperty("_ZWrite", value ? 1f : 0f);
    }
    RenderQueue RenderQueue
    {
        set
        {
            foreach(Material m in materials)
            {
                m.renderQueue = (int)value;
            }
        }
    }
    // 渲染模式预置
    // 每种渲染模式都有对应一个按钮
    bool PresetButton(string name)
    {
        if (GUILayout.Button(name))
        {
            // 属性重置
            editor.RegisterPropertyChangeUndo(name);
            return true;
        }
        return false;
    }
    // 创建OpaquePreset方法进行不透明渲染模式的材质属性一系列设置
    void OpaquePreset()
    {
        if (PresetButton("Opaque"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.Zero;
            ZWrite = true;
            RenderQueue = RenderQueue.Geometry;
        }
    }
    // 裁剪模式
    void ClipPreset()
    {
        if (PresetButton("Clip"))
        {
            Clipping = true;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.Zero;
            ZWrite = true;
            RenderQueue = RenderQueue.AlphaTest;
        }
    }
    // 标准的透明渲染模式
    void FadePreset()
    {
        if (PresetButton("Fade"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.SrcAlpha;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = true;
            RenderQueue = RenderQueue.Transparent;
        }
    }
    // 预设了透明度标准的透明渲染模式
    void TransparentPreset()
    {
        if (PresetButton("Transparent"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = false;
            RenderQueue = RenderQueue.Transparent;
        }
    }
}
