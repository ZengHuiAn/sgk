using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;
public class AccountLoginScene : MonoBehaviour {
	public Scrollbar _scrollbar;
	public Text _percent;
	public System.Action callback; // release on destory
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}
	public void LoadGame(string sceneName,System.Action _callback) {
		callback = _callback;
		StartCoroutine(StartLoading(sceneName));
	}
	private IEnumerator StartLoading(string sceneName) {
	    int displayProgress = 0;
	    int toProgress = 0;
        //AsyncOperation op = Application.LoadLevelAsync(scene);
        SGK.SceneService.GetInstance().Callback(0);
        ResourceBundle.LoadScenes(sceneName);
        AsyncOperation op = SceneManager.LoadSceneAsync(sceneName,LoadSceneMode.Single);        
        op.allowSceneActivation = false;
	    while(op.progress < 0.9f) {
	        toProgress = (int)op.progress * 100;
	        while(displayProgress < toProgress) {
	            ++displayProgress;
	            SetLoadingPercentage(displayProgress);
	            yield return new WaitForEndOfFrame();
	        }
			yield return new WaitForEndOfFrame();
	    }

	    toProgress = 100;
		while (displayProgress < toProgress) {
			++displayProgress;
			SetLoadingPercentage (displayProgress);
			yield return new WaitForEndOfFrame ();
		}
        
        op.allowSceneActivation = true;

        while (!op.isDone) {
			yield return new WaitForEndOfFrame ();
		}

        SGK.SceneService.GetInstance().Callback(1);

        if (callback != null) {
			callback ();
		}

        SGK.SceneService.GetInstance().Callback(2);
        Destroy (gameObject);

        SGK.SceneService.GetInstance().FinishLoading();
    }
	void OnDestroy(){
        callback = null;
    }
	void OnSceneLoaded(Scene scence, LoadSceneMode mod){

	}
	void StartLoading() {

	}
	public void SetLoadingPercentage(int displayProgress){
		// _scrollbar.size = (float)displayProgress/100;
		string desc = "";
		if (displayProgress < 20) {
			desc = "正在翻开地图...";
		} else if (displayProgress < 50) { 
			desc = "正在描绘画像...";
		} else if (displayProgress < 75) {
			desc = "正在加载场景...";
		} else {
			desc = "正在获取好友列表...";
		}
        // _percent.text = desc + displayProgress + "%";
        SGK.SceneService.GetInstance().SetPercent((float)displayProgress / 100, desc);
    }
}
