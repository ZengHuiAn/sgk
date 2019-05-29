using System;
using UnityEngine.EventSystems;
using UnityEngine;

public class ModelClickEventListener : MonoBehaviour {
    public delegate void modelclickDelegate(GameObject go, Vector3 pos);
    public modelclickDelegate onClick;
    private double second = 0;
    public void Fire(Vector3 position, GameObject obj) {
        TimeSpan time = new TimeSpan(DateTime.Now.Ticks);
        if (time.TotalSeconds - second >= 1)
        {
            second = time.TotalSeconds;
            onClick(obj, position);
            //Debug.Log("秒 " + DateTime.Now.Second);
        }
    }

    public static ModelClickEventListener Get(GameObject obj) {
        ModelClickEventListener del = obj.GetComponent<ModelClickEventListener>();
        if (del == null) {
            del = obj.AddComponent<ModelClickEventListener>();
        }
        return del;
    }

    private void OnDestroy() {
        onClick = null;        
    }
}
