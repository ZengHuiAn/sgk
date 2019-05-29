using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

// [XLua.LuaCallCSharp]
public class SDKScriptOOHOO : MonoBehaviour {
	public void ActiveGame() {
        UnityEngine.SceneManagement.SceneManager.LoadScene(SGK.SceneService.PRESISTENT_SCENE_BUILD_INDEX);
	}
}
