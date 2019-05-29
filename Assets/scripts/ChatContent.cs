using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ChatContent : MonoBehaviour {

	private ScrollRect _scrollRect;
	private VerticalLayoutGroup _verLayoutGroup;
	// private float startBottomValue;
	private List<ChatContentIndexCallback> _listItem;
	private List<ChatContentIndexCallback> _pool;
	private int totalCount;
	private int itemTypeStart;
	private int itemTypeEnd;
	private ChatStateType _chatStateType;
	private Vector3 startPostion;
	private Dictionary<int,float> itemHeightDic;
    private Transform itemParent;
	public int referencePixelsPerUnit = 1;
	public GameObject prefab;
    public delegate void OnRefreshItem(GameObject ga, int dataIndex);
    public OnRefreshItem onRefreshItem;
	public enum ChatStateType
	{
		initItem = 1,//初始化
		TopToBottom = 2,
		BotttomToTop = 3,
		empty = 4,
	}

	Vector2 SR_size = Vector2.zero;//SrollRect的尺寸  
    Vector3[] conners = new Vector3[4];//ScrollRect四角的世界坐标   
    // float viewHeight;//显示区域的一半
	void Awake ()
	{
		_scrollRect = transform.GetComponent<ScrollRect>();
		_verLayoutGroup = _scrollRect.content.GetComponent<VerticalLayoutGroup>();
		_listItem = new List<ChatContentIndexCallback>();
		_pool = new List<ChatContentIndexCallback>();
		itemHeightDic = new Dictionary<int, float>();
		// startBottomValue = _verLayoutGroup.padding.bottom;
		_scrollRect.onValueChanged.AddListener(OnValueChanged);
        itemParent = _scrollRect.content;
		//itemTypeStart = 0;
		//itemTypeEnd = 0;
	}
	// Use this for initialization
	void Start () {
		InitData();

        SetChatCount(totalCount);
        //WrapContent();
    }
	public void InitData ()
	{
		SR_size =transform.GetComponent<RectTransform>().rect.size;
        startPostion = transform.localPosition;
		//四角坐标  横着数  
        conners[0] = new Vector3(-SR_size.x / 2f, SR_size.y / 2f,0);  
        conners[1] = new Vector3(SR_size.x / 2f, SR_size.y / 2f,0);  
        conners[2] = new Vector3(-SR_size.x / 2f, -SR_size.y / 2f,0);  
        conners[3] = new Vector3(SR_size.x / 2f, -SR_size.y / 2f,0);  
        for (int i = 0; i < 4; i++)  
        {   
            Vector3 temp = transform.TransformPoint(conners[i]);  
            conners[i].x = temp.x;  
            conners[i].y = temp.y;  
        }  
		// viewHeight = SR_size.y/2;
	}
	/*private void WrapContent ()
	{
		Vector3[] conner_Local = new Vector3[4];
		for (int i = 0; i < 4; i++) {
			conner_Local [i] = transform.InverseTransformPoint (conners [i]);
			Debug.Log ("conner_Local[i]: " + conner_Local [i]);
		}
        Vector3 lastItemPos = _listItem.Count > 0 ? _listItem[_listItem.Count - 1].transform.localPosition : Vector3.zero;
        Debug.Log("lastItemPos.y <= conner_Local[0].y : " + lastItemPos.y + "conner_Local[0].y" + conner_Local[0].y);
        Debug.Log("itemTypeStart: " + itemTypeStart);
        if (lastItemPos.y <= conner_Local[0].y || _listItem.Count == 0)
        {
            ChatContentIndexCallback temp = CreateItem(itemTypeStart);
            temp.transform.SetAsFirstSibling();
            itemTypeStart--;
            _listItem.Add(temp);
        }
	}*/
	// Update is called once per frame
	void Update ()
	{
		//if (_listItem.Count > 0) {
		//GameObject obj = _listItem[]
		//Debug.Log(_scrollRect.content.sizeDelta.y);
		if (_chatStateType == ChatStateType.initItem) {
            if (itemTypeStart > 0)
            {     	
               
				Vector3[] conner_Local = new Vector3[4];
				for (int i = 0; i < 4; i++) {
                    conner_Local[i] = itemParent.InverseTransformPoint(conners[i]);
					//Debug.Log ("conner_Local[i]: " + conner_Local [i]);
				}
				//Vector3 center = (conner_Local [0] + conner_Local [3]) / 2;//计算此时中心点的坐标
				Vector3 lastItemPos = _listItem.Count > 0 ? _listItem [_listItem.Count - 1].transform.localPosition : Vector3.zero;			
                //Debug.Log("lastItemPos.y <= conner_Local[0].y : " + lastItemPos.y + "conner_Local[0].y" + conner_Local[0].y);
//Debug.Log("itemTypeStart: "+itemTypeStart);
                if (lastItemPos.y <= conner_Local[0].y || _listItem.Count == 0)
                {
					ChatContentIndexCallback temp = CreateItem(itemTypeStart);
                    temp.transform.SetAsFirstSibling();
                    itemTypeStart--;
                    _listItem.Add(temp);
				}
                else
                {
                    startPostion = _scrollRect.content.position;
                    _chatStateType = ChatStateType.empty;
                }
            }
            else {
                _chatStateType = ChatStateType.empty;
            }
		} else if (_chatStateType == ChatStateType.BotttomToTop) {
                //Debug.Log("itemTypeEnd: " + itemTypeEnd + "totalCount: " + totalCount);
			MoveBotttomToTop();
		} else if (_chatStateType == ChatStateType.TopToBottom) {
			//Debug.Log("itemTypeStart: "+itemTypeStart);
			MoveTopToBottom();
		}
		//startPostion = _scrollRect.content.anchoredPosition;
	}
	void OnValueChanged (Vector2 vec)
	{	
		//	return;
		if (vec != Vector2.zero) {
			Vector3 currentPos = _scrollRect.content.position;
			Vector3 temp = currentPos - startPostion;
			//Debug.Log ("temp: " + temp);
			//float offest = currentPos.y - startPostion.y;
			if ((_chatStateType == ChatStateType.empty || _chatStateType == ChatStateType.BotttomToTop) && temp.y < 0) {
				_chatStateType = ChatStateType.TopToBottom;
				//_scrollRect.content.pivot = new Vector2(0.5f,0);
			} else if ((_chatStateType == ChatStateType.empty || _chatStateType == ChatStateType.TopToBottom) && temp.y > 0) {
				_chatStateType = ChatStateType.BotttomToTop;
				//_scrollRect.content.pivot = new Vector2(0.5f,1);
			}
			startPostion = _scrollRect.content.position;
			//Debug.Log("currentPos: "+currentPos+"startPosition: "+startPostion+"offest: "+offest); 
			//Debug.Log ("_chatStateType: " + _chatStateType);
		}
		
	}



	public void SetChatCount (int count)
	{
        if (_verLayoutGroup == null) {
            totalCount = count;
            return;
        }

		_verLayoutGroup.padding.bottom = 0;
		Recycle();
		totalCount = count;
		itemTypeEnd = totalCount;
		itemTypeStart = itemTypeEnd;
		_chatStateType = ChatStateType.initItem;

		//_verLayoutGroup.padding.bottom = (int)_scrollRect.GetComponent<RectTransform>().sizeDelta.y;
	}
	//添加新的
	public void AddItem ()
	{
		/*Vector3 lastItemPos = _listItem.Count > 0 ? _listItem [0].transform.position : Vector3.zero;
		float itemY = _listItem.Count > 0 ? _listItem [0].GetComponent<RectTransform> ().sizeDelta.y / 2 : 0;
		float tempY = _scrollRect.GetComponent<RectTransform> ().sizeDelta.y / 2 + itemY;
		Debug.Log ("(lastItemPos - _scrollRect.transform.position).y: " + (lastItemPos - _scrollRect.transform.position).y + "tempY: " + tempY);
		if (itemTypeEnd == totalCount && ((lastItemPos - _scrollRect.transform.position).y >= -tempY || itemY == 0)) {//满屏
			itemTypeEnd++;
			ScrollIndexCallback item = CreateItem (itemTypeEnd);
			_listItem.Insert (0, item);
		}   */   
		totalCount += 1;
		if (itemTypeEnd == totalCount - 1) {
			MoveBotttomToTop();
		}
	}
	private void Recycle ()
	{
		for (int i = 0; i < _listItem.Count; i++) {
			_listItem[i].gameObject.SetActive(false);
			_pool.Add(_listItem[i]);
		}
		_listItem.Clear();
        _scrollRect.content.anchoredPosition = new Vector2(_scrollRect.content.anchoredPosition.x,-_scrollRect.GetComponent<RectTransform>().sizeDelta.y/2);
	}
	private void UpdateItem ()
	{
		
	}
	private ChatContentIndexCallback CreateItem (int index)
	{
		ChatContentIndexCallback obj;
		if (_pool.Count > 0) {
			obj = _pool[_pool.Count - 1];
			_pool.Remove(obj);
		}else{
			obj = Instantiate(prefab,_scrollRect.content.transform).AddComponent<ChatContentIndexCallback>();
			obj.transform.localPosition = Vector3.zero;
			//Debug.Log(obj.transform.position+" locaPos: "+obj.transform.localPosition);
		}
		obj.name = index.ToString();
        obj.chatContent = this;
        obj.index = index;
		obj.gameObject.SetActive(true);
		return obj;
	}
	//向上移动判断
	private void MoveBotttomToTop ()
	{
		if (itemTypeEnd < totalCount) {
            Vector3[] conner_Local = new Vector3[4];
            for (int i = 0; i < 4; i++)
            {
                conner_Local[i] = itemParent.InverseTransformPoint(conners[i]);
                //Debug.Log("conner_Local[i]: " + conner_Local[i]);
            }
			Vector3 lastItemPos = _listItem.Count > 1 ? _listItem [_listItem.Count - 2].transform.localPosition : Vector3.zero;
			//移除上边不在范围的
			if (lastItemPos.y > conner_Local[0].y) {
				if (_listItem.Count > 0) {
					ChatContentIndexCallback startItem = _listItem [_listItem.Count - 1];
					startItem.gameObject.SetActive (false);
					_listItem.Remove (startItem);
					_pool.Add (startItem);
					itemTypeStart++;
					//Debug.Log ("delete");
				}

			}
			//Debug.Log("BotttomToTop");
			//增加新的
			Vector3 endItemPos = _listItem.Count > 0 ? _listItem [0].transform.localPosition : Vector3.zero;
			//Debug.Log(endItemPos - _scrollRect.transform.position);
			//if (itemStartY2 <= itemEndTempY || _listItem.Count == 0) {
			if (endItemPos.y > conner_Local[3].y || _listItem.Count == 0) {
				//减少新的item的height
				//Debug.Log("_verLayoutGroup.padding.bottom: "+_verLayoutGroup.padding.bottom);
				itemTypeEnd++;
				//Debug.Log ("add"+itemTypeEnd);
				ChatContentIndexCallback temp = CreateItem (itemTypeEnd);
                float newItemHeight = itemHeightDic.ContainsKey(itemTypeEnd) ? itemHeightDic[itemTypeEnd] : 0;
                _verLayoutGroup.padding.bottom = _verLayoutGroup.padding.bottom - (int)newItemHeight > 0 ? _verLayoutGroup.padding.bottom - (int)newItemHeight : 0;//104;//Mathf.FloorToInt (_listItem [_listItem.Count - 1].GetComponent<RectTransform> ().sizeDelta.y);
				temp.transform.SetAsLastSibling ();
				//_listItem.Add (temp);
				_listItem.Insert (0, temp);
				//totalCount--;
			}
		}
	}
	private void MoveTopToBottom ()
	{
		if (itemTypeStart > 0) {
            Vector3[] conner_Local = new Vector3[4];
            for (int i = 0; i < 4; i++)
            {
                conner_Local[i] = itemParent.InverseTransformPoint(conners[i]);
                //Debug.Log("conner_Local[i]: " + conner_Local[i]);
            }
			//float itemY = _listItem.Count > 1 ? _listItem [1].rect.sizeDelta.y/2 : 0;
			Vector3 lastItemPos = _listItem.Count > 1 ? _listItem [1].transform.localPosition : Vector3.zero;
			//移除下边不在范围的
			//Debug.Log(lastItemPos - _scrollRect.transform.position);
            if (lastItemPos.y < conner_Local[3].y)
            {
				if (_listItem.Count > 0) {
					//_scrollRect.content.anchoredPosition = new Vector2(_scrollRect.content.anchoredPosition.x,-600);
					_verLayoutGroup.padding.bottom = _verLayoutGroup.padding.bottom + Mathf.FloorToInt (_listItem [0].GetComponent<RectTransform> ().sizeDelta.y);
					//移除要保存被移除的item的height
					//Debug.Log("_listItem [0]: "+_listItem [0].name);
					ChatContentIndexCallback lastItem = _listItem [0];
					lastItem.gameObject.SetActive (false);
					_listItem.Remove (lastItem);
					if (!itemHeightDic.ContainsKey (itemTypeEnd)) {
						itemHeightDic.Add(itemTypeEnd,lastItem.GetComponent<RectTransform>().sizeDelta.y);
					}else
						itemHeightDic[itemTypeEnd] = lastItem.GetComponent<RectTransform>().sizeDelta.y;
					//_scrollRect.content.anchoredPosition.y+_listItem [0].GetComponent<RectTransform> ().sizeDelta.y);
					_pool.Add(lastItem);
					itemTypeEnd --;
				}
			}
			//Debug.Log("TopToBottom");0
			//增加新的
		
			Vector3 StartItemPos = _listItem.Count > 0 ? _listItem [_listItem.Count - 1].transform.localPosition : Vector3.zero;
			// float itemStartY2 = Vector3.Distance (_scrollRect.transform.position, StartItemPos);
			if (_listItem.Count > 0) {
				//Debug.Log ("lastItemPos: " + StartItemPos + "_listItem [_listItem.Count - 1].transform.localPosition:" + _listItem [_listItem.Count - 1].transform.localPosition);
				//Debug.Log(_listItem [_listItem.Count - 1].name);
			}
			if (StartItemPos.y < conner_Local[0].y || _listItem.Count == 0) {
				ChatContentIndexCallback temp = CreateItem (itemTypeStart);
				temp.transform.SetAsFirstSibling ();
				itemTypeStart--;
				_listItem.Add (temp);
				//totalCount--;
			} else {
				//_chatStateType = ChatStateType.empty;
			}			
		}
	}

}
