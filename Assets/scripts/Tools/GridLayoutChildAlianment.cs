using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(GridLayoutGroup))]
public class GridLayoutChildAlianment : MonoBehaviour {
	public TextAnchor anchorEnabled;
	public TextAnchor anchorDisabled;

	void Start() {
	}

	LayoutGroup _layout;
	LayoutGroup layout {
		get {
			if (_layout == null) {
				_layout = GetComponent<LayoutGroup>();
			}
			return _layout;
		}
	}

	void OnEnable() {
		layout.childAlignment = anchorEnabled;
	}

	void OnDisable() {
		layout.childAlignment = anchorDisabled;
	}
}
