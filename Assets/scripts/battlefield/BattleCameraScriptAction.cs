using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class BattleCameraScriptAction : MonoBehaviour {
        public static SGK.Battle.BattleCameraController controller;

        public enum ActionType {
            MoveTo,
            LookAt,
        };

        public AnimationCurve curveX = AnimationCurve.Linear(0, 0, 10, 10);

        public ActionType action = ActionType.MoveTo;
        public bool autoTarget = true;
        public Transform target;
        public Vector3 offset = Vector3.zero;
        public float delay = 0;
        public float duration = 1;
        public bool autoRevert = true;
        public float keepDuration = 1;
        public float revertDuration = 1;

        public float magnification = 3;

        void OnEnable() {
            if (controller != null) {
                StartCoroutine(RunAction());
            }
        }

        void OnDisable() {
            if (controller == null) {
                return;
            }

            if (autoRevert) {
                if (action == ActionType.MoveTo) {
                    controller.CameraMoveReset(revertDuration);
                } else if (action == ActionType.LookAt) {
                    controller.CameraLookReset(revertDuration);
                }
            }
        }

        IEnumerator RunAction() {
            if (delay > 0) {
                yield return new WaitForSeconds(delay);
            }

            if (action == ActionType.MoveTo) {
                controller.CameraMoveTo(target, offset * magnification, duration);
            } else if (action == ActionType.LookAt) {
                controller.CameraLookAt(target, offset * magnification, duration);
            }

            yield return new WaitForSeconds(duration);

            if (autoRevert) {
                yield return new WaitForSeconds(keepDuration);

                if (action == ActionType.MoveTo) {
					controller.CameraMoveReset(revertDuration);
                } else if (action == ActionType.LookAt) {
					controller.CameraLookReset(revertDuration);
                }
                yield return new WaitForSeconds(revertDuration);
            }
        }
    }
}
