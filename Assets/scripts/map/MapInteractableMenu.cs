using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
	public class MapInteractableMenu : MonoBehaviour, MapInteractableObject {
		public TextAsset script;
		public string LuaTextName;
		public string LuaCondition;
		public string [] values;

		static float last_interact_time = 0;
        public static float interact_protect_time = 0.25f;

		[XLua.CSharpCallLua]
		public delegate void LuaThreadEval(string script, string chunkName, MonoBehaviour behaviour, params object [] objs);
		LuaThreadEval luaThreadEval = null;
        void Start(){ }
        public virtual void Interact(GameObject obj) {
            if (Time.realtimeSinceStartup - last_interact_time < interact_protect_time) {
                return;
            }
            
            last_interact_time = Time.realtimeSinceStartup;
            MapPlayer mapPlayer = GetComponent<MapPlayer>();
            MapMonster mapMonster = GetComponent<MapMonster>();
            if (mapPlayer != null && mapPlayer.enabled) {
                mapPlayer.UpdateDirection((obj.transform.position - transform.position).normalized, true);
            } else if (mapMonster != null && mapMonster.enabled) {
                mapMonster.UpdateDirection((obj.transform.position - transform.position).normalized);
            } else {

            }

            string fileName = (script == null) ? "guide/" + LuaTextName + ".lua" : script.name;
            if (luaThreadEval == null) {
                luaThreadEval = LuaController.GetLuaValue<LuaThreadEval>("ThreadEvalWithGameObject");
            }
            if (luaThreadEval != null) {
                luaThreadEval(fileName, fileName, this, values);
            } else {
                LuaController.DoFile(fileName, values);
            }
        }
        void OnDestroy() {
            luaThreadEval = null;
        }
    }
}
