using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(UGUISelector))]
public class UGUIRandomSelector : MonoBehaviour {
    public float duration = 0;

    void OnEnable() {
        ChangeImage();
    }

    void ChangeImage() {
        UGUISelector selector = GetComponent<UGUISelector>();
        if (selector != null && selector.Count > 0) {
            selector.index = Random.Range(0, selector.Count);
        }
    }

    float pass;
    private void Update() {
        if (duration <= 0) return;

        pass += Time.deltaTime;
        if (pass >= duration) {
            ChangeImage();
            pass = 0;
        }
    }
}
