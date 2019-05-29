using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace SGK {
	public class MapInteractableGameObject : MonoBehaviour, MapInteractableObject {
        public UnityEvent _onInteract;
        public System.Action onInteract;

		public void Interact(GameObject obj) {
            if (_onInteract != null) {
                _onInteract.Invoke();
            }

            if (onInteract != null) {
                onInteract();
            }
        }

        private void OnDestroy() {
            onInteract = null;
        }

        public static MapInteractableGameObject Get(GameObject obj) {
            MapInteractableGameObject mi = obj.GetComponent<MapInteractableGameObject>();
            if (mi == null) {
                mi = obj.AddComponent<MapInteractableGameObject>();
            }
            return mi;
        }
	}
}