using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

namespace SGK {
    public class FormationSlots : MonoBehaviour {
        public FormationSlotItem prefab;

        public System.Action onOrderChange;

        [SerializeField]
        int _count = 5;
        public int count {
            get { return _count; }
            set {
                if (_count != value) {
                    _count = value;
                    _start_pos = float.NaN;
                    FillSlots();
                }
            }
        }

        public float _elementWidth = 120;

        FormationSlotItem[] items;

        // Use this for initialization
        void Start() {
            FillSlots();
        }

        bool dirty = false;
        void Update() {
            if (_count <= 1) {
                return;
            }

            // Array.Sort(items, new CustomComparer());
            FormationSlotItem draging = null;
            int drag_slot = -1;
            for (int i = 0; i < items.Length; i++) {
                if (items[i] != null && items[i].dragOnSurfaces) {
                    draging = items[i];
                    drag_slot = i;
                    break;
                }
            }

            if (draging == null) {
                if (dirty) {
                    dirty = false;
                    for (int i = 0; i < items.Length; i++) {
                        SetPosition(items[i].gameObject.GetComponent<RectTransform>(), i);
                    }

                    if (onOrderChange != null) {
                        onOrderChange();
                    }
                }
                return;
            }
            dirty = true;

            if (draging.rt.anchoredPosition.x < start_pos) {
                draging.rt.anchoredPosition = new Vector2(start_pos, y_pos);
            }

            if (draging.rt.anchoredPosition.x > end_pos) {
                draging.rt.anchoredPosition = new Vector2(end_pos, y_pos);
            }

            int target_slot = (int)((draging.rt.anchoredPosition.x - start_pos + _elementWidth / 2) / _elementWidth);
            if (target_slot != drag_slot) {
                if (!items[target_slot].isLocked) {
                    items[drag_slot] = items[target_slot];
                    items[target_slot] = draging;
                    if (items[drag_slot] != null) {
                        SetPosition(items[drag_slot].gameObject.GetComponent<RectTransform>(), drag_slot);
                    }
                }
            }
        }

        private void OnDestroy() {
            onOrderChange = null;
        }

        float _y_pos = float.NaN;
        float y_pos {
            get {
                if (float.IsNaN(_y_pos)) {
                    _y_pos = prefab.gameObject.GetComponent<RectTransform>().anchoredPosition.y;
                }
                return _y_pos;
            }
        }

        float _start_pos = float.NaN;
        float start_pos {
            get {
                if (float.IsNaN(_start_pos)) {
                    Vector2 pos = prefab.gameObject.GetComponent<RectTransform>().anchoredPosition;
                    return pos.x - (items.Length - 1) * _elementWidth / 2;
                }
                return _start_pos;
            }
        }

        float end_pos {
            get {
                if (_count > 1) {
                    return start_pos + (_count - 1) * _elementWidth;
                } else {
                    return start_pos;
                }
            }
        }

        void SetPosition(RectTransform rt, int index) {
            rt.anchoredPosition = new Vector2(start_pos + _elementWidth * index, y_pos);
        }

        void FillSlots() {
            FormationSlotItem[] old_items = items;
            items = new FormationSlotItem[_count];

            // copy
            if (old_items != null) {
                //for (int i = 0; i < _count && i < old_items.Length; i++) {
                //	if (old_items[i] != null) {
                //		items[i] = old_items[i];
                //		old_items[i] = null;
                //	}
                //}

                //for (int i = 0; i < old_items.Length; i++) {
                //	Destroy(old_items[i].gameObject);
                //}

                for (int i = 0; i < old_items.Length; i++) {
                    if (old_items[i] != null && i < _count) {
                        items[i] = old_items[i];
                        old_items[i] = null;
                    } else {
                        Destroy(old_items[i].gameObject);
                    }
                }
            }

            Vector2 pos = prefab.gameObject.GetComponent<RectTransform>().anchoredPosition;

            // float start_pos = pos.x - (items.Length - 1) / 2 * _elementWidth;
            for (int i = 0; i < items.Length; i++) {
                FormationSlotItem item = items[i];
                if (item == null) {
                    item = Instantiate(prefab);
                    items[i] = item;
                    item.gameObject.SetActive(true);

                    // Set(i, i + 1, string.Format("{0}", 11000 + i));
                }

                RectTransform rt = item.gameObject.GetComponent<RectTransform>();
                rt.SetParent(GetComponent<RectTransform>(), false);
                SetPosition(rt, i);
                item.gameObject.name = string.Format("obj_{0}", i);
            }
        }

        public void Set(int index, long key, string skeletonName) {
            Set(index, key, skeletonName, null);
        }

        public void Set(int index, long key, string skeletonName, System.Action func) {
            if (index < 0 || index >= items.Length || items[index] == null) {
                return;
            }

            FormationSlotItem item = items[index];
            item.key = key;
            item.UpdateSkeleton(key == 0 ? "" : skeletonName);
            if (func != null) {
                func();
                func = null;
            }
        }

        public long Get(int index) {
            if (index < 0 || index >= items.Length || items[index] == null) {
                return 0;
            }
            return items[index].key;
        }

        public GameObject GetItem(int index) {
            if (index < 0 || index >= items.Length || items[index] == null) {
                return null;
            }
            return items[index].gameObject;
        }

        public void SetLock(int index, bool isLocked = true) {
            items[index].isLocked = isLocked;
        }
    }
}
