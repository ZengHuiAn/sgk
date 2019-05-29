using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DontDestroy : MonoBehaviour {
	static List<DontDestroy> list = new List<DontDestroy>();

    public int order;

	void Start() {
		list.Add(this);
		DontDestroyOnLoad(this);
	}

	void OnDestroy() {
		list.Remove(this);
	}

    public static void Clean() {
        List<DontDestroy> old = list;
        list = new List<DontDestroy>();

        old.Sort(delegate (DontDestroy x, DontDestroy y)
        {
            return x.order.CompareTo(y.order);
        });

        foreach (DontDestroy dd in old) {
			Destroy(dd.gameObject);
		}
	}
}
