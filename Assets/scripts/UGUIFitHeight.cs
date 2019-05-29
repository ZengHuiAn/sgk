using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(RectTransform))]
public class UGUIFitHeight : MonoBehaviour {
    public float baseHeight = 0.0f;
    public RectTransform target;
    public enum Arrangement { Horizontal, Vertical, }
    public Arrangement _movement = Arrangement.Vertical;

     RectTransform rt;

	// Use this for initialization
	void Start () {
        rt = GetComponent<RectTransform>();
	}
	
	// Update is called once per frame
	void Update () {
        if (target != null)
        {
            if (_movement == Arrangement.Vertical)
            {
                rt.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, baseHeight + target.rect.height);
            }
            else
            {
                rt.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, baseHeight + target.rect.width);
            }
        }

        
    }

#if UNITY_EDITOR
    [ContextMenu("Save")]
    public void SaveValue() {
        if (target != null) {
            rt = GetComponent<RectTransform>();
            if (_movement == Arrangement.Vertical)
            {
                baseHeight = rt.rect.height - target.rect.height;
            }
            else
            {
                baseHeight = rt.rect.width - target.rect.width;
            }
            
        }
    }
#endif
}
