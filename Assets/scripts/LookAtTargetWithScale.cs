using UnityEngine;
using System.Collections;

[XLua.LuaCallCSharp]
public class LookAtTargetWithScale : MonoBehaviour {
    public Vector3 targetPosition;

    public Vector3 scaleRate = Vector3.zero;
	void Update () {
        if (!targetPosition.Equals(Vector3.zero)) {
            transform.LookAt(targetPosition);

            float distance = Vector3.Distance(targetPosition, transform.position);
            Vector3 scale = Vector3.one;

            if (scaleRate.x > 0) scale.x = distance * scaleRate.x;
            if (scaleRate.y > 0) scale.y = distance * scaleRate.y;
            if (scaleRate.z > 0) scale.z = distance * scaleRate.z;

            transform.localScale = scale;
        }
    }
}