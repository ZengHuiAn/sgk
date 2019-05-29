using UnityEngine;
using System.Collections;

public class PartnerStageScaler : MonoBehaviour {

    public float designWidth = 640;
    public float designHeight = 960;

    public float scaleMin = 0.75f;
    public float scaleMax = 1.25f;

    // Use this for initialization
    void Start () {
        updateScale();
	}

    void updateScale() {
        float scale = (Screen.width * 1.0f/ Screen.height) / (designWidth/ designHeight);

        scale = Mathf.Clamp(scale, scaleMin, scaleMax);

        
        transform.localScale = new Vector3(scale, scale, scale);

        /*
        float y = Mathf.Lerp(-1.75f, -2.5f, (scale - 0.75f) / (1.25f - 0.75f));
        Vector3 position = new Vector3(originPosition.x, y, originPosition.z);
        transform.localPosition = position;
        */
    }

    // Update is called once per frame
    void Update () {
        updateScale();
    }
}
