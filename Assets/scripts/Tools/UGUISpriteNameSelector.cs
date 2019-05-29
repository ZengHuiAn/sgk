using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using SGK;

public class UGUISpriteNameSelector : UGUISelector {
	[SerializeField]
	int _index = 0;

    public bool asyncLoad = true;
	public string [] sprites;

	public override int index {
		get {
			return _index;
		}

		set {
            _index = value;
			UpdateSprite();
		}
	}

    public override int Count {
        get { return sprites.Length; }
    }

    private void OnEnable() {
        UpdateSprite();
    }

    private void OnDisable() {
        Image graphic = GetComponent<Image>();
        if (graphic != null) {
            graphic.sprite = null;
        }
    }

    [ContextMenu("Execute")]
	void UpdateSprite() {
        if (_index < 0 && _index >= sprites.Length) {
            return;
        }

        if (string.IsNullOrEmpty(sprites[_index])) {
            return;
        }

        Image graphic = GetComponent<Image>();
        if (graphic == null) {
            return;
        }

        if (asyncLoad) {
            graphic.LoadSprite(sprites[_index]);
        } else {
            graphic.sprite = SGK.ResourcesManager.Load<Sprite>(sprites[_index]);
        }
	}
}
