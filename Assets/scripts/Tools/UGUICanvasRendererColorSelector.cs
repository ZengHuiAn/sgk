using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UGUICanvasRendererColorSelector : UGUISelector {
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
        get { return color.Length; }
    }

    public CanvasRenderer [] renderers;

	void SetColor(CanvasRenderer renderer, int index) {
		if (renderer == null || color == null || index < 0 || index > color.Length) {
			return;
		}

		renderer.SetColor(color[index]);
	}

	[ContextMenu("Execute")]
	void UpdateColor() {
		SetColor(GetComponent<CanvasRenderer>(), _index);
		for (int i = 0; i < renderers.Length; i++) {
			SetColor(renderers[i], _index);
		}
	}
}
