using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
public class MapController : MonoBehaviour {
	public MapPlayer playerPrefab = null;
	// Use this for initialization
	void Start () {
		CameraClickEventListener _data = GetComponent<CameraClickEventListener> ();
			_data.onClick += MoveTo;
	}

		void MoveTo(Vector3 vec3,GameObject obj){
			playerPrefab.MoveTo (vec3, obj);
	}
	// Update is called once per frame
	void Update () {
		
	}

}
}
