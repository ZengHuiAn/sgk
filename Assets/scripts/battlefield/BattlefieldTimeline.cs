using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using UnityEngine.UI;
using XLua;

namespace SGK {
    namespace Battle {
        [LuaCallCSharp]
        public class BattlefieldTimeline : MonoBehaviour {
            public GameObject timeLineItemPrefab;

            Dictionary<string, BattlefieldTimelineItem> items = new Dictionary<string, BattlefieldTimelineItem>();
            Dictionary<string, BattlefieldTimelineItem> itemsSetup = new Dictionary<string, BattlefieldTimelineItem>();

            bool changed = false;

            public void Set(int pos, int id, int icon, bool friend = false) {
                Set(pos, string.Format("{0}", id), string.Format("{0}", icon), friend);
            }

            public void Set(int pos, string id, int icon, bool friend = false) {
                Set(pos, id, string.Format("{0}", icon), friend);
            }

            public void Set(int pos, string id, string icon, bool friend = false) {
                if (pos > 0) {
                    int position = pos - 1;
                    BattlefieldTimelineItem item = getItem(id);
                    itemsSetup[id] = item;
                    item.position = position;
                    item.icon = icon;
                    item.friend = friend;
                    item.frame.gameObject.SetActive(true);
                    item.iconText.gameObject.SetActive(false);
                }
                changed = true;
            }

            public void SetRound(int pos, string id, int round)
            {
                if (pos > 0)
                {
                    int position = pos - 1;
                    BattlefieldTimelineItem item = getItem(id);
                    itemsSetup[id] = item;
                    item.position = position;
                    item.iconImage.GetComponent<UGUISpriteSelector>().index = 0;
                    item.frame.gameObject.SetActive(false);
                    item.text = round.ToString();
                    item.iconText.gameObject.SetActive(true);
                }
                changed = true;
            }

            void Cleanup() {
                if (!changed) {
                    return;
                }
                changed = false;

                foreach (KeyValuePair<string, BattlefieldTimelineItem> ite in items) {
                    if (!itemsSetup.ContainsKey(ite.Key)) {
                        Destroy(ite.Value.gameObject);
                    }
                }

                Dictionary<string, BattlefieldTimelineItem> swap = items;
                items = itemsSetup;
                itemsSetup = swap;
                itemsSetup.Clear();
            }

            void LateUpdate() {
                Cleanup();
            }

            public void Fastforward() {
                foreach(KeyValuePair<string, BattlefieldTimelineItem> ite in items) {
                    ite.Value.Fastforward();
                }
            }

            BattlefieldTimelineItem getItem(string id) {
                BattlefieldTimelineItem item;
                if (items.TryGetValue(id, out item)) {
                    return item;
                }

                if (itemsSetup.TryGetValue(id, out item)) {
                    return item;
                }

                if (timeLineItemPrefab == null) {
                    return null;
                }

                GameObject itemGameObject = Instantiate(timeLineItemPrefab, gameObject.transform) as GameObject;
                itemGameObject.SetActive(true);
                itemGameObject.name = string.Format("timeline_item_{0}", id);
                item = itemGameObject.GetComponent<BattlefieldTimelineItem>();
                return item;
            }
        }
    }
}