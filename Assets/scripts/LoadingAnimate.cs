using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class LoadingAnimate : MonoBehaviour {
	public Animator animator;
	public Renderer process;
	public TextMesh processText;
	public TextMesh tipsText;

	public string nextSceneName = "login_scene2";
	public bool nextSceneUseAnimate = false;
	public System.Action nextSceneCallback = null;
    public bool unloadResources = false;

	public System.Action BeforeSceneUnload;
	public System.Action AfterSceneLoad;
	public System.Action AfterSceneReady;

	bool start = false;
    public void Load(string name, bool useAnimate = false, System.Action callback = null, bool unloadResources = false) {
		nextSceneName = name;
		nextSceneUseAnimate = useAnimate;
		nextSceneCallback = callback;
        this.unloadResources = unloadResources;
		if (start) {
			loadNextScene(nextSceneName, nextSceneUseAnimate, nextSceneCallback);
		}
		// UnityEngine.SceneManagement.SceneManager.LoadScene("loading2");
	}

	public void SetPercent(float value) {
		if (process != null) {
			process.material.SetFloat("FillAmount", value);
		}

		if (processText != null) {
			processText.text = string.Format("{0}%", (int)(value * 100));
		}
	}

	bool isLoading = false;
	public void StartLoading() {
		isLoading = true;
	}

	public void FinishLoading() {
		isLoading = false;
	}

	void Start() {
		start = true;
		SetPercent(0);
		loadNextScene(nextSceneName, nextSceneUseAnimate, nextSceneCallback);
	}

	void loadNextScene(string name, bool useAnimate = false, System.Action callback = null) {
		StartCoroutine(startNextScene(name, useAnimate, callback));
	}

	IEnumerator startNextScene(string name, bool useAnimate = false, System.Action callback = null) {
		if (useAnimate) {
			animator.gameObject.SetActive(true);
			animator.SetInteger("sta", 0);

			while (!animator.GetCurrentAnimatorStateInfo(0).IsName("load_ani2")) {
				yield return null;
			}

			yield return new WaitForSeconds(0.5f);
		} else {
			animator.gameObject.SetActive(false);
		}

		if (BeforeSceneUnload != null)
			BeforeSceneUnload();

        // Scene _currentScene = SceneManager.GetActiveScene();
        // yield return SceneManager.UnloadSceneAsync(_currentScene);
        ResourceBundle.LoadScenes(name);
        yield return SceneManager.LoadSceneAsync(name, LoadSceneMode.Single);

        if (unloadResources) {
            SGK.ResourcesManager.UnloadUnusedAssets();
        }

		Scene newlyLoadedScene = SceneManager.GetSceneAt(SceneManager.sceneCount - 1);
		SceneManager.SetActiveScene(newlyLoadedScene);

        if (AfterSceneLoad != null)
			AfterSceneLoad();

		if (callback != null) {
			callback();
		}

		while(isLoading) {
			yield return null;
		}

		if (useAnimate) {
			Debug.Log("load finished");
			animator.SetInteger("sta", 1);

			yield return new WaitForSeconds(1.0f);
		}

		if (AfterSceneReady != null) {
			AfterSceneReady();
		}

		Destroy(gameObject);
		// SceneManager.UnloadSceneAsync(_currentScene);
	}

    private void OnDestroy() {
        nextSceneCallback = null;
        BeforeSceneUnload = null;
        AfterSceneLoad = null;
        AfterSceneReady = null;
    }
}
