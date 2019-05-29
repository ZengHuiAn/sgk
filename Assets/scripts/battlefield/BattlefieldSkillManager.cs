using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;
using UnityEngine.Playables;

namespace SGK {
    namespace Battle {
        [LuaCallCSharp]
        public class BattlefieldSkillManager : MonoBehaviour {
            public System.Action<object> selectedDelegate;
            public Animator animator;

            public ToggleGroup toggelGroup;

            [System.Serializable]
            public class SkillButton {
                public BattlefieldSkillButton button;
            };

            public BattlefieldSkillButton [] buttons;

            public BattlefieldSkillButton btnDefend;
            public BattlefieldSkillButton btnIdle;
            public GameObject btnCancel;
            public Image cancelIcon;

            public GraphicRaycaster graphicRaycaster;

            void Start() {
                Hide();
            }

            bool played = false;
            public void Set(int index, int icon, string name, int cd, bool disabled = false) {
                Set(index, string.Format("{0}", icon), name, cd, disabled);

                if (!played) {
                    played = true;
                    GetComponent<PlayableDirector>().Play();
                }
            }

            public void Set(int index, string icon, string name, int cd, bool disabled = false) {
                int pos = index - 1;
                if (pos >= 0 && pos < buttons.Length) {
                    buttons[pos].SetInfo(icon, name, cd, disabled);
                }
            }

            public Transform GetButtonTransform(int index) {
                int pos = index - 1;
                if (pos >= 0 && pos < buttons.Length) {
                    return buttons[pos].gameObject.transform;
                }
                return null;
            }

            public void Show(bool showIdle = true) {
                foreach (BattlefieldSkillButton btn in buttons) {
                    btn.Show(true);
                }

                btnDefend.Show(true);
                btnIdle.Show(showIdle);

                CanvasGroup cg = btnCancel.GetComponent<CanvasGroup>();
                cg.alpha = 0;
                cg.blocksRaycasts = false;

                if (animator != null) {
                    animator.SetBool ("show", true);
                }

                /*
                if (graphicRaycaster != null) {
                    graphicRaycaster.enabled = false;
                    Invoke("EnableGraphicRaycaster", 0.5f);
                }
                */
            }

            void EnableGraphicRaycaster() {
                graphicRaycaster.enabled = true;
            }


            public bool IsActive() {
                return btnDefend.gameObject.activeInHierarchy;
            }

            public void Hide(bool showCancel = false, string icon = "") {
                foreach (BattlefieldSkillButton btn in buttons) {
                    btn.Show(false);
                }

                if (animator != null) {
                    animator.SetBool ("show", false);
                }

                btnDefend.Show(false);
                btnIdle.Show(false);

                CanvasGroup cg = btnCancel.GetComponent<CanvasGroup>();
                cg.alpha = showCancel ? 1 : 0;
                cg.blocksRaycasts = showCancel;

                if (cancelIcon != null) {
                    cancelIcon.gameObject.SetActive(!string.IsNullOrEmpty(icon));
                    if (!string.IsNullOrEmpty(icon)) {
                        cancelIcon.LoadSprite("icon/" + icon);
                    }
                }
            }

            public void onSelected(int pos) {
                selectedDelegate(pos);
            }

            [ContextMenu("Play")]
            public void PlayeEnter() {
                GetComponent<PlayableDirector>().Play();
            }

            private void OnDestroy() {
                selectedDelegate = null;
            }
        }
    }
}