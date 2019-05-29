using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UGUIColorSelector : UGUISelector {
	[SerializeField]
    int _index = 0;

    public Color [] color;

	public override int index {
		get {
			return _index;
		}

		set {
			if (value >= 0 && value < color.Length) {
				_index = value;
				UpdateColor();
			}
		}
	}

    public override int Count {
        get { return (color == null) ? 0 : color.Length; }
    }

    public Graphic [] graphics;

	[ContextMenu("Execute")]
	void UpdateColor() {
		Graphic graphic = GetComponent<Graphic>();
		if (graphic != null) graphic.color = color[_index];
		for (int i = 0; i < graphics.Length; i++) {
			if (graphics[i] != null) {
				graphics[i].color = color[_index];
			}
		}
	}
}
