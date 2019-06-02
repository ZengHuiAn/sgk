using UnityEngine;
using System.Collections;

public class AnimateMaterial : MonoBehaviour
{
    public float scrollSpeedX = 0.5f;
    public float scrollSpeedY = 0.5f;
    public float offsetX = 0f;
    public float offsetY = 0f;

    // Use this for initialization
    void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
        offsetX += (Time.deltaTime* scrollSpeedX) /10.0f;
        offsetY += (Time.deltaTime * scrollSpeedY) / 10.0f;
        GetComponent<Renderer>().material.SetTextureOffset("_MainTex", new Vector2(offsetX, offsetY));
	}
}
