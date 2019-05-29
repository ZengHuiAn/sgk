using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using DG.Tweening;

namespace SGK {
    public class BattlefieldTimelineItem : MonoBehaviour {
        // inspector
        public Image bgImage;
        public Image iconImage;
        public Text iconText;
        public Image frame;

        public bool friend = false;
        public float moveDuration = 0.5f;
        /*
                public Sprite firstBackgroundImage;
                public Sprite friendBackgroundImage;
                public Sprite enemyBackgroundImage;
        */
        UGUISelector colorSelector = null;

        // property
        private int _position = -1;
        public int position {
            get { return _position; }
            set {
                if (_position != value) {
                    _position = value;
                }
                MoveTo(value);
            }
        }

        private string _icon = "";
        public string icon {
            get { return _icon; }
            set {
                if (_icon != value) {
                    _icon = value;
                    iconImage.LoadSprite("icon/" + value);
                }
            }
        }

        private string _text = "";
        public string text {
            get { return _text; }
            set{
                if (_text != value)
                {
                    _text = value;
                    iconText.text = _text;
                }
            }
        }

        float w = 0;
        float w_large = 0 ;

        Vector3 targetPosition = Vector3.zero;
        Vector3 startPosition = Vector3.zero;

        RectTransform rectTransform;
        float passTime = -1;

		void Awake() {
            colorSelector = GetComponent<UGUISelector>();
            rectTransform = gameObject.GetComponent<RectTransform>();
			w = rectTransform.rect.width;
            w_large = w * 1.25f;
		}

        // Use this for initialization
        void Start() {
            rectTransform = gameObject.GetComponent<RectTransform>();

            rectTransform.anchoredPosition3D = getPositionByPos(0);
            rectTransform.localScale = Vector3.one;
            rectTransform.localRotation = Quaternion.identity;

            startPosition = rectTransform.anchoredPosition;
            // rectTransform.SetSiblingIndex(-position);
        }

        // Update is called once per frame
        void Update() {
            if (passTime < 0) {
                return;
            }

            passTime += Time.deltaTime;

            if (passTime < 0.2f) {
                return;
            }

            float moveTime = passTime - 0.2f;

            if (moveTime >= moveDuration) {
                rectTransform.anchoredPosition = targetPosition;
                passTime = -1;
            } else {
                rectTransform.anchoredPosition3D = Vector2.Lerp(startPosition, targetPosition, moveTime / moveDuration);
            }
        }

        Vector2 getPositionByPos(int i) {
            if (i == 0) {
                return new Vector3(w_large / 2, 0, 0);
            } else {
                return new Vector3((i - 1) * (w + 1) + w / 2 + w_large, 0, 0);
            }
        }

        void MoveTo(int i) {
            targetPosition = getPositionByPos(i);

            if (i == 0) {
                transform.DOScale(1.25f, 0.6f);
            } else if ( transform.localScale.x != 1) {
                transform.DOScale(1f, 0.6f);
            }


            if (colorSelector != null) {
                colorSelector.index = (friend ? 0 : 1) + ((i == 0) ? 2 : 0);
            }

            if (rectTransform) {
                startPosition = rectTransform.anchoredPosition;
                // rectTransform.SetSiblingIndex(-i);
            }
            passTime = 0.0f;
        }

        public void Fastforward() {
            rectTransform.anchoredPosition = targetPosition;
            passTime = -1;
        }
    }
}