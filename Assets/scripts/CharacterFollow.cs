using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class CharacterFollow : MonoBehaviour {
	public NavMeshAgent agent; 

	public bool followPosition;
	public Vector3 offset;

	Animator animator;
	

	int walk_id = 0;
	int direction_id = 0;

	SGK.CharacterSprite character = null;

	// Use this for initialization
	void Start () {
		animator = GetComponent<Animator>();
		if (animator != null) {
			walk_id = Animator.StringToHash("walk");
			direction_id = Animator.StringToHash("direction");
			animator.SetInteger(direction_id, 1);
		}

		character = GetComponent<SGK.CharacterSprite>();
	}

	// Update is called once per frame
	void Update () {
		if (followPosition) {
			gameObject.transform.position = agent.gameObject.transform.position + offset;
		}

		bool isRunning = (agent.velocity.sqrMagnitude > 0.1f);
		int direction = 0;
		if (agent.velocity.sqrMagnitude > 0.1f) {
			int angle = (int)(angle360(new Vector3(1, 0, -1), agent.velocity, new Vector3(-1, 0, -1)) - 22.5f);
			if (angle < 0) {
				angle += 360;
			}
			direction = 1 + (int)Mathf.Floor(angle / 45);
		}

		if (animator != null) {
			animator.SetBool(walk_id, isRunning);

			if (direction > 0) {
				animator.SetInteger(direction_id, direction);
			}
		}
		
		if (character) {
			character.idle = !isRunning;
			if (direction > 0) {
				character.direction = direction - 1;
			}
		}
	}

	float angle360(Vector3 from, Vector3 to, Vector3 right)
	{
		float angle = Vector3.Angle(from, to);
		return (Vector3.Angle(right, to) > 90f) ? 360f - angle : angle;            
    }


	[ContextMenu("Execute")]
	public void UpdatePosition() {
		gameObject.transform.position = agent.gameObject.transform.position + offset;
	}


	[ContextMenu("Save Current Value")]
	public void SaveValue() {
		offset = gameObject.transform.position - agent.gameObject.transform.position;
	}
}
