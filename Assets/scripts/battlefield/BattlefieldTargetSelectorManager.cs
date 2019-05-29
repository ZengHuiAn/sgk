using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Spine.Unity;

namespace SGK {
    namespace Battle {
        public class BattlefieldTargetSelectorManager : MonoBehaviour {
            public System.Action<object> selectedDelegate;

            public GameObject prefab;
            public Transform battle;
            public RectTransform characterDialog;
            public Text characterDialogText;
            float characterDialogDuration = 0;

            public BattlefieldObject enemySelector;
            public BattlefieldObject partnerSelector;

            public ToggleGroup skillToggleGroup;

            public static float selector_speed = 5;

            List<GameObject> selectorPool = new List<GameObject>();

            class SelectInfo {
                public int uuid;
                public GameObject selector;
                System.WeakReference followed;

                RectTransform rectTransform;
                BattlefiledUIConstraint constraint;

                public List<GameObject> followers = new List<GameObject>();

                public SelectInfo(int uuid, GameObject selector, BattlefieldObject followed, int type) {
                    this.uuid = uuid;
                    this.selector = selector;
                    this.followed = new System.WeakReference(followed);

                    constraint = selector.GetComponent<BattlefiledUIConstraint>();
                    rectTransform = selector.GetComponent<RectTransform>();

                    this.type = type;

                    UpdatePostion(false);
                }

                int _type = 0;
                public int type {
                    get { return _type;  }
                    set {
                        _type = value;
                        if (constraint != null) {
                            constraint.enabled = ((_type & 1) == 0);
                        }
                    }
                }

                void UpdatePostion(bool lerp = true) {
                    BattlefieldObject battle_obj = (BattlefieldObject)(followed.Target);
                    Vector3 worldPosition = battle_obj.GetPosition("hitpoint");
                    if ((type & 2) != 0) {
                        worldPosition.y -= 0.5f;
                    }

                    Vector2 ViewportPosition = Camera.main.WorldToViewportPoint(worldPosition);

                    if (lerp) {
                        rectTransform.anchorMin = Vector2.Lerp(rectTransform.anchorMin, ViewportPosition, Time.deltaTime * selector_speed);
                        rectTransform.anchorMax = Vector2.Lerp(rectTransform.anchorMax, ViewportPosition, Time.deltaTime * selector_speed);
                    } else {
                        rectTransform.anchorMin = ViewportPosition;
                        rectTransform.anchorMax = ViewportPosition;
                    }
                    rectTransform.anchoredPosition3D = Vector3.zero;
                }

                public void Update() {
                    if (!followed.IsAlive) {
                        return;
                    }

                    UpdatePostion( constraint != null && constraint.enabled );

                    Ray ray = Camera.main.ScreenPointToRay(rectTransform.position);
                    Vector3 effectposition = ray.origin + ray.direction * 4.9f;

                    Debug.DrawRay(ray.origin, ray.direction * 10, Color.yellow);

                    foreach (GameObject obj in followers) {
                        obj.transform.position = effectposition;
                    }
                }

                public void addFollower(GameObject obj) {
                    followers.Add(obj);
                }

                public void cleanFollower() {
                    foreach(GameObject obj in followers) {
                        SGK.GameObjectPoolManager.getInstance().Release(obj);
                    }
                    followers.Clear();
                }
            }
                
            Dictionary<int, SelectInfo> selectors = new Dictionary<int, SelectInfo>();

            [XLua.LuaCallCSharp]
            public void Show(int uuid, BattlefieldObject obj = null, int type = 0, params string [] effectNames) {
                if ( (uuid >= 0 &&  obj == null) || selectors.ContainsKey(uuid)) {
                    return;
                }

                if (uuid == -1) {
                    obj = partnerSelector;
                } else if (uuid < 0) {
                    obj = enemySelector;
                }

                GameObject selector = null;
                if (selectorPool.Count == 0) {
                    selector = Instantiate(prefab);
                    selector.GetComponent<RectTransform>().SetParent(GetComponent<RectTransform>(), false);
                } else {
                    selector = selectorPool[0];
                    selectorPool.RemoveAt(0);
                }

                selector.transform.localPosition = Vector3.zero;
                selector.transform.localScale = Vector3.one;
                selector.transform.localRotation = Quaternion.identity;

                selector.SetActive(true);

                if (uuid < 0) {
                    selector.transform.localScale = Vector3.one * 1.5f;
                } else {
                    selector.transform.localScale = Vector3.one;
                }

                selector.name = string.Format("targetSelector_{0}", obj.name);
                UGUIClickEventListener.Get(selector).onClick = () => {
                    onSelected(uuid);
                };
                
                selectors [uuid] = new SelectInfo (uuid, selector, obj, type);

                selectors[uuid].Update ();

                if (effectNames.Length > 0) {
                    for (int i = 0; i < effectNames.Length; i++) {
                        if (!string.IsNullOrEmpty(effectNames[i])) {
                            string fullPath = string.Format("prefabs/effect/{0}.prefab", effectNames[i]);
                            ResourcesManager.LoadAsync(this, fullPath, (o) => {
                                if (selectors.ContainsKey(uuid) == true) {
                                    GameObject effect = SGK.GameObjectPoolManager.getInstance().Get(fullPath);

                                    effect.transform.localPosition = Vector3.zero;
                                    effect.transform.localScale = Vector3.one;
                                    effect.transform.localRotation = Quaternion.identity;

                                    effect.SetActive(true);

                                    selectors[uuid].addFollower(effect);
                                }
                            });
                        }
                    }
                }
            }

            public void AddUIEffect(string prefabName, Vector3 worldPosition, System.Action<Object> callback) {
                GameObject obj = AddUIEffect(prefabName, worldPosition);

                if (callback != null) {
                    callback(obj);
                    callback = null;
                }
            }

            public GameObject AddUIEffect(string prefabName, Vector3 worldPosition) {
                GameObject obj = SGK.GameObjectPoolManager.getInstance().Get(prefabName);
                if (obj == null) {
                    return null;
                }

                Vector2 ViewportPosition = Camera.main.WorldToViewportPoint(worldPosition);

                RectTransform rectTransform = obj.GetComponent<RectTransform>();
                rectTransform.SetParent(gameObject.transform, true);

                rectTransform.localScale = Vector3.one;
                rectTransform.localRotation = Quaternion.identity;

                rectTransform.anchoredPosition3D = Vector3.zero;
                rectTransform.anchoredPosition = Vector2.zero;

                rectTransform.anchorMin = ViewportPosition;
                rectTransform.anchorMax = ViewportPosition;

                obj.SetActive(true);

                return obj;
            }

            public void SetUIPosition(RectTransform rectTransform, Vector3 worldPosition) {
                Vector2 ViewportPosition = Camera.main.WorldToViewportPoint(worldPosition);

                rectTransform.anchoredPosition3D = Vector3.zero;
                rectTransform.anchoredPosition = Vector2.zero;

                rectTransform.anchorMin = ViewportPosition;
                rectTransform.anchorMax = ViewportPosition;
            }

            public void ShowDialog(BattlefieldObject obj, string text, float duration) {
                if (characterDialogText) {
                    characterDialogText.text = text;
                }

                characterDialogDuration = duration;
                if (characterDialogDuration > 0 && obj != null) {
                    characterDialog.gameObject.SetActive(true);
                    Vector3 worldPosition = obj.GetPosition("head");
                    Vector2 ViewportPosition = Camera.main.WorldToViewportPoint(worldPosition);
                    characterDialog.anchorMin = ViewportPosition;
                    characterDialog.anchorMax = ViewportPosition;
                    characterDialog.anchoredPosition3D = Vector3.zero;
                } else {
                    characterDialogDuration = 0;
                    characterDialog.gameObject.SetActive(false);
                }
            }

            void Start() {
                RectTransform rt = gameObject.GetComponent<RectTransform>();
                for (int i = 0; i < 5; i++) {
                    GameObject obj = Instantiate(prefab);
                    selectorPool.Add(obj);
                    obj.SetActive(false);
                    obj.GetComponent<RectTransform>().SetParent(rt, false);
                }
            }

            void OnDestroy() {
                selectorPool.Clear();
                selectedDelegate = null;
            }

            void Update() {
                foreach (KeyValuePair<int, SelectInfo> ite in selectors) {
                    ite.Value.Update ();
                }

                if (characterDialogDuration > 0) {
                    characterDialogDuration -= Time.deltaTime;
                    if (characterDialogDuration <= 0) {
                        characterDialog.gameObject.SetActive(false);
                    }
                }
            }

            [XLua.LuaCallCSharp]
            public void Hide() {
                foreach (KeyValuePair<int, SelectInfo> ite in selectors) {
                    ite.Value.cleanFollower();
                    selectorPool.Add(ite.Value.selector);
                    ite.Value.selector.SetActive(false);
                    ite.Value.selector.name = "targetSelector";
                }
                selectors.Clear();
            }

            public void onSelected(int uuid) {
                Hide();
                if (skillToggleGroup != null) {
                    skillToggleGroup.SetAllTogglesOff();
                }
                selectedDelegate(uuid);
            }
        }
    }
}
