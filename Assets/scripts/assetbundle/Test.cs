using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SGK;
using UnityEngine.UI;

public class Test : MonoBehaviour {

	// Use this for initialization
	void Start () {
        Button b = GetComponent<Button>();
        Text text = GetComponentInChildren<Text>();
        text.text = Bundle.Number.ToString();

        b.onClick.AddListener(() => {
            Bundle.Number += 1;
            text.text = Bundle.Number.ToString();
        });
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
