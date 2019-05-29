using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(TextMesh))]
public class TextMeshCopy : MonoBehaviour {
	public TextMesh targetText;

	TextMesh selfMesh;

	// Use this for initialization
	void Start () {
		selfMesh = GetComponent<TextMesh>();
	}
	
	// Update is called once per frame
	void Update () {
		if (targetText != null) {
			selfMesh.text = targetText.text;
		}
	}
}
