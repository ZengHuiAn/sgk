using UnityEngine;

namespace SGK {
    namespace Battle {
        public class BattleCameraController : MonoBehaviour {
            [System.Serializable]
            public class RuntimeInfo {
                public Transform transform;
                // public Vector3 defaultOffset = Vector3.zero;

                private Vector3 origin = Vector3.zero;

                public SmoothMoveTo script {
                    get {
                        return transform.gameObject.GetComponent<SmoothMoveTo>();
                    }
                }

                public void Reset(Vector3 origin, float smoothTime) {
                    this.origin = origin;
                    Reset(smoothTime);
                }

                public void Reset(float smoothTime) {
                    MoveTo(null, Vector3.zero, smoothTime);
                }

                public void MoveTo(Transform targetTransform, float time = 0.1f) {
					MoveTo(targetTransform, Vector3.zero, time);
                }

				public void MoveTo(Transform targetTransform, Vector3 offset, float time = 0.1f) {
                    try {
                        SmoothMoveTo smt = transform.gameObject.GetComponent<SmoothMoveTo>();
                        if (smt == null) {
                            smt = transform.gameObject.AddComponent<SmoothMoveTo>();
                        }

                        Vector3 target;
                        if (targetTransform == null) {
                            target = origin + offset;
                        } else {
                            target = targetTransform.position + offset;
                        }
                        smt.Follow(target, time);
                    } catch (System.Exception e) {
                        Debug.LogError(e);
                    }
                }
            }

            public RuntimeInfo cameraMove;
            public RuntimeInfo cameraLook;

            public Camera playerCamera;

            SmoothMoveTo moveToScript {
                get {
                    return cameraMove.script;
                }
            }

            SmoothMoveTo lookAtScript {
                get {
                    return cameraLook.script;
                }
            }

            // Use this for initialization
            void Start() {
            }

            private void OnEnable() {
                SGK.BattleCameraScriptAction.controller = this;
            }

            private void OnDisable() {
                if (SGK.BattleCameraScriptAction.controller == this) {
                    BattleCameraScriptAction.controller = null;
                }
            }

            public void CameraMoveTo(Transform targetTransform, Vector3 offset, float smoothTime) {
                cameraMove.MoveTo(targetTransform, offset, smoothTime);
            }
				
			public void CameraLookAt(Transform targetTransform, Vector3 offset, float smoothTime) {
                cameraLook.MoveTo(targetTransform, offset, smoothTime);
            }

            public void CameraMoveReset(Transform targetTransform, float smoothTime = 0.3f) {
                cameraMove.Reset(targetTransform.position, smoothTime);
            }

            public void CameraLookReset(Transform targetTransform, float smoothTime = 0.3f) {
                cameraLook.Reset(targetTransform.position, smoothTime);
            }

            public void CameraMoveReset(float smoothTime = 0.3f) {
                cameraMove.Reset(smoothTime);
            }

            public void CameraLookReset(float smoothTime = 0.3f) {
                cameraLook.Reset(smoothTime);
            }
        }
    }
}
