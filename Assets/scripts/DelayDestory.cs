using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DelayDestory : MonoBehaviour {
	public float delayTime = 1.0f;

    void OnEnable() {
        Invoke("DelayFunc", delayTime);
    }

	void DelayFunc()
	{
        SGK.GameObjectPoolManager.getInstance().Release(gameObject);
    }
}
