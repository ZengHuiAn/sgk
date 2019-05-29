using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
	public class MapHelper : MonoBehaviour {
		public CameraClickEventListener clickListener;
		public SGK.MapPlayer player;
		void Start() {
			if (player != null && clickListener != null) {
				clickListener.onClick = (Vector3 pt, GameObject obj)=> {
					player.MoveTo(pt, obj);
				};
			}
		}

	}
}
