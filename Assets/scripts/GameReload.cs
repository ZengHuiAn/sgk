using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameReload : MonoBehaviour {
	void Start () {
        DontDestroy.Clean();

        SGK.LuaController.DisposeInstance();
        Invoke("Reload", 0.2f);
    }

    void Reload() {
        

        SceneManager.LoadScene(0);
    }
}
