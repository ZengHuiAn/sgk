using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
	public class MapClickableScript : MonoBehaviour, MapClickableObject {
		public TextAsset script;
		public void OnClick(GameObject obj) {
			LuaController.DoString(script.bytes, gameObject, obj);
		}
	}
}