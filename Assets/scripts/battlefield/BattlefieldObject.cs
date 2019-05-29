using UnityEngine;
using Spine.Unity;
using System.Collections;
using System.Collections.Generic;
using Spine;

namespace SGK {
    public class BattlefieldObject : MonoBehaviour {
        public GameObject spineObject = null;
        protected SkeletonAnimation skeletonAnimation = null;

        public delegate void SpineEvent(string eventName, string strValue, int intValue, float floatValue);
        public SpineEvent onSpineEvent = null;

        bool _flip = false;
        public bool flip {
            get { return _flip; }
            set { 
                if (_flip != value) {
                    _flip = value;
                    if (skeletonAnimation != null && skeletonAnimation.skeleton != null && skeletonAnimation.skeleton.FlipX != _flip) {
                        skeletonAnimation.skeleton.FlipX = _flip;
                        OnFlipChanged();
                    }
                }
            }
        }

        // Color color = Color.white;
        float colorDuration = 0.0f;
        string skinName;

        public virtual void Start() {
            if (spineObject != null) {
                skeletonAnimation = spineObject.GetComponent<SkeletonAnimation>();
                watchEvent();
            }
        }

        public virtual void SetName(string name) {
            // Debug.LogFormat("BattlefieldObject:SetName {0}", name);
        }
        
        public static SkeletonAnimation ForceChangeMode(GameObject obj, SkeletonDataAsset skeletonDataAsset, string action = "idle") {
            SkeletonAnimation animation = obj.GetComponent<SkeletonAnimation>();
            if (animation != null) {
                DestroyImmediate(animation);
            }

            animation = obj.AddComponent<SkeletonAnimation>();
            animation.skeletonDataAsset = skeletonDataAsset;
            animation.Initialize(true);
            animation.state.SetAnimation(0, action, true);

            return animation;
        }

        string[] actions = null;

        public virtual void ChangeIcon(string iconName, int level, int quality, int star) {
        }


        Color color = Color.white;
        public void SetColor(Color color, float delay) {
            this.color.r = color.r;
            this.color.g = color.g;
            this.color.b = color.b;
            if (skeletonAnimation != null && skeletonAnimation.skeleton != null) {
                skeletonAnimation.skeleton.SetColor(this.color);
                colorDuration = delay;
            }
        }

        public void SetAlpha(float alpha) {
            this.color.a = alpha;
            if (skeletonAnimation != null && skeletonAnimation.skeleton != null) {
                skeletonAnimation.skeleton.SetColor(this.color);
            }
        }

        public void SetExposure(float exposure) {
            if (spineObject == null) {
                return;
            }

            MaskableSkeletonAnimation ani = spineObject.GetComponent<MaskableSkeletonAnimation>();
            if (ani == null) {
                ani = spineObject.AddComponent<MaskableSkeletonAnimation>();
            }
            ani.Exposure = exposure;
        }

        string currentSkingName;
        public void SetSkin(string skinName) {
            currentSkingName = skinName;
            if (skeletonAnimation != null && skeletonAnimation.skeleton != null) {
                if (skeletonAnimation.skeleton.Data.FindSkin(skinName) != null) {
                    skeletonAnimation.skeleton.SetSkin(skinName);
                }
            }
        }

        #region spine
        public virtual void ChangeMode(string mode, SkeletonDataAsset skeletonDataAsset, float scale = 1.0f, string action = "idle", int sortingOrder = -1) {
            ChangeModePre(mode, action);
            ChangeModePost(mode, skeletonDataAsset, scale, action, sortingOrder);
        }

        public virtual void ChangeMode(string mode, float scale = 1.0f, string action = "idle", bool absolutePath = false, int sortingOrder = -1) {
            ChangeModePre(mode, action);

            MonoBehaviour mb = skeletonAnimation;
            if (mb == null) {
                mb = this;
            }

            if (string.IsNullOrEmpty(mode)) {
                return;
            }

            string path = absolutePath ? name : string.Format("roles/{0}/{0}_SkeletonData.asset", mode, mode);
            ResourcesManager.LoadAsync(mb, path, typeof(SkeletonDataAsset), o => {
                SkeletonDataAsset skeletonDataAsset = o as SkeletonDataAsset;
                if (skeletonDataAsset == null) {
                    Debug.LogWarningFormat("skeleton {0} can't load", mode);
                    return;
                }
                ChangeModePost(mode, skeletonDataAsset, scale, action, sortingOrder);
            });
        }

        void ChangeModePre(string mode, string action) {
            if (string.IsNullOrEmpty(mode)) {
                if (skeletonAnimation != null) {
                    DestroyImmediate(skeletonAnimation);
                    skeletonAnimation = null;
                    return;
                }
            }

            actions = new string[] {
                action
            };

        }

        void ChangeModePost(string mode , SkeletonDataAsset skeletonDataAsset, float scale = 1.0f, string action = "idle", int sortingOrder = -1) {
            if (skeletonAnimation != null) {
                if (skeletonAnimation.skeletonDataAsset == skeletonDataAsset) {
                    UpdateSkeletonTransform(mode, scale);
                    skeletonAnimation.state.SetAnimation(0, action, true);
                    return;
                } else {
                    stopWatch();
                    DestroyImmediate(skeletonAnimation);
                }
            }

            if (spineObject == null) {
                spineObject = new GameObject();
            }

            skeletonAnimation = spineObject.AddComponent<SkeletonAnimation>();
            skeletonAnimation.skeletonDataAsset = skeletonDataAsset;
            skeletonAnimation.Initialize(true);
            skeletonAnimation.state.SetAnimation(0, action, true);

            if (!string.IsNullOrEmpty(currentSkingName)) {
                if (skeletonAnimation.skeleton.Data.FindSkin(currentSkingName) != null) {
                    skeletonAnimation.skeleton.SetSkin(currentSkingName);
                }
            }

            if (skeletonAnimation != null && skeletonAnimation.skeleton != null) {
                skeletonAnimation.skeleton.FlipX = _flip;
            }

            watchEvent();

            Play(actions);

            UpdateSkeletonTransform(mode, scale);

            if (skeletonAnimation != null && skeletonAnimation.skeleton != null) {
                skeletonAnimation.skeleton.SetColor(this.color);
            }

            if (sortingOrder > 0) {
                spineObject.GetComponent<MeshRenderer>().sortingOrder = sortingOrder;
            }
        }

        void stopWatch() {
            if (skeletonAnimation == null || skeletonAnimation.state == null) {
                return;
            }

            skeletonAnimation.state.Event += OnSpineEvent;
        }

        void watchEvent() {
            if (skeletonAnimation == null || skeletonAnimation.state == null) {
                return;
            }

            skeletonAnimation.state.Event += OnSpineEvent;
        }

        void OnDestroy() {
            stopWatch();
        }

        void OnSpineEvent(TrackEntry trackEntry, Spine.Event e) {
            if (onSpineEvent == null) {
                defaultSpineEvent(e.Data.Name, e.String, e.Int, e.Float);
            } else {
                onSpineEvent(e.Data.Name, e.String, e.Int, e.Float);
            }
        }

        void defaultSpineEvent(string eventName, string strValue, int intValue, float floatValue) {
            if (eventName == "u3d_effect") {
                string [] array = strValue.Split('@');
                string bone = "hitpoint", effect = null;
                if (array.Length >= 1) {
                    effect = array[0];
                } 

                if (array.Length >= 2) {
                    bone = array[1];
                }

                if (!string.IsNullOrEmpty(effect)) {
                    GameObject prefab = SGK.ResourcesManager.Load<GameObject>(string.Format("prefabs/effect/{0}.prefab", effect));
                    GameObject go = Instantiate(prefab);
                    AddEffectToSlot(bone, go);
                    Destroy(go, floatValue <= 0 ? 5 : floatValue);
                }
            }
        }

        public virtual void Play(params string[] actions) {
            if (skeletonAnimation == null) {
                this.actions = actions;
                return;
            }

            try {
                for (int i = 0; i < actions.Length; i++) {
                    bool loop = (i == (actions.Length - 1));
                    if (i == 0) {
                        skeletonAnimation.state.SetAnimation(0, actions[i], loop);
                    } else {
                        skeletonAnimation.state.AddAnimation(0, actions[i], loop, 0);
                    }
                }
            } catch (System.Exception e) {
                Debug.Log(e);
            }
        }

        public static Vector3 GetSkeletonBonePosition(SkeletonAnimation skeletonAnimation, string name) {
            if (skeletonAnimation != null) {
                Spine.Bone bone = skeletonAnimation.skeleton.FindBone(name);
                if (bone != null) {
                    return new Vector3(bone.WorldX, bone.WorldY, 0);
                }
            }
            return Vector3.zero;
        }
		public static Vector3 GetskeletonGraphicBonePosition(SkeletonGraphic skeletonGraphic, string name) {
			if (skeletonGraphic != null && skeletonGraphic.Skeleton != null) {
				Spine.Bone bone = skeletonGraphic.Skeleton.FindBone (name);
				if (bone != null) {
					return new Vector3(bone.WorldX, bone.WorldY, 0);
				}
			}
			return Vector3.zero;
		}
        public virtual Vector3 GetPosition(string name) {
            if (skeletonAnimation != null) {
                // TODO: check range
                Spine.Bone bone = skeletonAnimation.skeleton.FindBone(name);
                if (bone != null) {
                    Vector3 pos = new Vector3(bone.WorldX, bone.WorldY, 0);
                    return spineObject.transform.TransformPoint(pos);
                }

            }

            Vector3 spos;
            if (GetSpecialPosition(name, out spos)) {
                return spos;
            }

            return gameObject.transform.TransformPoint(new Vector3(0, 1, 0));
        }

        public virtual Vector3 GetBoneScale(string name) {
            if (skeletonAnimation != null) {
                // TODO: check range
                Spine.Bone bone = skeletonAnimation.skeleton.FindBone(name);
                if (bone != null) {
                    if (bone.ScaleX == bone.ScaleY) {
                        return new Vector3(bone.ScaleX, bone.ScaleY, bone.ScaleX);
                    } else {
                        return new Vector3(bone.ScaleX, bone.ScaleY, 1);
                    }
                }
            }
            return Vector3.one;
        }

        Dictionary<string, Dictionary<int, GameObject> > effectSlot = new Dictionary<string,  Dictionary<int, GameObject> >();
        public Transform GetEffectSlot(string name, int type = 0) {
            Dictionary<int, GameObject> objs;
            if (!effectSlot.TryGetValue(name, out objs)) {
                objs = new Dictionary<int, GameObject>();
                effectSlot[name] = objs;
            }

            GameObject obj;
            if (objs.TryGetValue(type, out obj)) {
                return obj.transform;
            }

            obj = new GameObject();
            obj.transform.parent = gameObject.transform;
            obj.transform.localScale = Vector3.one;
            obj.transform.localRotation = Quaternion.identity;
            obj.transform.position = GetPosition(name);
            obj.name = name + "@" + type.ToString();

            objs[type] = obj;

            return obj.transform;
        }

        public void SetEffectActive(int type, bool active) {
            foreach(KeyValuePair<string, Dictionary<int, GameObject> > entry in effectSlot) {
                GameObject obj;
                if (entry.Value.TryGetValue(type, out obj)) {
                    obj.SetActive(active);
                }
            }
        }

        protected virtual void Update() {
            Dictionary<string, Dictionary<int, GameObject>>.Enumerator enumerator = effectSlot.GetEnumerator();
            while (enumerator.MoveNext()) {
                Vector3 pos = GetPosition(enumerator.Current.Key);
                Vector3 scale = GetBoneScale(enumerator.Current.Key);
                Dictionary<int, GameObject>.Enumerator e2 = enumerator.Current.Value.GetEnumerator();
                while (e2.MoveNext()) {
                    e2.Current.Value.transform.position = pos;
                    e2.Current.Value.transform.localScale = scale;
                }
            }

            if (colorDuration > 0) {
                colorDuration -= Time.deltaTime;
                if (colorDuration <= 0) {
                    this.color.r = this.color.g = this.color.b = 1;
                    if (skeletonAnimation != null && skeletonAnimation.skeleton != null) {
                        skeletonAnimation.skeleton.SetColor(this.color);
                    }
                }
            }
        }

        public void AddEffectToSlot(string name, GameObject effect) {
            AddEffectToSlot(name, effect, Vector3.zero);
        }

        public void AddEffectToSlot(string name, GameObject effect, Vector3 offset) {
            effect.transform.parent = GetEffectSlot(name);
            effect.transform.localPosition = offset;
        }

        public void AddEffectToSlot(string name, GameObject effect, int type) {
            AddEffectToSlot(name, effect, Vector3.zero, type);
        }

        public void AddEffectToSlot(string name, GameObject effect, Vector3 offset, int type) {
            effect.transform.parent = GetEffectSlot(name, type);
            effect.transform.localPosition = offset;
        }

        protected virtual bool GetSpecialPosition(string name, out Vector3 pos ) {
            pos = Vector3.zero;
            return false;
        }

        public virtual void UpdateSkeletonTransform(string mode, float scale) {

        }

        public virtual void OnFlipChanged() {

        }

        #endregion

        #region visualization
        public virtual void Active(bool active = true, int param = 0) {
            Debug.LogWarning("BattlefieldObject.Active");
        }

        public virtual void ShowWarning(int type) {
            Debug.LogWarning("BattlefieldObject.Warning");
        }

        public virtual void SetQualityColor(Color color) {
            
        }
        #endregion

        #region ui
        public virtual void ShowUI(bool show = true) {
            Debug.LogWarning("BattlefieldObject.ShowUI");
        }

        public virtual void UpdateProperty(float hp, float hpp, float mp, float mpp, float shield = 0) {
            Debug.LogWarning("BattlefieldObject.UpdateProperty");
        }
        #endregion

        #region buff
        public virtual void AddBuff(int uuid, string icon) {
            Debug.LogWarning("BattlefieldObject.AddBuff");
        }

        public virtual void RemoveBuff(int uuid) {
            Debug.LogWarning("BattlefieldObject.RemoveBuff");
        }
        #endregion

        #region pet
        public virtual void AddPet(int uuid, GameObject obj) {
            Debug.LogWarning("BattlefieldObject.AddPet");
        }

        public virtual void RemovePet(int uuid) {
            Debug.LogWarning("BattlefieldObject.RemovePet");
        }

        public virtual void UpdatePetPosition() {
            Debug.LogWarning("BattlefieldObject.UpdatePetPosition");
        }
             
        #endregion
    }
}
