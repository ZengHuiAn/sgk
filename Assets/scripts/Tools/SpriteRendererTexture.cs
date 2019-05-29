using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(SpriteRenderer))]
public class SpriteRendererTexture : MonoBehaviour {
	public Texture2D _texture;
	public Texture2D texture {
		get { return _texture; }
		set {
			if (_texture != value) {
				_texture = value;
				UpdateImage();
			}
		}
	}

	SpriteRenderer spriteRenderer;

	void Start () {
		spriteRenderer =  GetComponent<SpriteRenderer>();
		UpdateImage(false);
	}

#if UNITY_EDITOR
	void Update() {
		if (!Application.isPlaying) {
			UpdateImage(false);
		}
	}
#endif

	[ContextMenu("update")]
	void UpdateImage() {
		UpdateImage(true);
	}

	void UpdateImage(bool force) {
		Texture2D oldTexture = spriteRenderer.sprite ? spriteRenderer.sprite.texture : null;
		if (_texture != oldTexture || force) {
			Sprite sprite  = _texture ? Sprite.Create(texture, new Rect(0, 0, _texture.width, _texture.height), Vector2.one / 2) : null;
			spriteRenderer.sprite = sprite;
		}
	}
}
