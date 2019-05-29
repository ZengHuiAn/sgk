using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class GuideNodeMask : MonoBehaviour, IPointerClickHandler {
    public int ClickCount = 3;
    private int m_clickCount = 0;

    public void OnPointerClick(PointerEventData eventData) {
        m_clickCount += 1;
    }

    void Update() {
        if (Input.GetKeyDown(KeyCode.Escape)) {
            m_clickCount += 1;
            if (m_clickCount >= ClickCount) {
                GameObject.Destroy(gameObject);
            }
        }
    }

}
