using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class UGUIScrollRectEventListener : MonoBehaviour, IDragHandler, IEndDragHandler {
    public delegate void ScrollDelegate(GameObject go, Vector2 pos, Vector2 delta);
    public ScrollDelegate onDrag;
    public ScrollDelegate onEndDrag;

    public bool useBaseOnDrag = true;
    public bool useBaseOnEndDrag = true;

    private ScrollRect m_scrollRect;

    private void Awake() {
        m_scrollRect = GetComponentInChildren<ScrollRect>();
    }

    public void OnDrag(PointerEventData eventData) {
        if (useBaseOnDrag && m_scrollRect) {
            m_scrollRect.OnDrag(eventData);
        }
        if (onDrag != null) {
            onDrag(eventData.pointerDrag, eventData.position, eventData.delta);
        }
    }
    public void OnEndDrag(PointerEventData eventData) {
        if (useBaseOnEndDrag && m_scrollRect) {
            m_scrollRect.OnEndDrag(eventData);
        }
        if (onEndDrag != null) {
            onEndDrag(eventData.pointerDrag, eventData.position, eventData.delta);
        }
    }

    public static UGUIScrollRectEventListener Get(GameObject obj) {
        UGUIScrollRectEventListener del = obj.GetComponent<UGUIScrollRectEventListener>();
        if (del == null) {
            del = obj.AddComponent<UGUIScrollRectEventListener>();
        }
        return del;
    }

    private void OnDestroy() {
        onDrag = null;
        onEndDrag = null;
    }
}