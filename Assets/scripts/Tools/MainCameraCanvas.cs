using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteInEditMode]
public class MainCameraCanvas : MonoBehaviour {
	// Use this for initialization
	void Start () {
		GetComponent<Canvas>().worldCamera = Camera.main;
	}
}
