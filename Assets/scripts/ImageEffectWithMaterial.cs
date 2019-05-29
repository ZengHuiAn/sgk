using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]

 public class ImageEffectWithMaterial : MonoBehaviour {
    public Material material;
    void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (material != null) {
            Graphics.Blit(source, destination, material, 0);
        }
    }
}
