using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(ScrollRect))]
public class UGUIScrollViewArrow : MonoBehaviour {
    public Image up;
    public Image down;
    public float space = 10;
    ScrollRect scrollRect;
    // Use this for initialization
    private void OnEnable() {
        if (scrollRect == null) {
            scrollRect = GetComponent<ScrollRect>();
        }
        scrollRect.onValueChanged.AddListener(onValueChanged);
        updateArrow();
    }

    private void OnDisable() {
        scrollRect.onValueChanged.RemoveListener(onValueChanged);
    }

    void onValueChanged(Vector2 vec) {
        updateArrow();
    }

    void OnTransformChildrenChanged() {
        updateArrow();
    }

    void updateArrow() {
        float viewport_height = scrollRect.viewport.rect.height;
        float content_height = scrollRect.content.rect.height;

        float upPos = scrollRect.content.anchoredPosition.y + content_height * (1 - scrollRect.content.pivot.y);
        float downPos = upPos - content_height;

        up.enabled = (upPos > space);
        down.enabled = downPos < -viewport_height-space;
    }
}
