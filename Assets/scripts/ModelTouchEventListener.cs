using System.Collections;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using UnityEngine;

public class ModelTouchEventListener : MonoBehaviour {
    public System.Action<Vector3> onTouchBegan;
    public System.Action<Vector3> onTouchMove;
    public System.Action<Vector3> onTouchEnd;
    public System.Action onTouchCancel;

    public bool checkMoveDistance = false;
    int touchStatus = 0;
    Vector3 touchPosition;
    // Vector3 screenPosition;
    Vector3 beganTouch;
    int lastTouchStaus = 0;

    public void SetTouchInfo(int status , Vector3 pos, Vector3 screenPos) {
        touchStatus = status;
        touchPosition = pos;
        // screenPosition = screenPos;
    }

    bool inTouch = false;

    private void Update() {
        if (!inTouch && touchStatus != 1) {
            return;
        }

        if (touchStatus == 0) {
            if (lastTouchStaus != 0) {
                if (onTouchCancel != null) {
                    onTouchCancel();
                }
            }
            inTouch = false;
        } else if (touchStatus == 1) {
            if (lastTouchStaus != 1) {
                beganTouch = touchPosition;
                if (onTouchBegan != null) {
                    onTouchBegan(touchPosition);
                }
            }
            inTouch = true;
        } else if (touchStatus == 2) {
            if (onTouchMove != null) {
                onTouchMove(touchPosition);
            }
        } else if (touchStatus == 3) {
            if (checkMoveDistance && (beganTouch != null) && (Vector3.Distance(beganTouch, touchPosition) > 0.01f))
            {
                if (onTouchCancel != null)
                {
                    onTouchCancel();
                }
            }
            else
            {
                if (onTouchEnd != null) {
                    onTouchEnd(touchPosition);
                }
            }
            touchStatus = 0;
            inTouch = false;
        }

        lastTouchStaus = touchStatus;
        touchStatus = 0;
    }

    public static ModelTouchEventListener Get(GameObject obj) {
        ModelTouchEventListener del = obj.GetComponent<ModelTouchEventListener>();
        if (del == null) {
            del = obj.AddComponent<ModelTouchEventListener>();
        }
        return del;
    }

    private void OnDestroy() {
        onTouchBegan = null;
        onTouchMove = null;
        onTouchEnd = null;
        onTouchCancel = null;
    }
}
