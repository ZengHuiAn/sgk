using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimatorClickContinue : MonoBehaviour
{
    Animator ani;
    public GameObject next_anmation;

    GameObject UITopRoot;
    GameObject LockFrame;
    private void Start() {
        ani = GetComponent<Animator>();
        UITopRoot = GameObject.FindWithTag("UITopRoot");
        if (UITopRoot != null) {
            GameObject perfab = SGK.ResourcesManager.Load<GameObject>("prefabs/base/LockFrame.prefab");
            LockFrame = Instantiate(perfab, UITopRoot.transform);
        }

    }

    public void PauseAnimation() {
        if (ani != null) {
            ani.enabled = false;
        }
    }

    public void DestroySelf()
    {
        if (next_anmation != null)
        {
            Instantiate(next_anmation);
        }

        if (UITopRoot != null)
        {
            Destroy(LockFrame);
        }

        Destroy(this.gameObject);
    }
    void Update() {
#if !UNITY_EDITOR && (UNITY_IOS || UNITY_ANDROID)
        if (Input.touchCount == 1 && Input.GetTouch(0).phase == TouchPhase.Ended) {
            if (ani != null && !ani.enabled) {
                ani.enabled = true;
            }
        }
#else
        if (Input.GetMouseButtonUp(0)) {
            if (ani != null && !ani.enabled) {
                ani.enabled = true;
            }
        }
#endif
    }
}
