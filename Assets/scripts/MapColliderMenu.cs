using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace SGK
{
    public class MapColliderMenu : MonoBehaviour
    {
        public TextAsset script;
        public string LuaTextName;
        public string LuaCondition;
        public int interaction = -1;//无交互
        public string[] values;
        static float time = 0;
        public float interDeltime = 0.25f;
        [XLua.CSharpCallLua]
        public delegate void LuaThreadEval(string script, string chunkName, MonoBehaviour behaviour, params object[] objs);
        LuaThreadEval luaThreadEval = null;
        BoxCollider _collider;
        void Start() { }
        public BoxCollider NPCcollider
        {
            get
            {
                if (_collider == null)
                {
                    _collider = GetComponent<BoxCollider>();
                }
                return _collider;
            }
        }
        void LuaNPCScript(GameObject obj)
        {
            if (Time.time - time > interDeltime)
            {
                time = Time.time;
                MapPlayer mapPlayer = GetComponent<MapPlayer>();
                MapMonster mapMonster = GetComponent<MapMonster>();
                if (mapPlayer != null && mapPlayer.enabled)
                {
                    mapPlayer.UpdateDirection((obj.transform.position - transform.position).normalized, true);
                }
                else if (mapMonster != null && mapMonster.enabled)
                {
                    mapMonster.UpdateDirection((obj.transform.position - transform.position).normalized);
                }

                string fileName = (script == null) ? "guide/" + LuaTextName + ".lua" : script.name;
                if (luaThreadEval == null)
                {
                    luaThreadEval = LuaController.GetLuaValue<LuaThreadEval>("ThreadEvalWithGameObject");
                }
                if (luaThreadEval != null)
                {
                    luaThreadEval(fileName, fileName, this, values);
                }
                else
                {
                    LuaController.DoFile(fileName, values);
                }
            }
        }
        void OnDestroy()
        {
            luaThreadEval = null;
        }
        void OnTriggerEnter(Collider other)
        {
            interaction = 1;
            LuaNPCScript(other.gameObject);
        }
        void OnTriggerExit(Collider other)
        {
            interaction = 0;
            LuaNPCScript(other.gameObject);
        }
        //void OnTriggerStay(Collider other) { }

    }
}