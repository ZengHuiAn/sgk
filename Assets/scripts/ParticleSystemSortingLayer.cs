using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class ParticleSystemSortingLayer : MonoBehaviour {
        public string sortingLayerName = "Default";
        public int sortingOrder = 0;
        public bool ignoreSortOrder = false;

        [ContextMenu("Exec")]
        void Start() {
            if (ignoreSortOrder) {
                return;
            }

            ParticleSystem[] ps = GetComponentsInChildren<ParticleSystem>();
            foreach (ParticleSystem p in ps) {
                p.GetComponent<Renderer>().sortingLayerName = sortingLayerName;
                p.GetComponent<Renderer>().sortingOrder = sortingOrder;
            }
        }

        public static void Set(GameObject obj, int sortingOrder, string sortingLayerName) {
            ParticleSystemSortingLayer l = obj.GetComponent<ParticleSystemSortingLayer>();
            if (l == null) {
                l = obj.AddComponent<ParticleSystemSortingLayer>();
            }
            l.sortingLayerName = sortingLayerName;
            l.sortingOrder = sortingOrder;
        }

        public static void Set(GameObject obj, int sortingOrder) {
            Set(obj, sortingOrder, "Default");
        }
    }
}