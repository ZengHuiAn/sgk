using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIFixScaleIn3DSpace : MonoBehaviour {
    public Camera uiCamera;

    public float scale = -0.0f;
    public float bestDistance = 0;

	void Start () {
        if (uiCamera == null) {
            uiCamera = Camera.main;
        }
        if (scale <= 0) {
            scale = transform.localScale.x;
        }

        if (bestDistance == 0) {
            bestDistance = (uiCamera.transform.position - transform.position).magnitude;
        }
    }
	
	// Update is called once per frame
	void UpdateScale () {
        // ((uiCamera.transform.position - transform.position).magnitude - bestDistance) * Mathf.Tan(uiCamera.fieldOfView * Mathf.Deg2Rad);

        float fact = (uiCamera.transform.position - transform.position).magnitude  / bestDistance;
        transform.localScale =  Vector3.one * scale * fact;
    }

    void Update() {
        UpdateScale();
    }
}
