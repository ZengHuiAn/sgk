using UnityEngine;
using System.Collections;

public class FollowUI : MonoBehaviour {
    public RectTransform ui;
    //public Camera camera;
    //public GameObject CubeObj;
    public Canvas canvas;
    void Update () {
        if (ui)
        {
            if (canvas.renderMode == RenderMode.ScreenSpaceCamera)
            {
                Vector3 vec3 = RectTransformUtility.WorldToScreenPoint(canvas.worldCamera, ui.position);
                //scr.z = 0;
                vec3.z = Mathf.Abs(Camera.main.transform.position.z - ui.position.z);
                this.transform.position = Camera.main.ScreenToWorldPoint(vec3);
            }else if (canvas.renderMode == RenderMode.ScreenSpaceOverlay){
                Vector3 vec3 = ui.position;
                //vec3.z = 0;
                vec3.z = Mathf.Abs(Camera.main.transform.position.z - ui.position.z);
                this.transform.position = Camera.main.ScreenToWorldPoint(vec3);
            }
        }
    }
}
