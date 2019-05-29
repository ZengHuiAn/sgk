using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(CanvasRenderer))]
public class ImageAnimation : MonoBehaviour {
    public bool loop = true;

    public AnimationCurve scale;
    public AnimationCurve rotation;
    public Gradient color;

    float durationScale = 0.0f;
    float durationRotation = 0.0f;

    CanvasRenderer canvasRenderer;
    private void Start() {
        canvasRenderer = GetComponent<CanvasRenderer>();
        if (scale != null && scale.length > 0) {
            Keyframe frame = scale[scale.length - 1];
            durationScale = frame.time;
        }

        if (rotation != null && rotation.length > 0) {
            Keyframe frame = rotation[rotation.length - 1];
            durationRotation = frame.time;
        }
    }

	void Update () {
        if (durationScale <= 0) {
            return;
        }

        if (!loop) {
            transform.localScale = Vector3.one * scale.Evaluate(Time.time);
            transform.localRotation = Quaternion.Euler(0, 0, rotation.Evaluate(Time.time)*360);
            canvasRenderer.SetColor(color.Evaluate(Time.time / durationScale));
        } else {
            transform.localScale = Vector3.one * scale.Evaluate(Time.time % durationScale);
			transform.localRotation = Quaternion.Euler(0, 0, rotation.Evaluate(Time.time % durationRotation)*360);
            canvasRenderer.SetColor(color.Evaluate((Time.time % durationScale) / durationScale));
        }
    }
}
