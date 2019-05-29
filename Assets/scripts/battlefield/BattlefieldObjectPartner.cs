using DG.Tweening;
using Spine.Unity;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
    public class BattlefieldObjectPartner : BattlefieldObjectWithBar {
        public Transform modeScaler;
        public Transform roleScaler;
        public SpriteRenderer hitImage;
        public SpriteRenderer colorImage;
        public GameObject deadEffect;
        public GameObject deadEffect2;
        public float hitImageFadeTime = 0.5f;
        public RectTransform petBar;
        private bool ShowWarning_next_time = false;
        private int ShowWarning_next_time_type = 0;

        public MaskableGameObject clippingNode;
        MaskableSkeletonAnimation _clippingNodeSpine;

        MaskableSkeletonAnimation clippingNodeSpine {
            get {
                if (_clippingNodeSpine == null) {
                    _clippingNodeSpine = spineObject.GetComponent<MaskableSkeletonAnimation>();
                }
                return _clippingNodeSpine;
            }
        }

        public Text nameLabel;

        // public GameObject [] hideInBig = new GameObject[0];
        public Transform [] overridePoint;

        [System.Serializable]
        public struct Icon {
            public GameObject gameObject;
            public Image image;
            public BattlefieldProgressBar hpBar;
            public BattlefieldProgressBar mpBar;
        }

        public Icon icon;

        public void SetModeScale(Vector3 scale) {
            SetModeScale(scale, Vector3.zero);
        }

        public void SetModeScale(Vector3 scale, Vector3 position) {
            modeScaler.localPosition = position;
            modeScaler.localScale = scale;
        }

        public override void SetName(string name) {
            if (nameLabel != null) {
                nameLabel.text = name;
            }
        }

        public System.Action<Vector3> onTouchBegan;
        public System.Action<Vector3> onTouchEnd;
        public System.Action<Vector3> onTouchMove;
        public System.Action onTouchCancel;

        Vector3 positionFromConfig = Vector3.zero;
        public override void UpdateSkeletonTransform(string mode, float in_scale) {
            Vector3 position = Vector3.zero;
            Vector3 scale = Vector3.one;

            Database.GetBattlefieldCharacterTransform(mode, "battle", out positionFromConfig, out scale);
            position = positionFromConfig;
            if (flip) {
                position.x = -position.x;
            }

            modeScaler.localPosition = position;
            modeScaler.localScale = scale;
            roleScaler.localScale = Vector3.one * in_scale;

            spineObject.GetComponent<MeshRenderer>().sortingOrder = 2;

            clippingNodeSpine.UpdateStencil();

            ModelTouchEventListener listener = ModelTouchEventListener.Get(gameObject);

            listener.onTouchBegan = onPartnerTouchBegan;
            listener.onTouchEnd = onPartnerTouchEnd;
            listener.onTouchMove = onPartnerTouchMove;
            listener.onTouchCancel = onPartnerTouchCancel;
        }

        void onPartnerTouchBegan(Vector3 pos) {
            if (onTouchBegan != null) {
                onTouchBegan(pos);
            }
        }

        void onPartnerTouchEnd(Vector3 pos) {
            if (onTouchEnd != null) {
                onTouchEnd(pos);
            }
        }

        void onPartnerTouchMove(Vector3 pos) {
            if (onTouchMove != null) {
                onTouchMove(pos);
            }

        }

        void onPartnerTouchCancel() {
            if (onTouchCancel != null) {
                onTouchCancel();
            }
        }

        private void OnEnable() {
            GetComponent<Animator>().SetBool("half", _half);
        }

        public override void OnFlipChanged() {
            Vector3 position = positionFromConfig;
            if (flip) {
                position.x = -position.x;
            }
            modeScaler.localPosition = position;
        }

        public override Vector3 GetPosition(string name) {
            for (int i = 0; overridePoint != null && i < overridePoint.Length; i++) {
                if (overridePoint[i].gameObject.name == name) {
                    return overridePoint[i].position;
                }
            }

            if (skeletonAnimation != null && skeletonAnimation.skeleton != null) {
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

        public override void UpdateProperty(float hp, float hpp, float mp, float mpp, float shield = 0) {
            Debug.Assert(hpp > 0 ,"hpp error");
            
            base.UpdateProperty(hp, hpp, mp, mpp, shield);
            if (icon.hpBar != null) {
                icon.hpBar.SetValue((int)hp, (int)hpp, (int)shield);
            }

            if (icon.mpBar != null) {
                icon.mpBar.SetValue((int)mp, (int)mpp, 0);
            }
        }

        public override void ChangeIcon(string iconName, int level, int quality, int star) {
            if (icon.gameObject != null) {
                icon.gameObject.SetActive(true);
            }

            if (icon.image != null) {
                icon.image.LoadSprite("icon/" + iconName);
            }
        }

        public override void Active(bool active = true, int param = 0) {
            if (!gameObject.activeSelf) {
                return;
            }

            if (active) {
                Big();
            } else {
                Normal(param);
                if (ShowWarning_next_time) {
                    if (ShowWarning_next_time_type == 1) {
                        skeletonAnimation.AnimationName = "idle";
                        skeletonAnimation.Initialize(true);
                        skeletonAnimation.skeleton.FlipX = flip;
                        GetComponent<Animator>().SetBool("Dead", true);
                    }  else if (ShowWarning_next_time_type == 0) {
                        skeletonAnimation.AnimationName = "idle";
                        skeletonAnimation.Initialize(true);
                        skeletonAnimation.skeleton.FlipX = flip;
                        GetComponent<Animator>().SetBool("Dead", false);
                    } else {
                    }
                    ShowWarning_next_time = false;
                }
            }
        }

        public override void ShowWarning(int type) {
            if (running_tween == null && _status == SHOW_STATUS.NORMAL) {
                if (type == 1) {
                    skeletonAnimation.AnimationName = "idle";
                    skeletonAnimation.Initialize(true);
                    skeletonAnimation.skeleton.FlipX = flip;
                    GetComponent<Animator>().SetBool("Dead", true);
                }  else if (type == 0) {
                    skeletonAnimation.AnimationName = "idle";
                    skeletonAnimation.Initialize(true);
                    skeletonAnimation.skeleton.FlipX = flip;
                    GetComponent<Animator>().SetBool("Dead", false);
                } else {
                }
            } else { 
                ShowWarning_next_time = true ;
                ShowWarning_next_time_type = type;
            } 
        }

        public override void SetQualityColor(Color color) {
            if (colorImage != null) {
                colorImage.color = color;
            }
        }


        #region pet
        Dictionary<int, BattlefieldObjectPet> petList = new Dictionary<int, BattlefieldObjectPet>();
        public override void AddPet(int uuid, GameObject obj) {
            BattlefieldObjectPet pet = obj.GetComponent<BattlefieldObjectPet>();

            petList[uuid] = pet;
            obj.transform.SetParent(petBar, false);
            // obj.transform.localScale = Vector3.one;
            // obj.transform.localRotation = Quaternion.identity;

            UpdatePetPosition();
        }

        public override void RemovePet(int uuid) {
            BattlefieldObjectPet pet;
            if (petList.TryGetValue(uuid, out pet)) {
                petList.Remove(uuid);
                Destroy(pet.gameObject);
                UpdatePetPosition();
            }
        }

        public override void UpdatePetPosition() {
            /*
            float offset = 20;
            if (SHOW_STATUS.BIG == _status) {
                foreach (KeyValuePair<int, BattlefieldObjectPet> ite in petList) {
                    Debug.AssertFormat(ite.Value != null && ite.Value.gameObject != null, "pet {0} error", ite.Key);
                    RectTransform rt = ite.Value.gameObject.GetComponent<RectTransform>();
                    int siblingIndex = petList.Count - rt.GetSiblingIndex() - 1;
                    // rt.anchoredPosition = new Vector2(offset * siblingIndex, -20 * siblingIndex);
                    rt.anchoredPosition3D = new Vector3( -offset * siblingIndex, offset * siblingIndex, 0);
                    rt.localScale = Vector3.one * (1 - siblingIndex * 0.2f);
                }
                characterRoot.localPosition = Vector3.zero;
            } else {
                foreach (KeyValuePair<int, BattlefieldObjectPet> ite in petList) {
                    RectTransform rt = ite.Value.gameObject.GetComponent<RectTransform>();
                    int siblingIndex = petList.Count - rt.GetSiblingIndex() - 1;
                    rt.anchoredPosition3D = new Vector3( -offset * siblingIndex, offset * siblingIndex, 0);
                    rt.localScale = Vector3.one * (1 - siblingIndex * 0.2f);
                }
            }
            */
        }


        #endregion


        #region visualization

        public Transform character;
        public Transform characterRoot;

        Tween running_tween = null;
        const float _act_duration = 0.25f;

        private enum SHOW_STATUS {
            NORMAL, BIG, HIDE
        };
        private SHOW_STATUS _status = SHOW_STATUS.NORMAL;

        // private bool show_small_on_late_update = false;
        public void Normal(int offset) {
            if (offset == 0) {
                gameObject.SetActive(true);
            }

            const float grid_width = 0.765f;
            Sequence tween = DOTween.Sequence();
            if (_status == SHOW_STATUS.NORMAL) {
                tween.Join(transform.DOLocalMove(new Vector3(0 + offset * grid_width, 0, 0), _act_duration));
            } else {
                _status = SHOW_STATUS.NORMAL;
                // Vector3 targetScale = new Vector3(0.2f, 1, 1);
                tween.Join(transform.DOLocalMove(new Vector3(0 + offset * grid_width, 0, 0), _act_duration));
                // tween.Join(ui.transform.DOLocalMoveX(0, _act_duration));
                // tween.Join(ui.transform.DOScale(Vector3.one * 0.003f, _act_duration));
                // tween.Join(petBar.DOAnchorPos(new Vector2(118, -132), _act_duration));
                // tween.Join(character.transform.DOLocalMoveX(0, _act_duration));
            }

            SetEffectActive(1, false);

            GetComponent<Animator>().SetBool("Big", false);

            running_tween = tween;
            tween.OnComplete(() => {
                showSmall();
                UpdatePetPosition();
                running_tween = null;

                if (offset != 0) {
                    gameObject.transform.localPosition = new Vector3(10*offset, 0, 0);
                } else {
                    gameObject.transform.localPosition = Vector3.zero;
                }
            });
            tween.Play();
        }

        public void Big() {
            if (_status == SHOW_STATUS.BIG) {
                return;
            }
            _status = SHOW_STATUS.BIG;

            // gameObject.SetActive(true);

            float xMove = 0;
            if (transform.parent != null) {
                xMove = -transform.parent.localPosition.x;
            }

            showBig(0.2f);

            UpdatePetPosition();

            if (running_tween != null) {
                running_tween.Kill();
            }

            Sequence tween = DOTween.Sequence();
            tween.Join(transform.DOLocalMove(new Vector3(xMove, 0.1f, 0), _act_duration));
            // tween.Join(ui.transform.DOLocalMoveX(-1, _act_duration));
            // tween.Join(ui.transform.DOScale(Vector3.one * 0.005f, _act_duration));
            // tween.Join(petBar.DOAnchorPos(new Vector2(100, -250), _act_duration));
            // tween.Join(character.transform.DOLocalMoveX(-1.8f, _act_duration));

            GetComponent<Animator>().SetBool("Big", true);
            
            /*
            for (int i = 0; i < hideInBig.Length; i++) {
                hideInBig[i].SetActive(false);
            }
            */

            running_tween = tween;

            tween.OnComplete(() => {
                showBig(1.0f);
                SetEffectActive(1, true);
                running_tween = null;
            });
            tween.Play();
        }

        bool _half = false;
        public bool half {
            get { return _half;  }
            set {
                if (_half != value) {
                    _half = value;
                    if (gameObject.activeInHierarchy) {
                        GetComponent<Animator>().SetBool("half", _half);
                    }
                }
            }
        }

        int _origin_stencil = 0;
        public void ShowMask(bool show = true) {
            if (_origin_stencil == 0) {
                _origin_stencil = clippingNodeSpine.stencil;
            }

            clippingNode.enabled = show;
            clippingNodeSpine.stencil = show ? _origin_stencil : 0;
            clippingNodeSpine.UpdateStencil();
        }

        void showBig(float scale = 1.0f) {
            // clippingNode.transform.localScale = Vector3.one * 10;
        }

        void showSmall() {
            /*
            for (int i = 0; i < hideInBig.Length; i++) {
                hideInBig[i].SetActive(true);
            }
            clippingNode.transform.localScale = Vector3.one;
            */
        }
        #endregion

        private void OnDestroy() {
            onTouchBegan = null;
            onTouchEnd = null;
            onTouchMove = null;
            onTouchCancel = null;
        }
    }
}
