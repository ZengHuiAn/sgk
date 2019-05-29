using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
    public class BattlefieldObjectPet : BattlefieldObject {
        public Image petIcon;
        public Image hpBar;
        public RectTransform handle;

        public Text countLabel;
        public Image typeIcon;

        public Image cd1Image;
        public Text  cd1Label;

        public Image cd2Image;
        public Text  cd2Label;
        // public UIDotCounter cdCounter;

        public int order = 0;

        #region spine
        public override void ChangeMode(string mode, float scale = 1.0f, string action = "", bool absolutePath = false, int sortingOrder = -1) {
            if (petIcon != null) {
                petIcon.LoadSprite(absolutePath ? mode : string.Format("icon/{0}", mode));
            }

            if (typeIcon != null) {
                typeIcon.LoadSprite(string.Format("icon/pet_type_{0}", action));
            }
        }

        public override void Play(params string[] actions) {
            // TODO: ??? what todo
        }

        // public virtual Vector3 GetPosition(string name) { }
        // public virtual void UpdateSkeletonTransform(string mode, float scale) {}
        #endregion

        #region visualization
        public override void Active(bool active = true, int param = 0) {
            Debug.LogWarning("BattlefieldObjectPet.Active");
        }

        public override void ShowWarning(int type) {
            Debug.LogWarning("BattlefieldObjectPet.Warning");
        }
        #endregion

        #region ui
        // public override void ShowUI(bool show = true) { Debug.LogWarning("BattlefieldObjectPet.ShowUI"); }

        public void UpdateUI(float hpPercent, int cd, int count, int order, int cd2 = 0) {
            // cdLabel.text = string.Format("{0}", cd);
            if (cd1Label != null) {
                cd1Image.gameObject.SetActive(cd != 0);
                cd1Label.gameObject.SetActive(cd != 0);
                cd1Label.text = string.Format("{0}", cd);
            }

            if (cd2Label != null) {
                cd2Image.gameObject.SetActive(cd2 != 0);
                cd2Label.gameObject.SetActive(cd2 != 0);
                cd2Label.text = string.Format("{0}", cd2);
            }

            if (countLabel != null) {
                countLabel.text = string.Format("x{0}", count);
            }

            if (hpBar != null) {
                //hpBar.SetValue((int)(hpPercent * 100), 100);
                hpBar.fillAmount = hpPercent;
            }

            if (handle != null) {
                handle.gameObject.SetActive(hpPercent != 1);
                handle.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, hpPercent * 100);
            }

            this.order = order;
            // if (cdCounter != null) { cdCounter.count = cd; }
        }

        // public override void UpdateProperty(int hp, int hpp, int mp, int mpp) {  }
        #endregion

        #region buff
        public override void AddBuff(int uuid, string icon) {
            // Debug.LogWarning("BattlefieldObjectPet.AddBuff");
        }

        public override void RemoveBuff(int uuid) {
            // Debug.LogWarning("BattlefieldObjectPet.RemoveBuff");
        }
        #endregion
    }
}
