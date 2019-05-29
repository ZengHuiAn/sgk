using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
	public class MapInteractableMenuPlayer : MonoBehaviour, MapInteractableObject {
		public TextAsset script;
		public GameObject Character;
		public string Playerid;
		public string [] values;

        static float last_interact_time = 0;
        public static float interact_protect_time = 0.25f;

        public virtual void Interact(GameObject obj) {
            if (Time.realtimeSinceStartup - last_interact_time < interact_protect_time) {
                return;
            }
            last_interact_time = Time.realtimeSinceStartup;

            if (script != null){
				if (Character) {
					values [0] = Character.gameObject.transform.localPosition.x.ToString();
					values [1] = Character.gameObject.transform.localPosition.y.ToString();
					values [2] = Character.gameObject.transform.localPosition.z.ToString();
				}
				values [3] = Playerid;
				LuaController.DoString(script.bytes, values);
			}
		}
	}
}