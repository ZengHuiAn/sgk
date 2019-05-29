using UnityEngine;
using System.Collections;
using UnityEngine.UI;

[ExecuteInEditMode]
[XLua.LuaCallCSharp]
public class FollowTarget : MonoBehaviour {
    public Transform target;
    public float speed = 1.0f;
    public ToggleGroup toggleGroup;

    public bool followRotation = false;
    public bool followScale = false;

    void LateUpdate () {
        Transform real_target = target;
        if (toggleGroup != null) {
            foreach(Toggle toggle in toggleGroup.ActiveToggles()) {
                real_target = toggle.gameObject.transform;
            }
        }

        if (real_target != null) {
            if (speed > 0) {
                transform.position = Vector3.MoveTowards(transform.position, real_target.position, speed * Time.deltaTime);
            } else {
                transform.position = target.position;
            }

            if (followRotation) {
                transform.rotation = target.rotation;
            }

            if (followScale) {
                transform.localScale = target.localScale;
            }
        }
    }

    [ContextMenu("Execute")]
    void Execute() {
        transform.position = target.position;
    }

    public static void Follow(GameObject obj, Transform target, float speed = -1, bool rotation = false, bool scale = false) {
        FollowTarget follow = obj.GetComponent<FollowTarget>();
        if (follow == null) {
            follow = obj.AddComponent<FollowTarget>();
        }
        follow.target = target;
        follow.followRotation = rotation;
        follow.followScale = scale;
        follow.speed = speed;
    }

    public static void Follow(GameObject obj, GameObject target, float speed = -1, bool rotation = false, bool scale = false) {
        Follow(obj, target.transform, speed, rotation, scale);
    }
}
