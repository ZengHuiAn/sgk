using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TaskListView : MonoBehaviour {
    public float OffHeight = 5;
    public Transform recommendObj;
    public Transform scrollViewObj;
    public Transform parentObj;
    public Canvas canvasObj;
    public float recommendOff = 120;
    private float parentHeight = 0;

    // Use this for initialization
    void Start () {
		
	}

    private void Awake() {
        parentHeight = parentObj.GetComponent<RectTransform>().sizeDelta.y;
    }

    // Update is called once per frame
    void Update () {
        upContentSzie();
    }

    private void upContentSzie() {
        float _height = 0;
        float _wigth = 0;
        for (int i = 0; i < transform.childCount; ++i) {
            var _itemSize = transform.GetChild(i).GetComponent<RectTransform>().rect;
            transform.GetChild(i).localPosition = new Vector3(_itemSize.width + 20, _itemSize.height + _height - _itemSize.height / 2);
            _height = _itemSize.height + _height + OffHeight;
            if (_itemSize.height > _wigth) {
                _wigth = _itemSize.height;
            }
            upItem(transform.GetChild(i));
        }
        if (parentObj.GetComponent<RectTransform>().sizeDelta.y != _height) {
            if (parentHeight > parentObj.GetComponent<RectTransform>().sizeDelta.y) {
                parentObj.GetComponent<RectTransform>().sizeDelta = new Vector2(parentObj.GetComponent<RectTransform>().sizeDelta.x, parentHeight);
            } else {
                if (_height < parentHeight) {
                    parentObj.GetComponent<RectTransform>().sizeDelta = new Vector2(parentObj.GetComponent<RectTransform>().sizeDelta.x, _height);
                }
            }
        }
        GetComponent<RectTransform>().sizeDelta = new Vector2(_wigth, _height);
        if (recommendObj && parentObj) {
            var _pos = parentObj.position;
            recommendObj.transform.position = _pos;
            recommendObj.transform.localPosition += new Vector3(0, parentObj.GetComponent<RectTransform>().sizeDelta.y + recommendOff, 0);
        }

    }

    private void upItem(Transform item) {
        Bounds srcBounds = RectTransformUtility.CalculateRelativeRectTransformBounds(transform.parent, item);
        if (srcBounds.center.y > item.GetComponent<RectTransform>().rect.height / 2) {
            if (item.gameObject.activeSelf) {
                item.gameObject.SetActive(false);
            }
        } else {
            bool _show = srcBounds.center.y > - (item.GetComponent<RectTransform>().rect.height * 4.5);
            if (item.gameObject.activeSelf != _show) {
                item.gameObject.SetActive(_show);
            }
        }
    }

}
