using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace SGK {
public class CharacterSpriteIdle : MonoBehaviour {

	// Use this for initialization
	public bool Idle =	true;
	public int Direction = 0;
	public CharacterSprite characterSprite;
	public GameObject footprint;
        GameObject MainCamera;

    void Start () {
            MainCamera = GameObject.FindWithTag("MainCamera");
	}
	
	// Update is called once per frame
	void Update () {
		if (Idle != characterSprite.idle){
			Idle = characterSprite.idle;
			footprint.SetActive (!Idle);
		}
		if (Direction != characterSprite.direction) {
			Direction = characterSprite.direction;
			footprint.transform.localEulerAngles = new Vector3 (0, Direction* 45 + MainCamera.transform.localEulerAngles.y, 0);
		}
	}
}
}