using UnityEngine;
using System.Collections;

public class DeemoDelay : MonoBehaviour {
	
	public float delayTime = 1.0f;

	void OnEnable () 
    {		
        StartCoroutine(DelayFunc()); 
        for (int i = 0; i < transform.childCount; i++) 
        {
            transform.GetChild(i).gameObject.SetActive(false);
        }
	}
	
	IEnumerator DelayFunc()
	{
        yield return new WaitForSeconds(delayTime);
        for (int i = 0; i < transform.childCount; i++) 
        {
            transform.GetChild(i).gameObject.SetActive(true);
        }
	}	
}
