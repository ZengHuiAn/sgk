using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;
public class UIMultiScrollIndex : MonoBehaviour
{
    private UIMultiScroller _scroller;
    private int _index;
	private Vector2 _IstweenPosition;
	private bool IsTween = false;

	private UIMultiScroller.Arrangement _movement = UIMultiScroller.Arrangement.Horizontal;
    void Start()
    {
      
    }

    private void OnButtonAddClick()
    {
        //添加一个新的Item
        _scroller.AddItem(_index + 1);
    }

    private void OnButtonDelClick()
    {
        //删除当前的Item
        _scroller.DelItem(_index);
    }
	public UIMultiScroller.Arrangement Movement
	{
		set{
			_movement = value;
		}
	}
	public Vector2 IstweenPosition
	{
		set{
			_IstweenPosition = value;
			IsTween = true;
		}
	}
    public int Index
    {
        get { return _index; }
        set
        {
            _index = value;
            if (IsTween)
            {
                IsTween = false;
                if (_movement == UIMultiScroller.Arrangement.Vertical)
                {
                    transform.localPosition = new Vector3(transform.localPosition.x + _IstweenPosition.x, transform.localPosition.y, 0);
                    transform.DOLocalMove(_scroller.GetPosition(_index), 0.3f).SetDelay(0.1f * (Mathf.Abs(transform.localPosition.y) / _IstweenPosition.y));
                }
                else
                {
                    transform.localPosition = new Vector3(transform.localPosition.x, transform.localPosition.y + _IstweenPosition.y, 0);
                    transform.DOLocalMove(_scroller.GetPosition(_index), 0.3f).SetDelay(0.1f * (Mathf.Abs(transform.localPosition.x) / _IstweenPosition.x));
                }
            }
            else {
                transform.localPosition = _scroller.GetPosition(_index);
            }
            gameObject.name = "Scroll" + (_index < 10 ? "0" + _index : _index.ToString());
        }
    }

    public UIMultiScroller Scroller
    {
        set { _scroller = value; }
    }

    public static UIMultiScrollIndex Get(GameObject obj) {
        UIMultiScrollIndex index = obj.GetComponent<UIMultiScrollIndex>();
        if (index == null) {
            index = obj.AddComponent<UIMultiScrollIndex>();
        }
        return index;
    }
}
