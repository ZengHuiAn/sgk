using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class MapPortalPath : MonoBehaviour {
	public Color color = Color.red;
#if UNITY_EDITOR
	void OnDrawGizmos() {
		Gizmos.color = color;
		OffMeshLink [] link = FindObjectsOfType<OffMeshLink>();
		for (int i = 0; i < link.Length; i++) {
			Gizmos.DrawLine(link[i].startTransform.position, link[i].endTransform.position);
		}
	}
#endif
}
