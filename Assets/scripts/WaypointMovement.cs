using UnityEngine;
using System.Collections;
using DG.Tweening;

public class WaypointMovement : MonoBehaviour {

    [Range(0.1f, 20.0f)]
    public float speed = 1.0f;
    public bool jumpToFirst = false;

    public  Transform [] waypoints = { };

    public Transform defaultPoint;

    private int currentTarget = 0;
    public bool stoped = false;
	// Use this for initialization
	void Start () {
        currentTarget = 0;
	}
	
    public void StopMove() {
        currentTarget = 0;
        stoped = true;
        if (defaultPoint != null) {
            Vector3 localPostion = transform.InverseTransformPoint(defaultPoint.position);
            transform.DOLocalMove(localPostion, 0.2f);
        }
    }

    public void StartMove() {
        stoped = false;
    }

	// Update is called once per frame
	void Update () {
        if (waypoints.Length == 0 || stoped) {
            return;
        }

        Transform current = GetComponent<Transform>();
        Transform target = waypoints[currentTarget];

        if (currentTarget == 0 && jumpToFirst) {
            transform.position = target.position;
            currentTarget = (currentTarget + 1) % waypoints.Length;
            return;
        }

        Vector3 direction = Vector3.Normalize((target.position - current.position));
        Vector3 position = transform.position + direction * (Time.deltaTime * speed);

        if (Vector3.Distance(position, transform.position) >= Vector3.Distance(target.position, transform.position)) {
            transform.position = target.position;
            currentTarget = (currentTarget + 1) % waypoints.Length;
        } else {
            transform.position += direction * (Time.deltaTime * speed);
        }
    }
}
