using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ScrollViewItemBackground : MonoBehaviour {
    public ScrollRect scrollRect;

    RectTransform rectTransform;
    private void Awake() {
        rectTransform = GetComponent<RectTransform>();
    }

    // Use this for initialization
    void Start () {
        
        valueChange(Vector2.zero);
    }

    private void OnEnable() {
        if (scrollRect != null) {
            scrollRect.onValueChanged.AddListener(valueChange);
        }
    }

    private void OnDisable() {
        if (scrollRect != null) {
            scrollRect.onValueChanged.RemoveListener(valueChange);
        }
    }

    // Update is called once per frame
    void valueChange(Vector2 vec) {
        if (scrollRect == null || scrollRect.viewport == null ) {
            return;
        }

        Vector3 pos = scrollRect.viewport.InverseTransformPoint(rectTransform.TransformPoint(Vector3.zero));

        float viewPortHeight = scrollRect.viewport.rect.height;
        if (viewPortHeight < 1) {
            return;
        }

        RectTransform viewParent = (RectTransform)rectTransform.parent;
        if (viewParent == null) {
            return;
        }

        float percent = (viewPortHeight * scrollRect.viewport.pivot.y + pos.y) / viewPortHeight;
        float diff = rectTransform.rect.height - viewParent.rect.height;
        rectTransform.anchoredPosition = new Vector2(0, rectTransform.rect.height * (rectTransform.pivot.y - 0.5f) + (0.5f - percent) * diff);
    }
}
