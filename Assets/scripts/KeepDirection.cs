using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class KeepDirection : MonoBehaviour {
    // public bool keepDistance = false;

    public Vector3 direction = Vector3.up;
    GameObject MainCamera;
    void Start()
    {
        MainCamera = GameObject.FindWithTag("MainCamera");
    }
    [ContextMenu("Execute")]
    void LateUpdate() {
        if (MainCamera == null) {
            MainCamera = GameObject.FindWithTag("MainCamera");
        }
        if (MainCamera) {
            direction.y = MainCamera.transform.localEulerAngles.y;
        }
        transform.eulerAngles = direction;
    }
}
