using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using Spine.Unity;

[XLua.LuaCallCSharp]
public class FormationSlotItem : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler {
	public SkeletonGraphic spine;
	public RectTransform rt;
	public long key;
	public bool isLocked = false;

    public static string animationName = "idle1";
	
	bool _dragOnSurfaces = false;
	public bool dragOnSurfaces {
		get { return _dragOnSurfaces; }
	}

	void Start () {
		rt = GetComponent<RectTransform>();
	}

	public void UpdateSkeleton(string skeletonName) {
		if (!string.IsNullOrEmpty(skeletonName)) {
			SGK.ResourcesManager.LoadAsync(this, string.Format("roles_small/{0}/{0}_SkeletonData.asset", skeletonName), (o)=> {
				if (o != null) {
					spine.gameObject.SetActive(true);
                    if (o != spine.skeletonDataAsset) {
                        spine.skeletonDataAsset = o as SkeletonDataAsset;
                        spine.Initialize(true);
                        spine.AnimationState.SetAnimation(0, animationName, true);
                    }
				} else {
					spine.gameObject.SetActive(false);
				}
			});
		} else {
			spine.gameObject.SetActive(false);
		}
	}

	Vector2 beginDragPosition;
	Vector2 beginDragAnchorPosition;
	public void OnBeginDrag(PointerEventData eventData)
	{
		if (isLocked) {
			return;
		}

		beginDragPosition = eventData.position;
		RectTransform rt =  GetComponent<RectTransform>();
		beginDragAnchorPosition = rt.anchoredPosition;
		_dragOnSurfaces = true;
		rt.SetAsLastSibling();
	}

	public void OnDrag(PointerEventData eventData)
	{
		if (isLocked) {
			return;
		}

		float x = eventData.position.x - beginDragPosition.x;

#if UNITY_EDITOR
		GetComponent<RectTransform>().anchoredPosition = beginDragAnchorPosition + new Vector2(x * 1.2f, 0);
#else
		GetComponent<RectTransform>().anchoredPosition = beginDragAnchorPosition + new Vector2(x, 0);
#endif
	}

/*
	private void SetDraggedPosition(PointerEventData data)
	{
		if (isLocked) {
			return;
		}

		if (data.pointerEnter == null) {
			return;
		}

		RectTransform m_DraggingPlane = data.pointerEnter.transform as RectTransform;
        var rt = GetComponent<RectTransform>();
        Vector3 globalMousePos;
        if (RectTransformUtility.ScreenPointToWorldPointInRectangle(m_DraggingPlane, data.position, data.pressEventCamera, out globalMousePos))
        {
            rt.position = globalMousePos;
        }
    }
*/
	public void OnEndDrag(PointerEventData eventData)
	{
		_dragOnSurfaces = false;
	}
}
