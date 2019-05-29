using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
    public class BattlefieldObjectWithBar : BattlefieldObject {
        public GameObject ui;
        public BattlefieldProgressBar hpBar;
        public BattlefieldProgressBar mpBar;
        public RectTransform  buffBar;
        public GameObject [] buffPrefab;

        class BuffInfo {
            public GameObject obj;
            public int count;

            public Image image;
            public Text text;
            public BuffInfo(GameObject obj, int count) {
                this.obj = obj;
                this.count = count;
                image = null;
                text = null;
            }
        };

        Dictionary<int, BuffInfo> buffList = new Dictionary<int, BuffInfo>();

        public override void UpdateProperty(float hp, float hpp, float mp, float mpp, float shield = 0) {
            if (hpBar) {
                hpBar.SetValue((int)hp, (int)hpp, (int)shield);
            }

            if (mpBar) {
                mpBar.SetValue((int)mp, (int)mpp);
            }
        }

        public override void AddBuff(int uuid, string icon) {
            BuffInfo info;
            if (buffList.TryGetValue(uuid, out info)) {
                info.count += 1;
            } else {
                GameObject buffIcon = Instantiate(buffPrefab[Random.Range(0, buffPrefab.Length)]);
                Image image = buffIcon.transform.Find("Icon").gameObject.GetComponent<Image>();
                Text Text = buffIcon.transform.Find("Text").gameObject.GetComponent<Text>();

                info = new BuffInfo(buffIcon, 1);

                info.image = image;
                info.text = Text;

                buffList[uuid] = info;
                buffIcon.SetActive(true);
                image.color = Color.clear;
                buffIcon.transform.SetParent(buffBar, false);
                buffIcon.transform.localPosition = Vector3.zero;
                // buffIcon.transform.localScale = Vector3.one;
                buffIcon.transform.localRotation = Quaternion.identity;

                layout_changed = true;
            }

            info.image.LoadSprite(string.Format("icon/{0}", icon), Color.white);

            if (info.text != null) {
                if (info.count > 1) {
                    info.text.text = string.Format("x{0}", info.count);
                } else {
                    info.text.text = "";
                }
            }
        }

        public override void RemoveBuff(int uuid) {
            BuffInfo info;
            if (buffList.TryGetValue(uuid, out info)) {
                info.count -= 1;
                if (info.count <= 0) {
                    buffList.Remove(uuid);
                    Destroy(info.obj);
                    layout_changed = true;
                } else {
                    if (info.text != null) {
                        if (info.count > 1) {
                            info.text.text = string.Format("x{0}", info.count);
                        } else {
                            info.text.text = "";
                        }
                    }
                }
            }
        }

        bool layout_changed = false;
        protected override void Update() {
            base.Update();
            if (layout_changed) {
                buffBar.GetComponent<UGUISimpleLayout>().Layout();
            }
        }

        public override void ShowUI(bool show = true) {
            ui.SetActive(show);
        }

        protected override bool GetSpecialPosition(string name, out Vector3 pos ) {
            pos = Vector3.zero;
            if (name == "stat_bar") {
                pos = hpBar.transform.position;
                return true;
            }
            return false;
        }
    }
}
