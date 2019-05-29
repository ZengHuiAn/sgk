using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace SGK {
	public class EncounterFight : MonoBehaviour {
		public CharacterSprite character = null;
		public System.Action<bool, GameObject> onMove;
		public float mintime = 2;//切换场景遇怪保护时间
		public float probability = 10;//遇怪初始几率
		public float now_probability = 0;
		public float autoincrement = 0.1f;
		float ram = 0;
		float ProtectTime = 0;
		// Use this for initialization
		void Start () {
			//RandomRef ();
			//Debug.LogError (Time.time);
			now_probability = probability;
		}
		public void RandomRef(){
			now_probability = probability;
			ram = Random.Range(probability,100);
			ProtectTime = 0;
		}
		void FixedUpdate(){
			if (onMove != null && character && !character.idle) {
				if (now_probability >= ram) {
					onMove (true,this.gameObject);
					RandomRef ();
				} else {
					if (ProtectTime != 0 && (ProtectTime + mintime) <= Time.time) {
						now_probability = now_probability + autoincrement;
					}else if(ProtectTime == 0){
						ProtectTime = Time.time;
					}
				}
			}
		}
        private void OnDestroy() {
            onMove = null;
        }
    }
}
