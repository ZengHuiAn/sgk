using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteInEditMode]
[RequireComponent(typeof(Image))]
 public class ImageMaterial : MonoBehaviour {
    public Material material;
    public bool active {
        get {
            return GetComponent<Image>().material == material;
        }

        set {
            GetComponent<Image>().material = value ? material : null;
            _active = value;
        }
    }

    private void OnEnable() {
        GetComponent<Image>().material = _active ? material : null;
    }

    void OnDisable() {
        GetComponent<Image>().material = null;
    }

    public bool _active = false;

#if UNITY_EDITOR
    void Update() {
        if (!Application.isPlaying) {
            if (active != _active) {
                active = _active;
            }
        }
    }
#endif
}
