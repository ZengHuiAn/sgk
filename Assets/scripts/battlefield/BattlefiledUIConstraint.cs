using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace SGK {
    public class BattlefiledUIConstraint : MonoBehaviour {
        public string constraintTag = "";
        public float speed = 200;
        public float space = 0;

        static List<BattlefiledUIConstraint> allItems = new List<BattlefiledUIConstraint>();

        RectTransform _rectTransform;
        public RectTransform rectTransform {
            get {
                if (_rectTransform == null) {
                    _rectTransform = GetComponent<RectTransform>();
                }
                return _rectTransform;
            }
        }

        void OnEnable() {
            allItems.Add(this);
        }

        void OnDisable() {
            allItems.Remove(this);
        }

        public static Rect rectInScreen(RectTransform transform, float space = 0) {
            Vector2 size = Vector2.Scale(transform.rect.size, transform.lossyScale);
            Rect rect = new Rect(transform.position.x, transform.position.y, size.x, size.y);
            rect.x -= (transform.pivot.x * size.x);
            rect.y -= (transform.pivot.y * size.y);
            rect.x -= space;
            rect.y -= space;
            rect.width += 2 * space;
            rect.height += 2 * space;
            return rect;
        }

        void Update() {
            if (string.IsNullOrEmpty(this.constraintTag)) {
                return;
            }

            foreach (BattlefiledUIConstraint target in allItems) {
                if (target == this || target.constraintTag != this.constraintTag || string.IsNullOrEmpty(target.constraintTag)) {
                    continue;
                }

                Rect r1 = rectInScreen(rectTransform, space);
                Rect r2 = rectInScreen(target.rectTransform, space);

                if (r1.Overlaps(r2)) {
                    Vector2 normal = (r1.center - r2.center).normalized;
                    if (normal.sqrMagnitude < 1) {
                        normal = new Vector2(0, 1);
                    }
                    Vector2 pos = rectTransform.position;
                    Vector2 offset = normal * speed * Time.deltaTime;
                    r1.x += offset.x;
                    r1.y += offset.y;
                    rectTransform.position = adJustPos(pos + offset, r1);
                } else {
                    rectTransform.position = adJustPos(rectTransform.position, r1);
                }
            }
        }

        public static Vector2 adJustPos(Vector2 pos, Rect rt) {
            Vector2 offset = new Vector2(0, 0);
            if (rt.x < 0) {
                offset.x = -rt.x;
            } else if (rt.x + rt.width > Screen.width) {
                offset.x = Screen.width - rt.x - rt.width;
            }

            if (rt.y < 0) {
                offset.y = -rt.y;
            } else if (rt.y + rt.height > Screen.height) {
                offset.y = Screen.height - rt.y - rt.height;
            }
            return pos + offset;
        }
    }
}
