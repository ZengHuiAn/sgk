using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

namespace SGK {
	public class MapWaypointMovement : MonoBehaviour {
		public Transform [] waypoints;

		int target = -1;

		NavMeshAgent agent;		

		void Start() {
			agent = GetComponent<NavMeshAgent>();
			if (agent != null) {
				agent.SetDestination(waypoints[0].position);
			}
		}

		void Update () {
			if (agent == null || agent.pathPending)
				return;

			if (agent.remainingDistance <= agent.stoppingDistance) {
				target = (target + 1) % waypoints.Length;
				agent.SetDestination(waypoints[target].position);
			}
		}

		void OnDrawGizmosSelected()
		{
			if (waypoints != null) {
				for (int i = 0; i <waypoints.Length; i++) {
					Transform from = waypoints[i];
					Transform to = (i == waypoints.Length - 1) ? waypoints[0] : waypoints[i+1];
					Gizmos.color = Color.red;
					Gizmos.DrawLine(from.position, to.position);
				}
			}
		}
	}
}
