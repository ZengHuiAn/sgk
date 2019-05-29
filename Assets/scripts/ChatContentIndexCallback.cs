using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class ChatContentIndexCallback : MonoBehaviour 
{
	private ChatContent _chatContent;
	private int _index;
    private RectTransform _rect;
    public ChatContent chatContent
    {
        set { _chatContent = value; }
	}
	public int index{
		set{
			_index = value;
			gameObject.name = _index.ToString();
            if (_chatContent.onRefreshItem != null)
                _chatContent.onRefreshItem(this.gameObject, _index);
			//this.transform.SetSiblingIndex(_index);
		}
		get{
			return _index;
		}
	}
	public RectTransform rect {
		get{ 
			if (_rect == null)
				_rect = this.GetComponent<RectTransform>();
			return _rect;
		}
	}
}
