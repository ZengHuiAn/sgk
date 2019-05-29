using UnityEngine;
using System.Collections;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using DG.Tweening;

public class newScrollText : MonoBehaviour, IBeginDragHandler, IEndDragHandler
{
    ScrollRect rect;
    //是否拖拽结束
    // bool isDrag = false;
    public float height = 44;
    public float duration = 0.1f;
	public delegate void SystemAction_Go_Int(int index);
	public SystemAction_Go_Int RefreshCallback;
    // Use this for initialization
    void Start()
    {
        rect = transform.GetComponent<ScrollRect>();
		if (RefreshCallback == null) {
			RefreshCallback = func;
		}
    }
	
    // Update is called once per frame
    void Update ()
	{
		
    }
	void func(int index) { }
    /// <summary>
    /// 拖动开始
    /// </summary>
    /// <param name="eventData"></param>
    public void OnBeginDrag(PointerEventData eventData)
    {
        // isDrag = true;
    }

    /// <summary>
    /// 拖拽结束
    /// </summary>
    /// <param name="eventData"></param>
    public void OnEndDrag(PointerEventData eventData)
    {
        // isDrag = false;    
		//Invoke ("InvokeResetPosition", 0.25f);
		InvokeResetPosition();
		
    }
	public void MovePosition(int index){
		rect.content.transform.DOLocalMoveY (index * height, duration);
	}
    void InvokeResetPosition ()
	{
		float temp = rect.content.anchoredPosition.y / height;
		int index = Mathf.FloorToInt (temp);
		if ((temp - index) >= 0.5f) {
			index = index + 1;
		}
		if (index < 0) {
			index = 0;
		}
		RefreshCallback (index);
		if (rect.content.anchoredPosition.y < (rect.content.sizeDelta.y - height) && rect.content.anchoredPosition.y > 0) {
			float posY = index * height;		
			rect.content.transform.DOLocalMoveY (posY, duration).SetDelay (0.25f);
		}
	}
}