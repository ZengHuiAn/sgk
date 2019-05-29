using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

namespace SGK {
	public class MapPortal : MonoBehaviour, MapInteractableObject {
		public GameObject srcEffects;
		public GameObject destEffect;

		public OffMeshLink link;

		public float delay = 0.5f;

		public virtual void Interact(GameObject obj) {
			if (link == null) {
				return;
			}

			if (gameObject == link.startTransform.gameObject) {
				Portal(obj, link.endTransform.position);
			} else {
				Portal(obj, link.startTransform.position);
			}
		}

		public void Portal(GameObject obj, Vector3 position) {
			StartCoroutine(ProtalThread(obj, position));
		}

		IEnumerator ProtalThread(GameObject obj, Vector3 position) {
			if (srcEffects) {
				GameObject effect = Instantiate(srcEffects) as GameObject;
				effect.transform.position = obj.transform.position;
				Destroy(effect, 1);
			}

			yield return new WaitForSeconds(delay);

			NavMeshAgent agent = obj.GetComponent<NavMeshAgent>();
			if (agent == null) {
				obj.transform.position = position;
			} else {
				if (agent.isOnOffMeshLink) {
					agent.CompleteOffMeshLink();
				} else {
					agent.Warp(position);
				}
				yield return null;
			}

			if (destEffect != null) {
				GameObject effect2 = Instantiate(destEffect) as GameObject;
				effect2.transform.position = obj.transform.position;
				Destroy(effect2, 1);
			}
		}
	}
}