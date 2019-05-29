using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
    public class BattlefieldObjectEnemy : BattlefieldObjectWithBar {
        public Transform modeScaler;
        public Transform roleScaler;
        public Text nameText;
        public RectTransform petBar;

        public System.Action<Vector3> onTouchBegan;
        public System.Action<Vector3> onTouchEnd;
        public System.Action<Vector3> onTouchMove;
        public System.Action onTouchCancel;
        

        public void SetModeScale(Vector3 scale) {
            SetModeScale(scale, Vector3.zero);
        }

        public void SetModeScale(Vector3 scale, Vector3 position) {
            modeScaler.localPosition = position;
            modeScaler.localScale = scale;
        }

        public override void UpdateSkeletonTransform(string mode, float in_scale) {
            roleScaler.localScale = Vector3.one * in_scale;


            Vector3 center, size;
            Database.GetBattlefieldCharacterBound(mode, "battle", out center, out size);

            if (size.x > 0.01f) {
                BoxCollider boxCollider = spineObject.GetComponent<BoxCollider>();
                if (boxCollider == null) {
                    boxCollider = spineObject.AddComponent<BoxCollider>();
                }
                boxCollider.center = center;
                boxCollider.size = size;
            } else {
                MeshFilter render = spineObject.GetComponent<MeshFilter>();
                if (render != null) {
                    BoxCollider boxCollider = spineObject.GetComponent<BoxCollider>();
                    if (boxCollider == null) {
                        boxCollider = spineObject.AddComponent<BoxCollider>();
                    }
                    boxCollider.center = render.mesh.bounds.center;
                    boxCollider.size = render.mesh.bounds.size;
                }
            }

            ModelTouchEventListener listener = ModelTouchEventListener.Get(spineObject);

            listener.onTouchBegan = onEnemyTouchBegan;
            listener.onTouchEnd = onEnemyTouchEnd;
            listener.onTouchMove = onEnemyTouchMove;
            listener.onTouchCancel = onEnemyTouchCancel;
        }


        void onEnemyTouchBegan(Vector3 pos) {
            if (onTouchBegan != null) {
                onTouchBegan(pos);
            }
        }

        void onEnemyTouchEnd(Vector3 pos) {
            if (onTouchEnd != null) {
                onTouchEnd(pos);
            }
        }

        void onEnemyTouchMove(Vector3 pos) {
            if (onTouchMove != null) {
                onTouchMove(pos);
            }

        }

        void onEnemyTouchCancel() {
            if (onTouchCancel != null) {
                onTouchCancel();
            }
        }

        public override void SetName(string name) {
            if (nameText != null) {
                nameText.text = name;
            }
        }

        Dictionary<int, BattlefieldObjectPet> petList = new Dictionary<int, BattlefieldObjectPet>();
        public override void AddPet(int uuid, GameObject obj) {
            BattlefieldObjectPet pet = obj.GetComponent<BattlefieldObjectPet>();

            petList[uuid] = pet;
            obj.transform.SetParent(petBar, false);
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
            foreach (KeyValuePair<int, BattlefieldObjectPet> ite in petList) {
                Debug.AssertFormat(ite.Value != null && ite.Value.gameObject != null, "pet {0} error", ite.Key);
                RectTransform rt = ite.Value.gameObject.GetComponent<RectTransform>();
                int siblingIndex = petList.Count - rt.GetSiblingIndex() - 1;
                // rt.anchoredPosition = new Vector2(offset * siblingIndex, -20 * siblingIndex);
                rt.anchoredPosition3D = new Vector3( -offset * siblingIndex, offset * siblingIndex, 0);
                rt.localScale = Vector3.one * (1 - siblingIndex * 0.2f);
            }
            */
        }

        public override void Active(bool active = true, int param = 0) {
        }

        public override void ShowWarning(int type) {
        }

        public override void Start() {
            base.Start();
        }

        protected override void Update() {
            base.Update();
            // boxCollider.center = GetComponent<Renderer>().bounds.center;
        }

        /*
        void OnDrawGizmosSelected() {
            Renderer spineRenderer = spineObject.GetComponent<Renderer>();
            if (spineRenderer != null) { 
                Vector3 center = spineRenderer.bounds.center;
                float radius = spineRenderer.bounds.extents.magnitude;
                Gizmos.color = Color.red;
                Gizmos.DrawWireSphere(center, radius);


            }
        }
        */

        private void OnDestroy() {
            onTouchBegan = null;
            onTouchEnd = null;
            onTouchMove = null;
            onTouchCancel = null;
        }
    }
}
