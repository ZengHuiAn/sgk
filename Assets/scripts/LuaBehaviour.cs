using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using XLua;

namespace SGK {
	// [DisallowMultipleComponent]
    public class LuaBehaviour : MonoBehaviour {
        [CSharpCallLua]
        public delegate void LuaObjectAction(object lauObject, params object [] args);

        [CSharpCallLua]
        public delegate object CreateLuaBehaviourFunc(string path);
        static Dictionary<string, CreateLuaBehaviourFunc> statless_file = new Dictionary<string, CreateLuaBehaviourFunc>();
        public static void CleanStatlessFile() {
            statless_file.Clear();
        }

        public static void AddStatlessFile(string path, CreateLuaBehaviourFunc func) {
            statless_file[path] = func;
        }

        LuaObjectAction l_Start;
        LuaObjectAction l_OnEnable;
        LuaObjectAction l_OnDisable;
        LuaObjectAction l_OnDestroy;
        LuaObjectAction l_Update;
        LuaObjectAction l_onEvent;
        LuaObjectAction l_OnApplicationPause;

        public string luaScriptFileName = "";
        public LuaTable luaObject = null;
        public object [] args = null;

        bool scriptIsReady = false;
        bool started = false;
        bool needCallLuaStart = false;
		bool is_OnDisable = false;
        public LuaTable GetScript() {
            return luaObject;
        }

        void Start() {
            if (!SceneService.persistentSceneLoaded) {
                StartCoroutine(InitScriptWithLuaVM());
            } else {
                InitScript();
            }
        }

        IEnumerator InitScriptWithLuaVM() {
            if (!SceneService.persistentSceneLoaded) {
                yield return SceneService.LoadPersistentScene();
            }
            InitScript();
        }

        void InitScript() {
            started = true;

            if (!string.IsNullOrEmpty(luaScriptFileName) && this.luaObject == null) {
                LoadScript(luaScriptFileName, this.luaObject, args);
            } else {
                luaStart();
            }
        }

        public LuaTable LoadScript(string luaScriptFileName, LuaTable i_luaObject,  params object [] args) {
            this.luaScriptFileName = luaScriptFileName;
            this.args = args;

            // release old object
            if (luaObject != null && luaObject != i_luaObject) {
                OnDisable();
                luaObject.Dispose ();
                l_Start = null;
                l_OnDestroy = null;
                l_Update = null;
                l_onEvent = null;
                luaObject = null;
            }

            bool needPreload = false;
            if (i_luaObject != null && luaObject != i_luaObject) {
                luaObject = i_luaObject; 
                needPreload = true;
            } else if (!string.IsNullOrEmpty(luaScriptFileName)) {
                luaObject = loadDelegate(luaScriptFileName);
                needPreload = true;
            }

            if (luaObject == null) {
                return null;
            }

            luaObject.Set("gameObject", gameObject);
            luaObject.Set("LuaBehaviour", this);

            l_Start     = luaObject.Get<LuaObjectAction>("Start");
            l_OnEnable  = luaObject.Get<LuaObjectAction>("OnEnable");
            l_OnDisable = luaObject.Get<LuaObjectAction>("OnDisable");
            l_OnDestroy = luaObject.Get<LuaObjectAction>("OnDestroy");

            l_Update    = luaObject.Get<LuaObjectAction>("Update");
            l_onEvent   = luaObject.Get<LuaObjectAction>("onEvent");

            l_OnApplicationPause = luaObject.Get<LuaObjectAction>("OnApplicationPause");

            if (needPreload) {
                LuaObjectAction preload = luaObject.Get<LuaObjectAction>("OnPreload");
                if (preload != null) {
                    if (args != null) {
                        preload(luaObject, args);
                    } else {
                        preload(luaObject);
                    }
                }
                preload = null;
            }

            needCallLuaStart = true;
            luaStart();
            return luaObject;
        }

        public void LuaRegisterEventAndCallAfterStart()
        {
            is_OnDisable = false;
            LuaController.RegisterEventListener(luaObject);
            scriptIsReady = true;

            foreach (CallInfo info in _callAfterStart)
            {
                Call(info.eventName, info.param);
            }
            _callAfterStart.Clear();
        }

        void luaStart() {
            if (!started || luaObject == null) {
                return;
            }

            needCallLuaStart = false;

            if (l_Start != null) {
                LuaFunction func = luaObject.Get<LuaFunction>("Start");
                if (args != null) {
                    //l_Start(luaObject, args);
                    LuaController.Sync(func, luaObject, args);
                } else {

                    LuaController.Sync(func, luaObject);
                    // l_Start(luaObject);
                }
                func = null;
            }
            else
            {
                LuaRegisterEventAndCallAfterStart();
            }
        }

        void Update() {
            if (needCallLuaStart) {
                luaStart();
            }

            if (scriptIsReady && l_Update != null) l_Update(luaObject);
        }

        void OnEnable() {
            if (scriptIsReady && luaObject != null) {
                if (l_OnEnable != null) {
                    l_OnEnable(luaObject);
                }
				is_OnDisable = false;
                LuaController.RegisterEventListener(luaObject);
            }
        }

        void OnApplicationPause(bool pauseStatus) {
            if (scriptIsReady && luaObject != null) {
                if (l_OnApplicationPause != null) {
                    l_OnApplicationPause(luaObject, pauseStatus);
                }
            }
        }

        void OnDisable() {
			if (scriptIsReady && luaObject != null && L != null && !is_OnDisable) {
                if (l_OnDisable != null) {
                    l_OnDisable(luaObject);
                }
				is_OnDisable = true;
                LuaController.RemoveEventListener(luaObject);
            }
        }

        public void Dispose() {
            if (scriptIsReady) {
                if (true || !is_OnDisable) {
                    is_OnDisable = true;
                    LuaController.RemoveEventListener(luaObject);
                }
            }
            started = false;
            scriptIsReady = false;

            if (l_OnDestroy != null && L != null) l_OnDestroy(luaObject);

            l_Start = null;
            l_OnDestroy = null;
            l_Update = null;
            l_onEvent = null;
            l_OnDisable = null;
            l_OnEnable = null;
            l_OnApplicationPause = null;

            if (L != null && luaObject != null) {
                luaObject.Dispose();

            }
            luaObject = null;
        }

        void OnDestroy() {
            Dispose();
        }

        public void onEvent(string eventName) {
            if (luaObject == null) {
                return;
            }

            LuaObjectAction act = luaObject.Get<LuaObjectAction>(eventName);
            if (act != null) {
                act(luaObject);
            } else if (l_onEvent != null) {
                l_onEvent(luaObject, eventName);
            }
        }

        struct CallInfo {
            public string eventName;
            public object [] param;
        }

        List<CallInfo> _callAfterStart = new List<CallInfo>();
        public void Call(string eventName, params object [] param) {
            if (scriptIsReady) {
                LuaObjectAction act = luaObject.Get<LuaObjectAction>(eventName);
                if (act != null) {
                    act(luaObject, param);
                }
            } else {
                CallInfo info = new CallInfo();
                info.eventName = eventName;
                info.param = param;
                _callAfterStart.Add(info);
            }
        }

        public void onEventV(params object [] param) {
            if (luaObject == null) {
                return;
            }
            
            if (l_onEvent != null) {
                l_onEvent(luaObject, param);
            }
        }

        public static LuaTable loadDelegate(string luaScriptFileName) {
            if (!string.IsNullOrEmpty(luaScriptFileName) && L != null) {
                CreateLuaBehaviourFunc func;
                if (statless_file.TryGetValue(luaScriptFileName, out func)) {
                    object obj = func(luaScriptFileName);
                    if (obj != null) {
                        return obj as LuaTable;
                    }
                }

                object[] objs = L.DoString(FileUtils.LoadBytesFromFile(luaScriptFileName), luaScriptFileName);

                if (objs != null && objs.Length > 0) {
                    return objs[0] as LuaTable;
                }
                Debug.LogWarningFormat("Do file failed");
            }
            return null;
        }

        public static void Append(GameObject obj, string script, params object [] param) {
            LuaBehaviour lb = obj.AddComponent<LuaBehaviour>();
            lb.luaScriptFileName = script;
            lb.args = param;
        }

        static LuaEnv L {
            get {
                return LuaController.GetLuaState();
            }
        }
    }
}
