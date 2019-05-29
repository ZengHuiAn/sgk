using UnityEngine;
using System.Collections;

public class LookAtTarget : MonoBehaviour {
    public Transform target;
    public float speed = 360f;
	void Update () {
        if (target != null) {
            if (speed > 0) {
                transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(target.position - transform.position, Vector3.up), speed * Time.deltaTime);
            } else {
                transform.LookAt(target);
            }
        }
    }
}