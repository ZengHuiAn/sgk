using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIRingMenu : MonoBehaviour {
    public float distance = 100;
    public GameObject [] menus;

    public System.Action<int> onClick;

    private void OnEnable() {
        int n = 0;
        for (int i = 0; i < menus.Length; i++) {
            if (menus[i].activeSelf) {
                n++;
            }
        }
        // float sep = 360 / n;

        // Vector3 startPos = new Vector3(0, distance, 0);
        for (int i = 0; i < menus.Length; i++) {
            if (!menus[i].activeSelf) {
                continue;
            }

            /*float angle = sep * i - 45;
            Vector3 pos = Quaternion.Euler(0, 0, angle) * startPos;
            menus[i].transform.localPosition = pos;*/
            int j = i;
            UGUIClickEventListener.Get(menus[i]).onClick = () => {
                if (onClick != null) {
                    onClick(j);
                }
            };
        }
    }

    // Update is called once per frame
    void Update () {
		
	}

    private void OnDestroy() {
        onClick = null;
    }
}
