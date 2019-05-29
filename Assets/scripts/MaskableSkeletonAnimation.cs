using UnityEngine;
using Spine.Unity;
using System;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine.Rendering;

namespace SGK {
    public class MaskableSkeletonAnimation : MaskableGameObject {
        [SerializeField]
        SkeletonAnimation _skeletonAnimation = null;
        public SkeletonAnimation skeletonAnimation {
            get {
                if (_skeletonAnimation == null) _skeletonAnimation = GetComponent<SkeletonAnimation>();
                return _skeletonAnimation;
            }
        }

        protected override void UpdateStencil(int stencil) {
            if (skeletonAnimation != null) {
                foreach (KeyValuePair<Material, Material> ite in skeletonAnimation.CustomMaterialOverride) {
                    ReleaseMaterial(ite.Value);
                }

                if (stencil == 0 && _color == Color.white && _Exposure == 0) {
                    skeletonAnimation.ResetCustomMaterial();
                } else if (skeletonAnimation.skeletonDataAsset != null) { 
                    AtlasAsset[] atlasAssets = skeletonAnimation.skeletonDataAsset.atlasAssets;
                    foreach (AtlasAsset atlasAsset in atlasAssets) {
                        foreach (Material atlasMaterial in atlasAsset.materials) {
                            Material mat = GetReplacementMaterial(atlasMaterial);
                            mat.SetFloat("_Exposure", _Exposure);
                            mat.SetColor("_Color", _color);
                            skeletonAnimation.AddCustomMaterial(atlasMaterial, mat);
                        }
                    }
                }
            }
        }

        public void UpdateStencil() {
            if (this.enabled) {
                UpdateStencil(stencil);
            }
        }

        [SerializeField]
        [Range(-1,1)]
        float _Exposure = 0;
        public float Exposure {
            get { return _Exposure; }
            set {
                if(_Exposure == value) {
                    return;
                }

                _Exposure = value;

                if (skeletonAnimation == null) {
                    return;
                }

                if (skeletonAnimation.CustomMaterialOverride.Count == 0) {
                    UpdateStencil();
                } else {
                    foreach(KeyValuePair<Material, Material> kv in skeletonAnimation.CustomMaterialOverride) {
                        kv.Value.SetFloat("_Exposure", _Exposure);
                    }
                }
            }
        }

        [SerializeField]
        Color _color = Color.white;
        public Color color {
            get { return _color; }
            set {
                if(_color == value) {
                    return;
                }

                _color = value;

                if (skeletonAnimation == null) {
                    return;
                }

                if (skeletonAnimation.CustomMaterialOverride.Count == 0) {
                    UpdateStencil();
                } else {
                    foreach(KeyValuePair<Material, Material> kv in skeletonAnimation.CustomMaterialOverride) {
                        kv.Value.SetColor("_Color", _color);
                    }
                }
            }
        }

#if UNITY_EDITOR
        void Update() {
            if (Application.isPlaying) {
                return;
            }

            if (skeletonAnimation == null) {
                return;
            }

            if (skeletonAnimation.CustomMaterialOverride.Count == 0) {
                UpdateStencil();
            } else {
                foreach(KeyValuePair<Material, Material> kv in skeletonAnimation.CustomMaterialOverride) {
                    kv.Value.SetColor("_Color", _color);
                    kv.Value.SetFloat("_Exposure", _Exposure);
                }
            }
        }
#endif
    }
}