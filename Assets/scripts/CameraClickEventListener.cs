using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.EventSystems;

[RequireComponent(typeof(Camera))]
public class CameraClickEventListener : MonoBehaviour {
	public System.Action<Vector3, GameObject> onClick;
	public float maxDistance = 100f;

	float mouseDownTime = 0;
	bool keepMove = false;

	Camera rayCamera;

	void Start() {
		rayCamera = GetComponent<Camera>();
	}
	public void ResetClick(){
		keepMove = false;
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

	void TryClickGameObject(Vector3 position, GameObject obj, bool checkModelClickEventListener = true) {
        ModelClickEventListener mc = checkModelClickEventListener ? obj.GetComponent<ModelClickEventListener>() : null;
		if (mc != null) {
			mc.Fire(position, obj);
		} else if (onClick != null) {
			onClick(position, obj);
		}
	}

    bool isTouching = false;

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

        if (touch.phase == TouchPhase.Began) {
            if (IsPointerOverGameObject(touch.fingerId)) {
                return;
            }
            isTouching = true;
		}


		if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled) {
            isTouching = false;
			return;
		}

        if (!isTouching) {
            return;
        }

		if (IsPointerOverGameObject(touch.fingerId)) {
			return;
		}

		RaycastHit hit;
		Ray ray = rayCamera.ScreenPointToRay (touch.position);
		Transform select = gameObject.transform;

		if (Physics.Raycast (ray, out hit, maxDistance)){
			TryClickGameObject(hit.point, hit.collider.gameObject, true);
		}
#else
        if (isMouseDown()) {
            if (EventSystem.current.IsPointerOverGameObject()) {
                return;
            }

            isTouching = true;
            mouseDownTime = Time.realtimeSinceStartup;
		}

        if (EventSystem.current.IsPointerOverGameObject()) {
            return;
        }

        if (!isTouching) {
            return;
        }

        if (isMouseUp()) {
			keepMove = (Time.realtimeSinceStartup - mouseDownTime >= 1.0f);
            isTouching = keepMove;
		}


        if (keepMove || isMouseHold() || isMouseUp()){
			RaycastHit hit;
			Ray ray = rayCamera.ScreenPointToRay (Input.mousePosition);
			Transform select = gameObject.transform;

			if (Physics.Raycast (ray, out hit, maxDistance,~(1<<20))){
				TryClickGameObject(hit.point, hit.collider.gameObject, isMouseUp() && !keepMove);
			}
		}
#endif
	}

    private void OnDestroy() {
        onClick = null;
    }
}
