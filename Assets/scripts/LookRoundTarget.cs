using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class LookRoundTarget : MonoBehaviour {
    public Transform target;
    public float distance = 1.0f;

    [ContextMenu("Execute")]
	void Update () {
        gameObject.transform.position = target.position - this.transform.forward * distance;
        gameObject.transform.LookAt(target);
    }
}
