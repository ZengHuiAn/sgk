using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UGUISelector : MonoBehaviour {
	public virtual int index { 
		get { return 0;	}
		set {	}
	}

    public virtual int Count {
        get { return 0; }
    }

	void Start() {
	}


    public void Toggle(bool enable) {
        index = enable ? 1 : 0;
    }


#if UNITY_EDITOR
    [ContextMenu("Next")]
    public void NextValue() {
        if (Count > 0) {
            index = (index+1) % Count;
        }
    }
#endif
}

public class UGUISelectorGroup : UGUISelector {
	[SerializeField]
	int _index = 0;

	public UGUISelector [] selectors;

	public override int index {
		get {
			return _index;
		}

		set {
			_index = value;
			UpdateValue();
		}
	}

    int _lastIdx = 0;
    const int _grayIdx = 4;
    public void setGray() {
        if (index != _grayIdx)
        {
            _lastIdx = index;
            index = _grayIdx;
        }
    }

    public void reset() {
        if (index != _grayIdx) {
            _lastIdx = index;
        }
        index = _lastIdx;
    }

    public override int Count {
        get {
            if (selectors.Length == 0 || selectors[0] == null) return 0;
            return selectors[0].Count;
        }
    }

    [ContextMenu("Execute")]
	void UpdateValue() {
		for (int i = 0; i < selectors.Length; i++) {
			if (selectors[i] != null) {
				selectors[i].index = _index;
			}
		}
	}
}
