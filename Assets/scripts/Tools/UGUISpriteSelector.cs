using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UGUISpriteSelector : UGUISelector {
	[SerializeField]
	int _index = 0;

	public Sprite [] sprites;

	public Image [] images;

    public bool setNativeSize = false;

	public override int index {
		get {
			return _index;
		}

		set {
			if (value >= 0 && value < sprites.Length) {
				_index = value;
				UpdateSprite();
			}
		}
	}

    public override int Count {
        get { return (sprites == null) ? 0 : sprites.Length; }
    }

    [ContextMenu("Execute")]
	void UpdateSprite() {
		Image graphic = GetComponent<Image>();
        if (graphic != null) {
            graphic.sprite = sprites[_index];
            if (setNativeSize) {
                graphic.SetNativeSize();
            }
        }
		if (images != null) {
			for (int i = 0; i < images.Length; i++) {
				if (images[i]) {
					images[i].sprite = sprites[_index];
                    if (setNativeSize) {
                        images[i].SetNativeSize();
                    }
				}
			}
		}
	}
}
