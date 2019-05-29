using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
	[ExecuteInEditMode]
	[RequireComponent(typeof(Image))]
	public class UIDotCounter : MonoBehaviour {
		public float dotWidth = 12;
		public float dotHeight= 12;
		RectTransform rectTransform;

		[SerializeField]
		[Range(0,10)]
		float _count = 0;

		public float count {
			get { return _count; }
			set {
				if (_count != value) {
					_count = value;
					if (rectTransform != null) {
						rectTransform.sizeDelta = new Vector2 (dotWidth * _count, dotHeight);
					}
				}
			}
		}

		void Start () {
			rectTransform = GetComponent<RectTransform>();
			rectTransform.sizeDelta = new Vector2 (dotWidth * _count, dotHeight);
		}

#if UNITY_EDITOR
		void Update() {
			rectTransform.sizeDelta = new Vector2 (dotWidth * _count, dotHeight);
		}
#endif
	}
}
