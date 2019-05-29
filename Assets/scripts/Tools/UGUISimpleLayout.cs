using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(RectTransform))]
public class UGUISimpleLayout : MonoBehaviour {

    public enum Direction
    {
        TOP_LEFT,
        TOP_RIGHT,
        BOTTOM_LEFT,
        BOTTOM_RIGHT,
    }

    public Direction direction;

    public Vector2 spacing = Vector2.zero;

    public Vector2 offset = Vector2.zero;
    public Vector2 cellSize = new Vector2(100, 100);

    public int countPerRow = 1;

    void Start () {
        Layout();
	}

    Vector2 CalcPosition(int idx) {
        int row = idx / countPerRow;
        int col = idx % countPerRow;

        Vector2 pos = new Vector2((col + 0.5f) * cellSize.x + (spacing.x * col),  ((row + 0.5f) * cellSize.y + (spacing.y * row)));

        switch (direction) {
            case Direction.TOP_LEFT:
                pos.x = offset.x + pos.x;
                pos.y = offset.y - pos.y;
                break;
            case Direction.TOP_RIGHT:
                pos.x = offset.x - pos.x;
                pos.y = offset.y - pos.y;
                break;
            case Direction.BOTTOM_LEFT:
                pos.x = offset.x + pos.x;
                pos.y = offset.y + pos.y;
                break;
            case Direction.BOTTOM_RIGHT:
                pos.x = offset.x - pos.x;
                pos.y = offset.y + pos.y;
                break;
        }
        return pos;
    }

    [ContextMenu("Layout")]
    public void Layout() {
        RectTransform rt = GetComponent<RectTransform>();

        countPerRow = (int)(rt.rect.width / (cellSize.x + spacing.x));
        if (countPerRow < 1) {
            countPerRow = 1;
        }

        int n = rt.childCount;
        int j = 0;
        for (int i = 0; i < n; i ++) {
            RectTransform childRT = rt.GetChild(i) as RectTransform;
            if (childRT.gameObject.activeSelf) {
                UnityEngine.UI.LayoutElement el = childRT.GetComponent<UnityEngine.UI.LayoutElement>();
                if (el != null && el.ignoreLayout) continue;

                Vector2 pos = CalcPosition(j);
                childRT.anchoredPosition = pos;
                j++;
            }
        }
    }
}
