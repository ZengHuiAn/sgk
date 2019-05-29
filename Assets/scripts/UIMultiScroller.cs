using UnityEngine;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using DG.Tweening;

public class UIMultiScroller : MonoBehaviour, IEndDragHandler
{
    public enum Arrangement { Horizontal, Vertical, }
    public Arrangement _movement = Arrangement.Horizontal;
    //单行或单列的Item数量
    [Range(1, 20)]
    public int maxPerLine = 5;
    //Item之间的距离
    [Range(0, 20)]
    private int cellPadiding = 0;
    //Item的宽高
    public static float frequencies = 400;
    private int RefMax = 0;
    public int cellWidth = 500;
    public int cellHeight = 100;
    public Vector2 offset = Vector2.zero;
    public bool test = false;
    public bool inertia = true;
    public bool _Tween = false;
    public enum _type { True, False, }
    public _type Type = _type.True;
    //默认加载的行数，一般比可显示行数大2~3行
    [Range(0, 20)]
    private int viewCount = 6;
    public GameObject itemPrefab;
    public RectTransform _content;
    public delegate void SystemAction_Go_Int(GameObject go, int state);
    public SystemAction_Go_Int RefreshIconCallback;
    private int _index = -1;
    private List<UIMultiScrollIndex> _itemList = new List<UIMultiScrollIndex>();
    private int _dataCount = 0;
    private bool isResetPosition = true;
    private List<UIMultiScrollIndex> TempList = new List<UIMultiScrollIndex>();
    private Stack<UIMultiScrollIndex> _unUsedQueue = new Stack<UIMultiScrollIndex>();  //将未显示出来的Item存入未使用队列里面，等待需要使用的时候直接取出
                                                                                       // private int maxViewCount;

    public int itemsPreUpdate = 20;

    private GameObject lastItemPrefab;
    void Start() {
        GetComponent<ScrollRect>().inertia = inertia;
        if (RefreshIconCallback == null) {
            RefreshIconCallback = func;
        }

        if (_movement == Arrangement.Vertical) {
            viewCount = Mathf.FloorToInt(this.GetComponent<RectTransform>().rect.height / cellHeight) + 2;
        } else {
            viewCount = Mathf.FloorToInt(this.GetComponent<RectTransform>().rect.width / cellWidth) + 2;
        }
        if (test) {
            DataCount = 30;
        } else {
            DataCount = _dataCount;
        }
        OnValueChange(Vector2.zero);
        RefMax = _itemList.Count;
        //continue.Start();
        //StartCoroutine(ShowItems());  
        //maxViewCount = maxPerLine * viewCount;
        //ShowItems();
    }
    public void OnEndDrag(PointerEventData data) {
        //Debug.Log("Stopped dragging " + this.name + "!");
        if (!inertia) {
            //print(_itemList [_itemList.Count-1].gameObject.name);
            //print (_content.transform.localPosition.x);
            int idx = 0;
            if (_movement == Arrangement.Vertical) {
                if (_content.transform.localPosition.y > 0) {
                    idx = Mathf.CeilToInt(_content.transform.localPosition.y / cellHeight);
                }
            } else {
                if (_content.transform.localPosition.x < 0) {
                    idx = Mathf.CeilToInt(Mathf.Abs(_content.transform.localPosition.x) / cellWidth);
                }
            }
            //print (idx);
            ScrollMove(idx - 1);
            //ScrollMove (_itemList[_itemList.Count-1].Index);
        }
    }
    void func(GameObject Obj, int index) { }

    /*
    void ShowItems ()
    {
        for (int i = 0; i < DataCount; i++) {
            if (i < maxViewCount) {
                //yield return new WaitForSeconds(0.1f);                
                AddItem(i);
                Debug.Log("item： "+ i);
            }
        }
        //yield return new WaitForSeconds(0.1f);
    }
     */

    public void OnValueChange(Vector2 pos) {
        int index = GetPosIndex();
        //if (_index != index && index >= -1 && index < DataCount-(viewCount -2))
        if (_index != index && _itemList != null) {
            _index = index;
            for (int i = _itemList.Count; i > 0; i--) {
                UIMultiScrollIndex item = _itemList[i - 1];
                if (item.Index < index * maxPerLine || (item.Index >= (index + viewCount) * maxPerLine)) {
                    //GameObject.Destroy(item.gameObject);
                    item.gameObject.SetActive(false);
                    item.transform.localPosition = new Vector3(-cellWidth, cellHeight, 0);
                    _itemList.Remove(item);
                    _unUsedQueue.Push(item);
                }
            }
            for (int i = _index * maxPerLine; i < (_index + viewCount) * maxPerLine; i++) {
                if (i < 0) continue;
                if (i > _dataCount - 1) continue;
                bool isOk = false;
                foreach (UIMultiScrollIndex item in _itemList) {
                    if (item.Index == i) isOk = true;
                }
                if (isOk) continue;
                CreateItem(i);
            }
        }
    }
    public bool DisableMoveTween = true;
    public void ScrollMove(int idx) {
        if (_movement == Arrangement.Vertical) {
            float _height = cellHeight * (idx / maxPerLine);
            float _heightOff = Mathf.Max((_content.sizeDelta.y - this.GetComponent<RectTransform>().rect.height), 0);
            if (_height > _heightOff) {
                _height = _heightOff;
            }
            if (DisableMoveTween) {
                _content.transform.localPosition = new Vector3(0, _height, 0);
            } else {
                DOTween.To(() => _content.offsetMax, x => _content.offsetMax = x, new Vector2(0, _height), 0.615f);
            }

        } else {
            var _idx = idx;
            if (_idx < 0) {
                _idx = 0;
            }
            float _width = cellWidth * _idx;
            var _size = Mathf.Max((_content.sizeDelta.x - this.GetComponent<RectTransform>().rect.width), 0);
            if (_width > _size) {
                _width = _size;
            }
            _content.transform.localPosition = new Vector3(-_width, 0, 0);
        }
        OnValueChange(Vector2.zero);
    }
    /// <summary>
    /// 提供给外部的方法，添加指定位置的Item
    /// </summary>
    public void AddItem(int index) {
        if (index > _dataCount) {
            Debug.LogError("添加错误:" + index);
            return;
        }
        AddItemIntoPanel(index);
        DataCount += 1;
    }

    /// <summary>
    /// 提供给外部的方法，删除指定位置的Item
    /// </summary>
    public void DelItem(int index) {
        if (index < 0 || index > _dataCount - 1) {
            Debug.LogError("删除错误:" + index);
            return;
        }
        DelItemFromPanel(index);
        DataCount -= 1;
    }

    private void AddItemIntoPanel(int index) {
        for (int i = 0; i < _itemList.Count; i++) {
            UIMultiScrollIndex item = _itemList[i];
            if (item.Index >= index) item.Index += 1;
        }
        CreateItem(index);
    }

    public GameObject GetItem(int index) {
        for (int i = _itemList.Count; i > 0; i--) {
            UIMultiScrollIndex item = _itemList[i - 1];
            if (item.Index == index) {
                return item.gameObject;
            }
        }
        return null;
    }

    private void DelItemFromPanel(int index) {
        int maxIndex = -1;
        int minIndex = int.MaxValue;
        for (int i = _itemList.Count; i > 0; i--) {
            UIMultiScrollIndex item = _itemList[i - 1];
            if (item.Index == index) {
                GameObject.Destroy(item.gameObject);
                _itemList.Remove(item);
            }
            if (item.Index > maxIndex) {
                maxIndex = item.Index;
            }
            if (item.Index < minIndex) {
                minIndex = item.Index;
            }
            if (item.Index > index) {
                item.Index -= 1;
            }
        }
        if (maxIndex < DataCount - 1) {
            CreateItem(maxIndex);
        }
    }

    private void CreateItem(int index) {
        if (lastItemPrefab != itemPrefab) {
            while (_unUsedQueue.Count > 0) {
                UIMultiScrollIndex idx = _unUsedQueue.Pop();
                Destroy(idx.gameObject);
            }
        }

        lastItemPrefab = itemPrefab;

        UIMultiScrollIndex itemBase;
        if (_unUsedQueue.Count > 0) {
            itemBase = _unUsedQueue.Pop();
        } else {
            itemBase = UIMultiScrollIndex.Get(AddChild(_content, itemPrefab));
        }
        if (_Tween) {
            itemBase.Movement = _movement;
            if (_movement == Arrangement.Vertical) {
                int x = cellWidth * maxPerLine;
                if (Type == _type.False) {
                    x = -x;
                }
                itemBase.IstweenPosition = new Vector2(x, cellHeight);
            } else {
                int y = cellHeight * maxPerLine;
                if (Type == _type.False) {
                    y = -y;
                }
                itemBase.IstweenPosition = new Vector2(cellWidth, y);
            }
        }
        if (test) {
            itemBase.gameObject.gameObject.SetActive(true);
        } else {
            itemBase.gameObject.SetActive(false);
            TempList.Add(itemBase);
            //RefreshIconCallback (itemBase.gameObject, index);
        }
        //itemBase.gameObject.SetActive(true);
        itemBase.Scroller = this;
        itemBase.Index = index;
        _itemList.Add(itemBase);
    }

    private int GetPosIndex() {
        switch (_movement) {
            case Arrangement.Horizontal:
                if (-1 < _content.anchoredPosition.x && _content.anchoredPosition.x < 1) {
                    return 0;
                } else {
                    return Mathf.FloorToInt(_content.anchoredPosition.x / -(cellWidth + cellPadiding));
                }
            case Arrangement.Vertical:
                if (-1 < _content.anchoredPosition.y && _content.anchoredPosition.y < 1) {
                    return 0;
                } else {
                    return Mathf.FloorToInt(_content.anchoredPosition.y / (cellHeight + cellPadiding));
                }
        }
        return 0;
    }

    public Vector3 GetPosition(int i) {
        switch (_movement) {
            case Arrangement.Horizontal:
                return new Vector3(cellWidth * (i / maxPerLine) + offset.x, -(cellHeight + cellPadiding) * (i % maxPerLine) + offset.y, 0f);
            case Arrangement.Vertical:
                return new Vector3(cellWidth * (i % maxPerLine) + offset.x, -(cellHeight + cellPadiding) * (i / maxPerLine) + offset.y, 0f);
        }
        return Vector3.zero;
    }

    public bool IsTween {
        get { return _Tween; }
        set {
            _Tween = value;
        }
    }
    public int DataCount {
        get { return _dataCount; }
        set {
            ItemRef(value);
        }
    }
    void SetDataCount(int value) {
        if (_itemList == null) {
            _dataCount = value;
            return;
        }
        if (isResetPosition) {
            _content.transform.localPosition = Vector3.zero;
        }
        for (int i = 0; i < _content.childCount; ++i) {
            _content.GetChild(i).gameObject.SetActive(false);
        }
        for (int i = 0; i < _itemList.Count; i++) {
            //GameObject.Destroy (_itemList[i].gameObject);
            _itemList[i].gameObject.SetActive(false);
            _unUsedQueue.Push(_itemList[i]);
        }
        _itemList.Clear();
        _dataCount = value;
        TempList.Clear();
        UpdateTotalWidth();
        _index = -1;
        OnValueChange(Vector2.zero);
        RefMax = _itemList.Count;
        _Tween = false;
    }
    public void IsReset(bool value) {
        isResetPosition = value;
    }

    public void ItemRef(int value = -1) {

        if (value > 0) {
            if (_dataCount == 0) {
                SetDataCount(value);
            } else {
                //Debug.LogError (_itemList.Count);
                // int tempCount = _dataCount;
                _dataCount = value;
                TempList.Clear();
                UpdateTotalWidth();
                for (int i = _itemList.Count; i > 0; i--) {
                    UIMultiScrollIndex item = _itemList[i - 1];
                    // if (item.Index < _index * maxPerLine || (item.Index >= (_index + viewCount) * maxPerLine))
                    //{
                    //GameObject.Destroy(item.gameObject);
                    //if (i > _dataCount)
                    //{

                    //}
                    item.gameObject.SetActive(false);
                    item.transform.localPosition = new Vector3(-cellWidth, cellHeight, 0);
                    _itemList.Remove(item);
                    _unUsedQueue.Push(item);
                    // }
                }
                for (int i = _index * maxPerLine; i < (_index + viewCount) * maxPerLine; i++) {
                    if (i < 0) continue;
                    if (i > _dataCount - 1) continue;
                    CreateItem(i);
                    _itemList[_itemList.Count - 1].transform.localPosition = GetPosition(_itemList[_itemList.Count - 1].Index);
                }

                //OnValueChange(Vector2.zero);
                //    if (tempCount > value)
                //    {
                //        for (int i = 0; i < _itemList.Count; i++)
                //        {
                //            //Debug.LogError (_itemList [i].Index + " " + _dataCount);
                //            if (_itemList[i].Index < value)
                //            {
                //                _itemList[i].transform.localPosition = GetPosition(_itemList[i].Index);
                //                RefreshIconCallback(_itemList[i].gameObject, _itemList[i].Index);
                //            }
                //            else
                //            {
                //                _itemList[i].gameObject.SetActive(false);
                //                Debug.Log(i + "_itemList[i]: " + _itemList[i].Index);
                //                _unUsedQueue.Push(_itemList[i]);
                //                _itemList.Remove(_itemList[i]);
                //                i--;
                //                //DelItem(_itemList[i].Index);
                //                //_itemList [i].gameObject.SetActive (false);
                //                //_unUsedQueue.Enqueue (_itemList [i]);
                //                //_itemList.Remove (_itemList [i]);
                //            }
                //        }
                //    }
                //    else
                //    {
                //        //for (int i = 0; i < _itemList.Count; i++)
                //        //{
                //        //    RefreshIconCallback(_itemList[i].gameObject, _itemList[i].Index);
                //        //}
                //        for (int i = _itemList.Count; i > 0; i--)
                //        {
                //            UIMultiScrollIndex item = _itemList[i - 1];
                //           // if (item.Index < _index * maxPerLine || (item.Index >= (_index + viewCount) * maxPerLine))
                //            //{
                //                //GameObject.Destroy(item.gameObject);
                //                item.gameObject.SetActive(false);
                //                _itemList.Remove(item);
                //                _unUsedQueue.Push(item);
                //           // }
                //        }
                //        for (int i = _index * maxPerLine; i < (_index + viewCount) * maxPerLine; i++)
                //        {
                //            if (i < 0) continue;
                //            if (i > _dataCount - 1) continue;                       
                //            CreateItem(i);
                //        }
                //    }
            }
        } else if (value == -1) {
            for (int i = 0; i < _itemList.Count; i++) {
                //_itemList [i].gameObject.SetActive (false);
                //TempList.Add (_itemList[i]);
                RefreshIconCallback(_itemList[i].gameObject, _itemList[i].Index);
            }
        } else {
            SetDataCount(value);
        }

    }
    void Update() {
        for (int j = 0; j < itemsPreUpdate; j++) {
            //Debug.LogError (RefMax+" "+frequencies+" "+TempList.Count+" "+ _itemList.Count);
            if (RefMax > 0) {
                for (int i = 0; i < Mathf.CeilToInt(RefMax / frequencies); i++) {
                    if (TempList.Count > 0) {
                        RefreshIconCallback(TempList[0].gameObject, TempList[0].Index);
                        TempList[0].gameObject.transform.localPosition = GetPosition(TempList[0].Index);
                        TempList.RemoveAt(0);
                    } else {
                        break;
                    }
                }
            }
        }
    }
    private void UpdateTotalWidth() {
        int lineCount = Mathf.CeilToInt((float)_dataCount / maxPerLine);
        switch (_movement) {
            case Arrangement.Horizontal:
                _content.sizeDelta = new Vector2(cellWidth * lineCount + cellPadiding * (lineCount - 1) + offset.x, _content.sizeDelta.y);
                break;
            case Arrangement.Vertical:
                _content.sizeDelta = new Vector2(_content.sizeDelta.x, cellHeight * lineCount + cellPadiding * (lineCount - 1) - offset.y);
                break;
        }
    }
    private GameObject AddChild(Transform parent, GameObject prefab) {
        GameObject go = GameObject.Instantiate(prefab) as GameObject;

        if (go != null && parent != null) {
            Transform t = go.transform;
            t.SetParent(parent, false);
            go.layer = parent.gameObject.layer;
        }
        return go;
    }

    private void OnDestroy() {
        RefreshIconCallback = null;
    }

#if UNITY_EDITOR
    [ContextMenu("Change To ScrollViewContent")]
    public void ChangeToScrollViewContent() {
        ScrollRect scrollRect = GetComponent<ScrollRect>();
        if (scrollRect == null || scrollRect.content == null) {
            Debug.LogFormat("scrollRect/content not found");
            return;
        }

        ScrollViewContent scrollViewContent = scrollRect.content.gameObject.GetComponent<ScrollViewContent>();
        if (scrollViewContent == null) {
            scrollViewContent = scrollRect.content.gameObject.AddComponent<ScrollViewContent>();
        }
        scrollViewContent.CopyFromUIMultiScroller();
    }
#endif
}
