using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using DG.Tweening;

[XLua.LuaCallCSharp]
public class ScrollViewContent : UIBehaviour
{
    [SerializeField] protected RectOffset m_Padding = new RectOffset();
    public RectOffset padding { get { return m_Padding; } set { SetProperty(ref m_Padding, value); } }

    [UnityEngine.Serialization.FormerlySerializedAs("m_Alignment")]
    [SerializeField]
    protected TextAnchor m_ChildAlignment = TextAnchor.UpperLeft;
    public TextAnchor childAlignment { get { return m_ChildAlignment; } set { SetProperty(ref m_ChildAlignment, value); } }

    public enum Corner { UpperLeft = 0, UpperRight = 1, LowerLeft = 2, LowerRight = 3 }
    public enum Axis { Horizontal = 0, Vertical = 1 }
    public enum Constraint { Flexible = 0, FixedColumnCount = 1, FixedRowCount = 2 }

    [SerializeField] protected Corner m_StartCorner = Corner.UpperLeft;
    public Corner startCorner { get { return m_StartCorner; } set { SetProperty(ref m_StartCorner, value); } }

    [SerializeField] protected Axis m_StartAxis = Axis.Horizontal;
    public Axis startAxis { get { return m_StartAxis; } set { SetProperty(ref m_StartAxis, value); } }

    [SerializeField] protected Vector2 m_CellSize = new Vector2(100, 100);
    public Vector2 cellSize { get { return m_CellSize; } set { SetProperty(ref m_CellSize, value); } }

    [SerializeField] protected Vector2 m_Spacing = Vector2.zero;
    public Vector2 spacing { get { return m_Spacing; } set { SetProperty(ref m_Spacing, value); } }

    [SerializeField] protected Constraint m_Constraint = Constraint.Flexible;
    public Constraint constraint { get { return m_Constraint; } set { SetProperty(ref m_Constraint, value); } }

    [SerializeField] protected int m_ConstraintCount = 2;
    public int constraintCount { get { return m_ConstraintCount; } set { SetProperty(ref m_ConstraintCount, Mathf.Max(1, value)); } }

    public RectTransform maskRectTransform;
    public GameObjectPool pool;
    bool willDistroy = false;
    static Vector2 hidePos = new Vector2(0, 1000);

    [SerializeField] protected int m_ChildCount = 0;
    public int DataCount {
        get {
            return m_ChildCount;
        }
        set {
            willDistroy = false;
            SetProperty(ref m_ChildCount, Mathf.Max(0, value));
            Refresh(true);
        }
    }

    public System.Action<GameObject, int> RefreshIconCallback;

    protected ScrollViewContent()
    { }

#if UNITY_EDITOR
    [ContextMenu("Refresh")]
    protected override void OnValidate()
    {
        base.OnValidate();
        Refresh(true);
    }
#endif

    protected override void Awake() {
        if (maskRectTransform == null) {
            maskRectTransform = rectTransform.parent as RectTransform;
        }
    }

    protected override void OnRectTransformDimensionsChange() {
        base.OnRectTransformDimensionsChange();
        Refresh();
    }

    [HideInInspector]
    public int cellsPerMainAxis = 1, actualCellCountX, actualCellCountY;

    int cornerX, cornerY;
    Vector2 startOffset;

    private void SetCellsAlongAxis() {
        if (!IsActive()) {
            return;
        }

        float width = rectTransform.rect.size.x;
        float height = rectTransform.rect.size.y;

        int cellCountX = 1;
        int cellCountY = 1;
        if (m_Constraint == Constraint.FixedColumnCount) {
            cellCountX = m_ConstraintCount;
            cellCountY = Mathf.CeilToInt(m_ChildCount / (float)cellCountX - 0.001f);
        } else if (m_Constraint == Constraint.FixedRowCount) {
            cellCountY = m_ConstraintCount;
            cellCountX = Mathf.CeilToInt(m_ChildCount / (float)cellCountY - 0.001f);
        } else {
            if (cellSize.x + spacing.x <= 0)
                cellCountX = int.MaxValue;
            else
                cellCountX = Mathf.Max(1, Mathf.FloorToInt((width - padding.horizontal + spacing.x + 0.001f) / (cellSize.x + spacing.x)));

            if (cellSize.y + spacing.y <= 0)
                cellCountY = int.MaxValue;
            else
                cellCountY = Mathf.Max(1, Mathf.FloorToInt((height - padding.vertical + spacing.y + 0.001f) / (cellSize.y + spacing.y)));
        }

        cornerX = (int)startCorner % 2;
        cornerY = (int)startCorner / 2;

        if (startAxis == Axis.Horizontal) {
            cellsPerMainAxis = cellCountX;
            actualCellCountX = Mathf.Clamp(cellCountX, 1, m_ChildCount);
            actualCellCountY = Mathf.CeilToInt(m_ChildCount / (float)cellsPerMainAxis); // Mathf.Clamp(cellCountY, 1, Mathf.CeilToInt(m_ChildCount / (float)cellsPerMainAxis));
        } else {
            cellsPerMainAxis = cellCountY;
            actualCellCountY = Mathf.Clamp(cellCountY, 1, m_ChildCount);
            actualCellCountX = Mathf.CeilToInt(m_ChildCount / (float)cellsPerMainAxis); //  Mathf.Clamp(cellCountX, 1, Mathf.CeilToInt(m_ChildCount / (float)cellsPerMainAxis));
        }

        Vector2 requiredSpace = new Vector2(
                actualCellCountX * cellSize.x + (actualCellCountX - 1) * spacing.x + padding.left + padding.right,
                actualCellCountY * cellSize.y + (actualCellCountY - 1) * spacing.y + padding.top + padding.bottom
                );
        startOffset = new Vector2(
                GetStartOffset(0, requiredSpace.x),
                GetStartOffset(1, requiredSpace.y)
                );

        if (startAxis == Axis.Horizontal) {
            rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, requiredSpace.y);
        } else {
            rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, requiredSpace.x);
        }

        Refresh();
    }

    bool IsVisible(Rect visibleRect, float x, float y) {
        if (x - cellSize[0] > visibleRect.xMax || x + cellSize[0]* 2 < visibleRect.x) {
            return false;
        }

        y = rectTransform.rect.height - y - cellSize[1];
        if (y - cellSize[0] > visibleRect.yMax || y + cellSize[1] * 2 < visibleRect.y) {
            return false;
        }

        return true;
    }

    static Vector2 CalculateRectTransformOffset(RectTransform root, RectTransform child) {
        Vector2 ret = new Vector2(0, 0);

        RectTransform rt = child;
        while (root && rt != root) {
            RectTransform parent = rt.parent as RectTransform;
            if (parent == null) {
                break;
            }

            ret.x += rt.localPosition.x - rt.rect.width * rt.pivot.x + parent.rect.width * parent.pivot.x;
            ret.y += rt.localPosition.y - rt.rect.height * rt.pivot.y + parent.rect.height * parent.pivot.y;

            rt = parent;
        }

        return ret;
    }

    /*
    static Rect CalcRectInParent(RectTransform root, RectTransform child) {
        Vector2 offset = CalculateRectTransformOffset(root, child);
        Rect rect = child.rect;
        rect.x = offset.x;
        rect.y = offset.y;
        return rect;
    }
    */

    static Rect CalcRectInChild(RectTransform root, RectTransform child) {
        Vector2 offset = CalculateRectTransformOffset(root, child);
        Rect rect = root.rect;
        rect.x = -offset.x;
        rect.y = -offset.y;
        return rect;
    }

    RectTransform[] objs = null;
    List<int> updateList = new List<int>();
    List<int> removeList = new List<int>();

    public GameObject GetItem(int i) {
        if (objs != null && i >= 0 && i < objs.Length && objs[i] != null) {
            return objs[i].gameObject;
        }
        return null;
    }

    bool _dirty = true;
    bool _rebuild = false;
    public void Refresh(bool rebuild = false) {
        _rebuild = _rebuild || rebuild;
        _dirty = true;
    }

    public void ItemRef() {
        Refresh(true);
    }

    protected override void OnEnable() {
        Refresh(false);
    }

    public static int update_max_item_count = 0;

    RectTransform popFromRemoveList() {
        if (removeList.Count > 0) {
            int idx = removeList[0];
            removeList.RemoveAt(0);
            RectTransform rt = objs[idx];
            objs[idx] = null;
            return rt;
        }
        return null;
    }

    private void Update() {
        if (willDistroy) {
            ReleaseObject();
            return;
        }

        if (_dirty) {
            _dirty = false;
            SetCellsAlongAxis();
            DoLayout();
        }

        var watch = new System.Diagnostics.Stopwatch();
        watch.Start();
        int updateCount = 0;
        int n = ((update_max_item_count > 0) ? update_max_item_count : cellsPerMainAxis);
        for (int j = 0; j < n * 1000; j++) {
            if (updateList.Count == 0) {
                break;
            }

            int i = updateList[0];
            updateList.RemoveAt(0);

            float x, y;
            CalcCellPosition(i, out x, out y);

            if (objs[i] == null) {
                if (removeList.Count > 0) {
                    // Debug.LogFormat("item {0} from removeQueue", i);
                    objs[i] = popFromRemoveList();
                } else {
                    // Debug.LogFormat("item {0} from pool", i);
                    objs[i] = pool.Get(transform).GetComponent<RectTransform>();
                }
            }

            SetupItem(i, x, y);

            updateCount++;

            if (watch.ElapsedMilliseconds >= 10) {
                break;
            }
        }

        watch.Stop();
    }

    void DoLayout() {
        if (!IsActive()) {
            return;
        }

        if (!Application.isPlaying || willDistroy) {
            return;
        }

        if (pool == null) {
            return;
        }

        if (m_ChildCount < 0) {
            m_ChildCount = 0;
        }

        if (objs == null) {
            objs = new RectTransform[m_ChildCount];
        } else if (objs.Length != m_ChildCount) {
            RectTransform[] newObjs = new RectTransform[m_ChildCount];
            for (int i = 0; i < objs.Length; i++) {
                if (i < newObjs.Length) {
                    newObjs[i] = objs[i];
                } else if (objs[i] != null) {
                    removeList.Remove(i);
                    pool.Release(objs[i].gameObject);
                }
            }
            objs = newObjs;
        }

        if (_rebuild) {
            updateList.Clear();
        }

        Rect visibleRect = CalcRectInChild(maskRectTransform, rectTransform);

        for (int i = 0; i < m_ChildCount; i++) {
            float x, y;
            CalcCellPosition(i, out x, out y);

            if (IsVisible(visibleRect, x, y)) {
                if (objs[i] == null) {
                    if (!updateList.Contains(i)) {
                        updateList.Add(i);
                    }
                } else if (_rebuild) {
                    if (!updateList.Contains(i)) {
                        updateList.Add(i);
                    }
                } else {
                    SetChildAlongAxis(objs[i], 0, x, cellSize[0]);
                    SetChildAlongAxis(objs[i], 1, y, cellSize[1]);
                }
                removeList.Remove(i);
            } else {
                updateList.Remove(i);
                if (objs[i] != null && !removeList.Contains(i)) {
                    removeList.Add(i);
                }
            }
        }

        _rebuild = false;

        while (removeList.Count > cellsPerMainAxis * 2) {
            pool.Release(popFromRemoveList().gameObject);
        }
    }

    void CalcCellPosition(int i, out float x, out float y) {
        if (cellsPerMainAxis == 0) {
            cellsPerMainAxis = 1;
        }

        int positionX;
        int positionY;
        if (startAxis == Axis.Horizontal) {
            positionX = i % cellsPerMainAxis;
            positionY = i / cellsPerMainAxis;
        } else {
            positionX = i / cellsPerMainAxis;
            positionY = i % cellsPerMainAxis;
        }

        if (cornerX == 1)
            positionX = actualCellCountX - 1 - positionX;
        if (cornerY == 1)
            positionY = actualCellCountY - 1 - positionY;


        x = startOffset.x + (cellSize[0] + spacing[0]) * positionX;
        y = startOffset.y + (cellSize[1] + spacing[1]) * positionY;
    }

    void SetupItem(int i, float x, float y) {
        SetChildAlongAxis(objs[i], 0, x, cellSize[0]);
        SetChildAlongAxis(objs[i], 1, y, cellSize[1]);

        if (RefreshIconCallback != null) {
            RefreshIconCallback(objs[i].gameObject, i);
        }

        objs[i].gameObject.SetActive(true);
        // objs[i].name = string.Format("item_{0}", i + 1);
        objs[i].name = "Scroll" + (i < 10 ? "0" + i : i.ToString());
    }

    public void WillDestroy() {
        willDistroy = true;
    }

    void ReleaseObject() {
        if (removeList.Count > 0) {
            pool.Release(popFromRemoveList().gameObject);
            return;
        }

        for (int i = 0; i < m_ChildCount; i++) {
            if (objs[i] != null) {
                pool.Release(objs[i].gameObject);
                objs[i] = null;
                break;
            }
        }
    }

    protected override void OnDestroy() {
        if (pool == null) {
            return;
        }

        for (int i = 0; i < objs.Length; i++) {
            if (objs[i] != null) {
                pool.Release(objs[i].gameObject);
                objs[i] = null;
            }
        }
    }

    public void ScrollMove(int idx, float tweenTime = 0) {
        if (idx < 0) idx = 0;
        if (idx >= m_ChildCount) idx = m_ChildCount - 1;

        float x, y;
        CalcCellPosition(idx, out x, out y);

        Vector2 targetPosition = rectTransform.anchoredPosition;

        if (startAxis == Axis.Horizontal) {
            targetPosition.y = y;
        } else {
            targetPosition.x = -x;
        }

        if (tweenTime > 0) {
            rectTransform.DOAnchorPos(targetPosition, tweenTime);
        } else {
            rectTransform.anchoredPosition = targetPosition;
        }
        Refresh(false);
    }

    protected void SetProperty<T>(ref T currentValue, T newValue) {
        currentValue = newValue;
        Refresh(false);
    }

    protected RectTransform _rectTransform;
    protected RectTransform rectTransform {
        get {
            if (_rectTransform == null) {
                _rectTransform = GetComponent<RectTransform>();
            }
            return _rectTransform;
        }
    }

    protected void SetChildAlongAxis(RectTransform rect, int axis, float pos) {
        if (rect == null)
            return;
        rect.SetInsetAndSizeFromParentEdge(axis == 0 ? RectTransform.Edge.Left : RectTransform.Edge.Top, pos, rect.sizeDelta[axis]);
    }

    protected void SetChildAlongAxis(RectTransform rect, int axis, float pos, float size) {
        if (rect == null)
            return;
        rect.SetInsetAndSizeFromParentEdge(axis == 0 ? RectTransform.Edge.Left : RectTransform.Edge.Top, pos, size);
    }

    protected float GetStartOffset(int axis, float requiredSpaceWithoutPadding) {
        float requiredSpace = requiredSpaceWithoutPadding + (axis == 0 ? padding.horizontal : padding.vertical);
        float availableSpace = rectTransform.rect.size[axis];
        float surplusSpace = availableSpace - requiredSpace;
        float alignmentOnAxis = GetAlignmentOnAxis(axis);
        return (axis == 0 ? padding.left : padding.top) + surplusSpace * alignmentOnAxis;
    }

    protected float GetAlignmentOnAxis(int axis) {
        if (axis == 0)
            return ((int)childAlignment % 3) * 0.5f;
        else
            return ((int)childAlignment / 3) * 0.5f;
    }

#if UNITY_EDITOR
    [ContextMenu("Init From UIMultiScroller")]
    public void CopyFromUIMultiScroller () {
        ScrollRect scrollRect = null;
        Transform parent = transform.parent;
        while (parent) {
            scrollRect = parent.gameObject.GetComponent<ScrollRect>();
            if (scrollRect != null) {
                break;
            }
            parent = parent.parent;
        }

        if (scrollRect == null) {
            Debug.LogFormat("ScrollRect not found");
            return;
        }

        UIMultiScroller scroller = scrollRect.gameObject.GetComponent<UIMultiScroller>();
        if (scroller != null) {
            cellSize = new Vector2(scroller.cellWidth, scroller.cellHeight);
            constraintCount = scroller.maxPerLine;

            if (scroller._movement == UIMultiScroller.Arrangement.Horizontal) {
                constraint = Constraint.FixedRowCount;
                startAxis = Axis.Vertical;
            } else {
                constraint = Constraint.FixedColumnCount;
                startAxis = Axis.Horizontal;
            }
            padding = new RectOffset((int)scroller.offset.x, (int)scroller.offset.y, 0, 0);

            if (pool == null) {
                pool = gameObject.GetComponent<GameObjectPool>();
                if (pool == null) {
                    pool = gameObject.AddComponent<GameObjectPool>();
                    pool.prefab = scroller.itemPrefab;
                    pool.count = 5;
                }
            }

            scroller.enabled = false;

            int n = scrollRect.onValueChanged.GetPersistentEventCount();
            for (int i = 0; i < n; i++) {
                if (scrollRect.onValueChanged.GetPersistentTarget(i) == scroller && scrollRect.onValueChanged.GetPersistentMethodName(i) == "OnValueChange") {
                    UnityEditor.Events.UnityEventTools.RegisterBoolPersistentListener(scrollRect.onValueChanged, i, Refresh, false);
                    break;
                }
            }
            // scrollRect.onValueChanged.RemoveListener(scroller.OnValueChange);
        } else {
            Debug.LogError("UIMultiScroller no found");
        }

        // gameObject.GetComponent<UnityEngine.UI.ScrollRect>().onValueChanged.AddListener(scroller.Refresh);
    }
#endif
}
