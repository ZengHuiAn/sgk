using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace SGK {
    public class BattlefiledHeadManager : MonoBehaviour {
        // public newCharacterIcon prefab;
        public string point = "hitpoint";

        List<RectTransform> icons = new List<RectTransform>();
        // bool dirty = false;

        List<GameObject> cleanObjs = new List<GameObject>();

        RectTransform _rectTransform;
        public RectTransform rectTransform {
            get {
                if (_rectTransform == null) {
                    _rectTransform = GetComponent<RectTransform>();
                }
                return _rectTransform;
            }
        }

        void Start() {
        }

        public void Clear() {
            foreach(RectTransform rt in icons) {
                Destroy(rt.gameObject);
            }

            foreach (GameObject obj in cleanObjs) {
                Destroy(obj);
            }

            // dirty = false;
            icons.Clear();
        }

        public GameObject Show(BattlefieldObject obj, GameObject prefab, int pos) {
            GameObject icon = Instantiate(prefab);
            icon.SetActive(true);

            RectTransform rt = icon.GetComponent<RectTransform>();
            rt.SetParent(rectTransform, false);

            // int pos = info.Get<int>("pos");
            rt.anchorMax = rt.anchorMin = Vector2.zero;

            if (pos >= 1 && pos <= 5) {
                rt.anchoredPosition3D = new Vector2(rectTransform.rect.width / 6 * pos, 200);
            } else {
                Vector3 worldPosition = obj.GetPosition(point);
                Vector2 ViewportPosition = Camera.main.WorldToViewportPoint(worldPosition);

                ViewportPosition.x = Mathf.Clamp(ViewportPosition.x, 0, 1);
                ViewportPosition.y = Mathf.Clamp(ViewportPosition.y, 0, 1);

                rt.anchoredPosition3D = new Vector2(
                    rectTransform.rect.width * ViewportPosition.x,
                    rectTransform.rect.height * ViewportPosition.y);
            }

            // icon.SetInfo(info);

            if (pos >= 1 && pos <= 5) {
                Record(rt.gameObject);
            } else {
                icons.Add(rt);
                // dirty = true;
            }

            return icon;
            // return icon.gameObject.GetComponent<UGUIClickEventListener>();
        }

        public void Record(GameObject obj) {
            cleanObjs.Add(obj);
        }
    }
}
