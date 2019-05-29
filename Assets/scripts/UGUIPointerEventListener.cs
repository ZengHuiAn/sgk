using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;

public class UGUIPointerEventListener : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerExitHandler, IDragHandler, IEndDragHandler
{
	public delegate void VectorDelegate(GameObject go, Vector2 pos);
    public delegate void VectorDelegate2(GameObject go, Vector2 delta, Vector2 pos);
    public VectorDelegate onPointerDown;
	public VectorDelegate onPointerUp;
	public VectorDelegate onPointerExit;
    public VectorDelegate onDrag;
    public VectorDelegate2 onDrag2;
    public VectorDelegate2 onEndDrag;
    private float _pressTime = 0;
    public float pressTime = 0.2f;
    public bool isLongPress = false;
    private bool isPressing = false;
    // private bool startPress = false;

    //按下
    public void OnPointerDown(PointerEventData eventData) {
        isPressing = true;
        if (onPointerDown != null) {
            if (isLongPress)
            {
                StartCoroutine(longPress(eventData));
            }
            else
            {
                onPointerDown(eventData.pointerDrag, eventData.position);
            }
		}
	}

	//抬起
	public void OnPointerUp(PointerEventData eventData) {
        _pressTime = 0;
        isPressing = false;
        if (onPointerUp != null) {
			onPointerUp(eventData.pointerDrag, eventData.position);
		}
	}

	//离开
	public void OnPointerExit(PointerEventData eventData) {
		if (onPointerExit != null) {
			onPointerExit(eventData.pointerDrag, eventData.position);
		}
	}

    public void OnDrag(PointerEventData eventData)
    {
        if (onDrag != null)
        {
            onDrag(eventData.pointerDrag, eventData.delta);
        }
        if (onDrag2 != null)
        {
            onDrag2(eventData.pointerDrag, eventData.delta, eventData.position);
        }
    }

    public void OnEndDrag(PointerEventData eventData)
    {
        if (onEndDrag != null)
        {
            onEndDrag(eventData.pointerDrag, eventData.delta, eventData.position);
        }
    }

    private IEnumerator longPress(PointerEventData eventData)
    {
        while (true)
        {
            if (!isPressing)
            {
                break;
            }
            _pressTime = _pressTime + Time.deltaTime;
            if (_pressTime >= pressTime)
            {
                onPointerDown(eventData.pointerDrag, eventData.position);
                break;
            }
            yield return null;
        }
    }


    public static UGUIPointerEventListener Get(GameObject obj) {
        UGUIPointerEventListener del = obj.GetComponent<UGUIPointerEventListener>();
		if (del == null) {
			del = obj.AddComponent<UGUIPointerEventListener>();
		}
		return del;
	}

    private void OnDestroy() {
        onPointerDown = null;
        onPointerUp = null;
        onPointerExit = null;
        onDrag = null;
        onDrag2 = null;
        onEndDrag = null;
    }
}
