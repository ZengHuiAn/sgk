using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
	public class BattlefieldEventDispatcher : MonoBehaviour {
		LuaBehaviour battleScript;

		[Range(0,10)]
		public float delay;
		public string eventName;
		public string stringValue;
		public int intValue;
		public float floatValue;
		public bool boolValue;
		
		// Use this for initialization
		void Start () {
			GameObject battleObject = GameObject.FindWithTag("battle_root");
			if (battleObject != null) {
				battleScript = battleObject.GetComponent<LuaBehaviour>();
				StartCoroutine(ToggleBattleEvent());
			}
		}

		IEnumerator ToggleBattleEvent() {
			yield return new WaitForSeconds(delay);
			battleScript.onEventV(eventName, stringValue, intValue, floatValue, boolValue);
		}
	}
}
