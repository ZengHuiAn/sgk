using UnityEngine;
using System.Collections;

public class SmoothMoveTo : MonoBehaviour {
    public Vector3 target = Vector3.zero;
    public float smoothTime = 1.0f;

    private Vector3 velocity = Vector3.zero;

    public delegate void OnReadyDelegate();

    public OnReadyDelegate onReady;

    private bool stoped = true;
    void Update () {
        if (!stoped) {
            transform.position = Vector3.SmoothDamp(transform.position, target, ref velocity, smoothTime);
            if (Mathf.Approximately((target - transform.position).sqrMagnitude, 0)) {
                transform.position = target;
                velocity = Vector3.zero;
                stoped = true;
                // Debug.LogFormat("SmoothMoveTo ready {0} -> {1}, {2}", transform.position, target, smoothTime);
                if (onReady != null) {
                    onReady();
                }
            }
        }
    }

    public void Follow(Vector3 target, float smoothTime) {
        // Debug.LogFormat("SmoothMoveTo start {0} -> {1}, {2}", transform.position, target, smoothTime);
        this.smoothTime = smoothTime;
        this.target = target;
        stoped = false;
    }
}
