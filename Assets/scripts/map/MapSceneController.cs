using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.AI;
namespace SGK {
    public class MapSceneController : MonoBehaviour {
        public MapPlayerCamera [] _playerCameras;
        int selectedCamera = 0;

        public MapPlayerCamera playerCamera {
            get {
                return _playerCameras[selectedCamera];
            }
        }

        public Camera UICamera = null;
        public MapPlayer playerPrefab = null;
        public GameObject _playerPrefabobj = null;

        public System.Action<Vector3, GameObject> onClick;

        public int mapId = 1;

        public int mapType = 2;

        long controlled_id = 0;

        MapPlayer self_player = null;

        Dictionary<long, MapPlayer> players = new Dictionary<long, MapPlayer>();

        public void ControllPlayer(long id) {
            controlled_id = id;
            MapPlayer player = Get(id);
            if (player != null) {
                playerCamera.target = player.transform;
            }
        }

        public MapPlayer Get(long id) {
            MapPlayer player;
            if (players.TryGetValue(id, out player)) {
                return player;
            }
            return null;
        }

        public MapPlayer Add(long id) {
            MapPlayer player;
            if (players.TryGetValue(id, out player)) {
                return player;
            }

            if (playerPrefabobj == null) {
                return null;
            }

            var obj = Instantiate<GameObject>(playerPrefabobj, transform);
            player = obj.GetComponent<MapPlayer>();
            if (player == null) {
                return null;
            }
        
            players[id] = player;
            player.id = id;
            player.gameObject.SetActive(true);

            if (id == controlled_id) {
                self_player = player;
                if (playerCamera != null) {
                    playerCamera.target = player.gameObject.transform;
                }
            }
            return player;
        }
		public MapPlayer AddMember(long id,GameObject parent){
			MapPlayer player = Add (id);
			if (player.enabled){
				//float x = parent.transform.localPosition.x + 0.5f;
				//player.gameObject.transform.localPosition = new Vector3(x,parent.transform.localPosition.y,parent.transform.localPosition.z);
				player.GetComponent<NavMeshAgent> ().enabled = false;
				// player.enabled = false;
			}
			FollowMovement3d Fol = player.gameObject.GetComponent<FollowMovement3d> ();
			if (!Fol) {
				Fol = player.gameObject.AddComponent<FollowMovement3d> ();
			} else {
				Fol.enabled = true;
			}
			Fol.TargetTF = parent.transform;
			return player;
		}
        public void Remove(long id) {
            MapPlayer player;
            if (!players.TryGetValue(id, out player)) {
                return;
            }

            players.Remove(id);

            if (id == controlled_id) {
                self_player = null;
                if (playerCamera != null) {
                    playerCamera.target = null;
                }
            }

            Destroy(player.gameObject);
        }

        public void MoveTo(long id, Vector3 pos, bool warp = false) {
            MapPlayer player;
            if (players.TryGetValue(id, out player)) {
                player.MoveTo(pos, warp);
            }
        }

        public void MoveTo(long id, float x, float y, float z, bool warp = false) {
            MapPlayer player;
            if (players.TryGetValue(id, out player)) {
                player.MoveTo(x, y, z, warp);
            }
        }

        public void OnGroundClick(BaseEventData data) {
            if (self_player != null) {
                PointerEventData pData = (PointerEventData)data;
                Vector3 pos = pData.pointerCurrentRaycast.worldPosition;
                pos = self_player.MoveTo(pos);
                LuaController.DispatchEvent("NAV_PLAYER_MOVE", pos.x, pos.y, pos.z);
            }
        }

        public void OnInteractableClick(GameObject interactable) {
            OnInteractableClick(interactable, null);
        }

        public void OnInteractableClick(GameObject interactable, System.Action callback) {
            if (self_player != null) {
                Vector3 pos = self_player.Interact(interactable, callback);
                LuaController.DispatchEvent("NAV_PLAYER_MOVE", pos.x, pos.y, pos.z);
            }
        }

        public void OnInteractableClick(string  gameObjectName, System.Action callback) {
            GameObject obj = UnityEngine.GameObject.Find(gameObjectName);
            if (obj != null) {
                OnInteractableClick(obj, callback);
            }
        }

        static T CheckComponent<T>(GameObject obj)  where T : Behaviour {
            T t = obj.GetComponent<T>();
            if (t == null) {
                t = obj.AddComponent<T>();
            }
            return t;
        }

        public void SelectCamera(string name) {
            for (int i = 0; i < _playerCameras.Length; i++) {
                if (_playerCameras[i] != null && _playerCameras[i].gameObject.name == name) {
                    SelectCamera(i);
                }
            }
        }

        public void SelectCamera(int index) {
            if (index < 0 || index >= _playerCameras.Length || _playerCameras[index] == null) {
                return;
            }

            Transform target = playerCamera.target;
            playerCamera.gameObject.SetActive(false);

            selectedCamera = index;

            if (playerCamera == null) {
                return;
            }

            playerCamera.target = target;
            playerCamera.gameObject.SetActive(true);

            CameraClickEventListener listener = playerCamera.gameObject.GetComponent<CameraClickEventListener>();
            if (listener != null) {
                listener.onClick = onCameraClick;
            }
        }

        public void ResetCamera() {
            playerCamera.UpdatePositionWithSpeed(0);
        }

        void Start() {
            if (playerCamera != null) {
                CameraClickEventListener listener = playerCamera.gameObject.GetComponent<CameraClickEventListener>();
                if (listener != null) {
                    listener.onClick = onCameraClick;
                }
            }
    
#if UNITY_EDITOR
            GameObject [] objs =  GameObject.FindGameObjectsWithTag("EditorOnly");
            foreach(GameObject obj in objs) {
                obj.SetActive(false);
            }
#endif
        }
        public GameObject playerPrefabobj
        {
            get
            {
                if (_playerPrefabobj == null)
                {
                    _playerPrefabobj = SGK.ResourcesManager.Load("prefabs/base/CharacterPrefab.prefab") as GameObject;
                }
                return _playerPrefabobj;
            }
        }
        void onCameraClick(Vector3 pos, GameObject obj) {
            if (onClick != null) {
                onClick(pos, obj);
            }
        }

        [ContextMenu("switch")]
        public void SwitchCamera() {
            SelectCamera( (selectedCamera + 1) % _playerCameras.Length);
        }

        private void OnDestroy() {
            onClick = null;
        }
    }
}
