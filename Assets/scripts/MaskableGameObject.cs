using UnityEngine;
using Spine.Unity;
using System;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine.Rendering;

namespace SGK {
    public class MaskableGameObject : MonoBehaviour {
        public static Material CreateMaterial(Material baseMat, int stencilID, StencilOp operation, CompareFunction compareFunction, ColorWriteMask colorWriteMask, int readMask = 255, int writeMask = 255) {
            if (baseMat == null)
                return baseMat;

            if (!baseMat.HasProperty("_Stencil")) {
                Debug.LogWarning("Material " + baseMat.name + " doesn't have _Stencil property", baseMat);
                return baseMat;
            }
            if (!baseMat.HasProperty("_StencilOp")) {
                Debug.LogWarning("Material " + baseMat.name + " doesn't have _StencilOp property", baseMat);
                return baseMat;
            }
            if (!baseMat.HasProperty("_StencilComp")) {
                Debug.LogWarning("Material " + baseMat.name + " doesn't have _StencilComp property", baseMat);
                return baseMat;
            }
            if (!baseMat.HasProperty("_StencilReadMask")) {
                Debug.LogWarning("Material " + baseMat.name + " doesn't have _StencilReadMask property", baseMat);
                // return baseMat;
            }

            if (!baseMat.HasProperty("_StencilReadMask")) {
                Debug.LogWarning("Material " + baseMat.name + " doesn't have _StencilWriteMask property", baseMat);
                // return baseMat;
            }
            if (!baseMat.HasProperty("_ColorMask")) {
                Debug.LogWarning("Material " + baseMat.name + " doesn't have _ColorMask property", baseMat);
                return baseMat;
            }

            Material customMat = new Material(baseMat);
            customMat.hideFlags = HideFlags.DontSaveInBuild | HideFlags.DontSaveInEditor; // HideFlags.HideAndDontSave;
            customMat.name = string.Format("{6} (ID: {0}, Op:{1}, Comp:{2}, WriteMask:{3}, ReadMask:{4}, ColorMask:{5} ", stencilID, operation, compareFunction, writeMask, readMask, colorWriteMask, baseMat.name);
            customMat.SetInt("_Stencil", stencilID);
            customMat.SetInt("_StencilOp", (int)operation);
            customMat.SetInt("_StencilComp", (int)compareFunction);
            customMat.SetInt("_StencilReadMask", readMask);
            customMat.SetInt("_StencilWriteMask", writeMask);
            customMat.SetInt("_ColorMask", (int)colorWriteMask);

            return customMat;
        }

        [SerializeField]
        [Range(0, 10)]
        int _stencil = 0;

        [SerializeField]
        bool _isMask = false;

        public bool showGraphic = false;

        public bool isMask {
            get { return _isMask; }
            set {
                _isMask = value;
                UpdateStencil(_stencil);
            }
        }

        public int stencil {
            get { return _stencil; }
            set {
                _stencil = value;
                dirty = true;
                UpdateStencil(_stencil);
            }
        }

        private void OnEnable() {
            UpdateStencil(_stencil);
        }

        private void OnDisable() {
            UpdateStencil(0);
        }

        void OnDestroy() {
            CleanMaterial();
        }

        bool dirty = false;
        protected void SetDirty() {
            dirty = true;
        }

#if UNITY_EDITOR
        int current_stencil = 0;
        void Update() {
            if (dirty || current_stencil != _stencil) {
                current_stencil = _stencil;
                dirty = false;
                UpdateStencil(_stencil);
            }
        }
#endif

        Material _GetReplacementMaterial(Material mateiral) {
            if (_stencil == 0) {
                return CreateMaterial(mateiral,
                           _stencil, StencilOp.Keep,
                           CompareFunction.Always,
                           ColorWriteMask.All);
            }

            return isMask ?
                CreateMaterial(mateiral, _stencil,
                                StencilOp.Replace,
                                CompareFunction.Always,
                                showGraphic ? ColorWriteMask.All : 0) :
                CreateMaterial(mateiral,
                                _stencil, StencilOp.Keep,
                                CompareFunction.Equal,
                                ColorWriteMask.All);
        }

        private List<Material> m_List = new List<Material>();
        protected Material GetReplacementMaterial(Material material) {
            Material newMaterial = _GetReplacementMaterial(material);
            if (newMaterial != material) {
                m_List.Add(newMaterial);
            }
            return newMaterial;
        }

        protected void CleanMaterial() {
            for (int i = 0; i < m_List.Count; ++i) {
                Material material = m_List[i];
                DestroyMaterial(material);
            }
            m_List.Clear();
        }

        protected void ReleaseMaterial(Material customMat) {
            if (customMat == null) {
                return;
            }

            for (int i = 0; i < m_List.Count; ++i) {
                Material material = m_List[i];
                if (material == customMat) {
                    DestroyMaterial(material);
                    m_List.RemoveAt(i);
                    return;
                }
            }
        }

        void DestroyMaterial(Material customMat) {
            if (Application.isEditor) {
                DestroyImmediate(customMat);
            } else {
                Destroy(customMat);
            }
        }

        protected virtual void UpdateStencil(int stencil) {
            Renderer renderer = GetComponent<Renderer>();
            if (renderer != null) {
                renderer.material = GetReplacementMaterial(renderer.material);
            }
        }

    }
}