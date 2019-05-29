using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace SGK {
    [LuaCallCSharp]
    public class LuaLoader : MonoBehaviour {
        bool started = false;

        IEnumerator Start() {
            if (!SceneService.persistentSceneLoaded) {
                yield return SceneService.LoadPersistentScene();
            }
            started = true;
        }

        public bool isReady {
            get { return started; }
        }

        LuaTable loadLuaBehaviour(string luaScriptFileName, params object[] args) {
            LuaBehaviour[] lbs = GetComponents<LuaBehaviour>();
            for (int i = 0; i < lbs.Length; i++)
            {
                if (lbs[i].luaScriptFileName == luaScriptFileName)
                {
                    return lbs[i].GetScript();
                    //return lbs[i].LoadScript(luaScriptFileName, null, args);
                }
                
            }
            LuaBehaviour lb = gameObject.AddComponent<LuaBehaviour> ();
            return lb.LoadScript(luaScriptFileName, null, args);
        }

        public void onEvent(string eventName) {
            LuaBehaviour [] lbs = GetComponents<LuaBehaviour> ();
            for (int i = 0; i < lbs.Length; i++) {
                lbs [i].onEvent (eventName);
            }
        }

        public static LuaTable Load(string luaScriptFileName, params object [] args) {
            LuaLoader loader = FindObjectOfType<LuaLoader>();
            return loader.loadLuaBehaviour(luaScriptFileName, args);
        }
    }
}
