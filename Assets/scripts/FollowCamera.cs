using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class FollowCamera : MonoBehaviour {
    // public bool keepDistance = false;

    public Camera ca;

    public float distance = 0.0f;
    public Vector2 archorPoint = new Vector2(0.5f, 0.5f);
    public Vector3 offset = new Vector3(0, 0, 0);

    private Transform caTransform;
    void Start() {
        if (ca == null) {
            ca = Camera.main;
        }
        caTransform = ca.GetComponent<Transform>();
        updateTransform();
    }

    [ContextMenu("Execute")]
    void updateTransform() {
#if UNITY_EDITOR
        if (ca == null) {
            ca = Camera.main;
        }
        caTransform = ca.GetComponent<Transform>();
#endif
        transform.rotation = caTransform.rotation;
        if (distance > 0.0f) {
            Vector3 _offset = offset * transform.localScale.x;
            float _distance = distance + _offset.z;
            float up = _distance * Mathf.Tan(ca.fieldOfView / 2 * Mathf.Deg2Rad) * 2 * (archorPoint.y - 0.5f) + _offset.y;
            float right = _distance * Mathf.Tan(calcHorizontalFOV(Screen.width, Screen.height, ca.fieldOfView) / 2 * Mathf.Deg2Rad) * 2 * (archorPoint.x - 0.5f) + _offset.x;

            transform.position = caTransform.position + caTransform.forward * _distance + caTransform.up * up + caTransform.right * right;
        }
    }

    float calcHorizontalFOV(float width, float height, float verticalFOV) {
        float distance = height / 2 / Mathf.Tan(Mathf.Deg2Rad * verticalFOV / 2);
        return Mathf.Atan2(width / 2, distance) * Mathf.Rad2Deg * 2;
    }

    void LateUpdate() {
        updateTransform();
    }
}
