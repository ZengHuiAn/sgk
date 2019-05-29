using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class GameObjectPoolItem : MonoBehaviour {
    public UnityEvent onRelease;

    public void Release() {
        if (onRelease != null) {
            onRelease.Invoke();
        }
    }
}
