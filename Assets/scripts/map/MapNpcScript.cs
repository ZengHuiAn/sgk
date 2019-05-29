using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

namespace SGK {
	public class MapNpcScript : MonoBehaviour {		
		public TextAsset script;
		public string scriptFileName;
		void Start() {
			if (script != null) {
				LuaController.DoStringInThread(script.text, script.name, gameObject);
			}

			if (!string.IsNullOrEmpty(scriptFileName)) {
				LuaController.DoStringInThread(FileUtils.LoadBytesFromFile(scriptFileName), scriptFileName, gameObject);
			}
		}

		public static void Attach(GameObject obj, string fileName) {
			MapNpcScript script = obj.AddComponent<MapNpcScript>();
			script.scriptFileName = fileName;
		}
	}
}