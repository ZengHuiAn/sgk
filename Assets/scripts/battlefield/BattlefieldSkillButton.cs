using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;

namespace SGK {
	public class BattlefieldSkillButton : MonoBehaviour {
		public Image [] images = null;

		[Range(0, 2)]
		public float selectScale = 1.0f;
		public Color selectColor = Color.white;

		[Range(0, 2)]
		public float unselectScale = 0.8f;
		public Color unselectColor = Color.grey;

        public Material disabledMaterial = null;

        public Image iconImage;
        public Image cooldownIcon;
        public Text cooldownText;
        public Text nameLabel;

        struct IconInfo {
            public string icon;
            public string name;
            public int cd;
            public bool disabled;
        }

        IconInfo nextIconInfo;
        IconInfo currIconInfo;

        CanvasGroup cg;
        void Start() {
            cg = GetComponent<CanvasGroup>();
        }

        void SetInfoImmediately(string icon, string name, int cd, bool disabled = false) {
            if (nameLabel != null) nameLabel.text = name;
            if (cooldownIcon != null) {
                cooldownIcon.gameObject.SetActive(true);
                cooldownIcon.enabled = cd > 0;
            }
            if (cooldownText) {
                cooldownText.gameObject.SetActive(true);
                cooldownText.text = (cd > 0) ? string.Format("{0}", cd) : "";
                cooldownText.enabled = true;
            }

            if (iconImage != null && currIconInfo.name != icon && !string.IsNullOrEmpty(icon)) {
                iconImage.LoadSprite("icon/" + icon);
            }
            SetEnabled(!disabled);

            currIconInfo.icon = icon;
            currIconInfo.name = name;
            currIconInfo.cd = cd;
            currIconInfo.disabled = disabled;

            nextIconInfo.icon = null;
        }

        public void SetInfo(string icon, string name, int cd, bool disabled = false) {
            if (icon == currIconInfo.icon || string.IsNullOrEmpty(currIconInfo.name)) {
                SetInfoImmediately(icon,name,cd, disabled);
            } else {
                nextIconInfo.icon = icon;
                nextIconInfo.name = name;
                nextIconInfo.cd   = cd;
                nextIconInfo.disabled = disabled;
                GetComponent<Animator>().SetTrigger("Change");
            }
        }

        public void SetSelect(bool selected) {
            transform.DOScale(Vector3.one * (selected ? selectScale : unselectScale), 0.1f);

            for (int i = 0; i < images.Length; i++) {
                images[i].color = selected ? selectColor : unselectColor;
            }
		}

        public void SetEnabled(bool enabled) {
            for (int i = 0; i < images.Length; i++) {
                images[i].material = (enabled ? null : disabledMaterial);
            }
        }

        public void Show(bool show) {
            cg = GetComponent<CanvasGroup>();
            if (cg == null) {
                gameObject.SetActive(show);
            } else {
                cg.alpha = (show ? 1 :0);
                cg.blocksRaycasts = show;
            }
        }

		[ContextMenu("Select")]
		public void Select() {
			SetSelect(true);
		}

		[ContextMenu("Unselect")]
		public void Unselect() {
			SetSelect(false);
		}

        public void EventChangeIcon() {
            if (!string.IsNullOrEmpty(nextIconInfo.icon)) {
                SetInfoImmediately(nextIconInfo.icon, nextIconInfo.name, nextIconInfo.cd, nextIconInfo.disabled);
            }
        }

        public void EventChangeIconFinished() {
            if (!string.IsNullOrEmpty(nextIconInfo.icon) && currIconInfo.icon != nextIconInfo.icon) {
                GetComponent<Animator>().SetTrigger("Change");
            }
        }
	}
}
