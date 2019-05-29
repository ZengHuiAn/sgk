using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EffectPlayer : MonoBehaviour {
    public GameObject prefab;
    public float delay = 1.0f;

	// Use this for initialization
	void Start () {
        StartCoroutine(addPrefab());
	}
	
    IEnumerator addPrefab() {
        while (true) {
            GameObject n = Instantiate(prefab, transform);
            n.transform.localPosition = Vector3.zero;
            n.transform.localRotation = Quaternion.identity;
            n.transform.localScale = Vector3.one;

            Destroy(n, delay);
            yield return new WaitForSeconds(delay);
        }
    }

	// Update is called once per frame
	void Update () {
		
	}
}
