using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK
{
	[XLua.LuaCallCSharp]
	public class UIReference : MonoBehaviour
	{
		public GameObject[] refs;

        Dictionary<string, GameObject> dic = null;

        HashSet<Object> set = null;

//         void Start() {
// 
// 		}

		public GameObject Get (string name)
		{
            if (refs == null) {
                return null;
            }

            if (dic == null)
            {
                dic = new Dictionary<string, GameObject>();
            }

			if (dic.Count == 0 && refs.Length != 0) {
				for (int i = 0; i < refs.Length; i++) {
					if (refs[i] != null) {
						dic [refs [i].name] = refs [i];
					}
				}
			}

			GameObject obj;
			if (dic.TryGetValue (name, out obj)) {
				return obj;
			}

			return null;
		}
        
        public void AddRef(Object obj) {
            if (set == null)
            {
                set = new HashSet<Object>();
            }
            set.Add(obj);
        }

        public void RemoveRef(Object obj) {
            if (set == null)
            {
                return;
            }

            set.Remove(obj);
        }

        void OnDestroy() {
            refs = null;
            if (set != null)
            {
                set.Clear();
            }
            if (dic != null)
            {
                dic.Clear();
            }
        }

        public GameObject Get (int idx)
		{
			if (idx < 1 || idx > refs.Length) {
				return null;
			}

			return refs[idx-1];
		}

		public Component Get (int idx, System.Type type) {
			GameObject obj = Get (idx);
			if (obj != null) {
				return obj.GetComponent (type);
			}
			return null;
		}

		public Component Get (string name, System.Type type)
		{
			GameObject obj = Get (name);
			if (obj != null) {
				return obj.GetComponent (type);
			}
			return null;
		}

		#if UNITY_EDITOR
		static void AppendToChild (Transform trans)
		{
			UIReference r = trans.gameObject.GetComponent<UIReference> ();
			if (trans.childCount == 0) {
				if (r != null) {
					DestroyImmediate (r);
				}
				return;
			}

			if (r == null) {
				r = trans.gameObject.AddComponent<UIReference> ();
			}

			r.refs = new GameObject[trans.childCount];

			for (int i = 0; i < trans.childCount; i++) {
				Transform child = trans.GetChild (i);
				r.refs [i] = child.gameObject;
				AppendToChild (child);
			}
		}

		[ContextMenu ("Append To All Children")]
		public void DoSomething ()
		{
			AppendToChild (transform);
		}
		#endif
	}
}
