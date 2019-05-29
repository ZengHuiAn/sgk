using UnityEngine;
using System.Collections;
using UnityEngine.UI;

// [RequireComponent(typeof(Animator))]
public class BattlefieldCameraReset : MonoBehaviour
{
    Animator animator;
	
	public Transform targetCamera;
	
    Transform mainCamera;
	
    public float delay    = 1.0f;
    public float duration = 1.0f;

    float pass = 0;

    Vector3 orgPosition;
    Quaternion orgRotation;

    private void Start() {
		animator = GetComponent<Animator>();
        mainCamera = Camera.main.GetComponent<Transform>();
    }

    private void OnEnable() {
        pass = 0;
        if (animator != null) {
            animator.enabled = true;
        }
    }

    void Update() {
        if (mainCamera == null || pass >= duration + delay || targetCamera == null) {
            return;
        }

        pass += Time.deltaTime;
        if (pass < delay) {
            orgPosition = targetCamera.position;
            orgRotation = targetCamera.rotation;
        } else {
            if (animator != null) {
                animator.enabled = false;
            }
            targetCamera.position = Vector3.Lerp(orgPosition, mainCamera.position, (pass - delay) / duration);
            targetCamera.rotation = Quaternion.Lerp(orgRotation, mainCamera.rotation, (pass - delay) / duration);
        }
    }

    [ContextMenu("Reset")]
    public void ResetOrg() {
        targetCamera.position = orgPosition;
        targetCamera.rotation = orgRotation;
    }
}
