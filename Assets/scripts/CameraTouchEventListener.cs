using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.EventSystems;

[RequireComponent(typeof(Camera))]
public class CameraTouchEventListener : MonoBehaviour {
    public float maxDistance = 100f;

    Camera rayCamera;
	void Start() {
		rayCamera = GetComponent<Camera>();
	}

    bool isMouseDown() {
		return Input.GetMouseButtonDown(0);
	}

	bool isMouseUp() {
		return Input.GetMouseButtonUp(0);
	}

	bool isMouseHold() {
		return Input.GetMouseButton(0);
	}

	bool IsPointerOverGameObject( int fingerId ) {
		EventSystem eventSystem = EventSystem.current;
		return ( eventSystem.IsPointerOverGameObject( fingerId ));
	}

    void TryTouchGameObject(Vector3 position, GameObject obj, int status, Vector3 screenPos) {
        ModelTouchEventListener mc = obj.GetComponent<ModelTouchEventListener>();
        if (mc != null) {
            mc.SetTouchInfo(status, position, screenPos);
        }
    }

	// Update is called once per frame
	void Update () {
        if (!EventSystem.current) {
			return;
		}

#if !UNITY_EDITOR && (UNITY_IOS || UNITY_ANDROID)
		if (Input.touchCount == 0) {
			return;
		}

		Touch touch = Input.GetTouch(0);

        if (IsPointerOverGameObject(touch.fingerId)) {
            return;
        }

        int status = 0;
        switch (touch.phase) {
            case TouchPhase.Began:
                status = 1;
                break;
            case TouchPhase.Ended:
                status = 3;
                break;
            case TouchPhase.Canceled:
                status = 3;
                break;
            case TouchPhase.Moved:
                status = 2;
                break;
            case TouchPhase.Stationary:
                status = 2;
                break;
        }

        if (status != 0) {
            RaycastHit hit;
            Ray ray = rayCamera.ScreenPointToRay(touch.position);
            Transform select = gameObject.transform;

            if (Physics.Raycast(ray, out hit, maxDistance)) {
                TryTouchGameObject(hit.point, hit.collider.gameObject, status, touch.position);
            }
        }
#else
        if (EventSystem.current.IsPointerOverGameObject()) {
            return;
        }

        int status = 0;
        if (isMouseDown()) {
            status = 1;
        } else if (isMouseUp()) {
            status = 3;
        } else if (isMouseHold()) {
            status = 2;
        }

        if (status != 0) {
            RaycastHit hit;
            Ray ray = rayCamera.ScreenPointToRay(Input.mousePosition);
            Transform select = gameObject.transform;
            if (Physics.Raycast(ray, out hit, maxDistance)) {
                TryTouchGameObject(hit.point, hit.collider.gameObject, status, Input.mousePosition);
            }
        }
#endif
    }
}
