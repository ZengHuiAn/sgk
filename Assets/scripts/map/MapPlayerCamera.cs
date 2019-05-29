using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class MapPlayerCamera : MonoBehaviour
    {
        [SerializeField]
        Transform _target;
        public Transform target {
            get {
                return _target;
            }

            set {
                if (_target == null) {
                    _target = value;
                    UpdatePositionWithSpeed(0);
                } else {
                    _target = value;
                }
            }
        }

        [Range(0, 20)]
        public float distance = 10;

        [Range(0, 10)]
        public float speed = 0;

        public bool worldSpace = true;

        public Transform viewArea;

        public Transform cameraLookAt = null;

        Vector3 min;
        Vector3 max;
		float CameraSize = 0;
		Camera playerCamera;
        void Start() {
            if (viewArea != null) {
                playerCamera = GetComponent<Camera>();
				UpdateCameraSize ();
				CameraSize = playerCamera.orthographicSize;
            }
            UpdatePositionWithSpeed(0);
        }
		void UpdateCameraSize(){
			if (playerCamera && CameraSize != playerCamera.orthographicSize && playerCamera.orthographicSize > 3f) {
				min = (viewArea.position - viewArea.lossyScale / 2) - transform.forward * distance;
				max = (viewArea.position + viewArea.lossyScale / 2) - transform.forward * distance;
				if (playerCamera != null) {
					if (playerCamera.orthographic) {
						min.x += playerCamera.orthographicSize * playerCamera.aspect;
						max.x -= playerCamera.orthographicSize * playerCamera.aspect;

						min.z += playerCamera.orthographicSize / Mathf.Sin (Vector3.Angle (transform.forward, viewArea.forward) * Mathf.Deg2Rad) - 1.8f;
						max.z -= playerCamera.orthographicSize / Mathf.Sin (Vector3.Angle (transform.forward, viewArea.forward) * Mathf.Deg2Rad) + 1.5f;

						if (max.x < min.x) {
							min.x = max.x = (min.x + max.x) / 2;
						}

						if (max.z < min.z) {
							min.z = max.z = (min.z + max.z) / 2;
						}
					} else {
						min = viewArea.position - viewArea.lossyScale / 2;
						max = viewArea.position + viewArea.lossyScale / 2;
					}
				}
			}
		}
        void LateUpdate() {
			UpdateCameraSize ();
			UpdatePositionWithSpeed(speed);
        }

        public void UpdatePositionWithSpeed(float _speed = 0) {
            if (target == null) {
                return;
            }

#if UNITY_EDITOR
            if (viewArea != null && !GetComponent<Camera>().orthographic) {
                min = (viewArea.position - viewArea.lossyScale / 2);
                max = (viewArea.position + viewArea.lossyScale / 2);
            }
#endif

            if (cameraLookAt != null) {
                transform.LookAt(cameraLookAt);
                Vector3 old = transform.localEulerAngles;
                transform.localEulerAngles = new Vector3(45, old.y, 0);
            }

            Vector3 targetPosition = target.position - transform.forward * distance;

            if (_speed > 0) {
                targetPosition = Vector3.Lerp(transform.position, targetPosition, _speed * Time.deltaTime);
            }

            if (viewArea != null) {
                targetPosition.x = Mathf.Clamp(targetPosition.x, min.x, max.x);
                targetPosition.z = Mathf.Clamp(targetPosition.z, min.z, max.z);
            }

            transform.position = targetPosition;
        }

        [ContextMenu("Save Current Value")]
        void SaveCurrentValue() {
            if (target) {
                distance = (transform.position - target.position).magnitude;
            }
        }
    }
}
