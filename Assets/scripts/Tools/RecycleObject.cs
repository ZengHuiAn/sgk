using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class GameObjectPool
    {
        string path;
        GameObject prefab;

        List<GameObject> caches = new List<GameObject>();

        public GameObjectPool(string path = null, GameObject prefab = null) {
            this.path = path;
            this.prefab = prefab;
        }

        public void Clear() {
            for (int i = 0; i < caches.Count; i++) {
                GameObject.Destroy(caches[i]);
            }
            caches.Clear();
        }

        public GameObject Create() {
            if (prefab == null) {
                if (!string.IsNullOrEmpty(path)) {
                    prefab = SGK.ResourcesManager.Load<GameObject>(path);
                }
            }

            if (prefab == null) {
                return null;
            }
            return GameObject.Instantiate(prefab);
        }

        GameObject Attach(GameObject obj, float delay = -1) {
            if (obj == null) {
                return null;
            }

            RecycleObject rc = obj.GetComponent<RecycleObject>();
            if (rc == null) {
                rc = obj.AddComponent<RecycleObject>();
            }
            rc.releaseAfter = delay;
            rc.pool = this;
            return obj;
        }

        public GameObject Get(float delay = -1) {
            GameObject obj = null;
            if (caches.Count == 0) {
                obj = Create();
            } else {
                obj = caches[0];
                caches.RemoveAt(0);
            }

            return Attach(obj);
        }

        public GameObject [] Prepare(int n = 0) {
            if (n <= 0) {
                return null;
            }

            List<GameObject> list = new List<GameObject>();
            while (caches.Count < n) {
                GameObject obj = Create();
                if (obj == null) {
                    return null;
                }

                Attach(obj).SetActive(false);
                caches.Add(obj);
                list.Add(obj);
            }
            return list.ToArray();
        }

        public void Release(GameObject obj) {
            RectTransform rt = obj.GetComponent<RectTransform>();
            if (rt != null) {
                rt.SetParent(null);
            } else {
                obj.transform.parent = null;
            }
            obj.SetActive(false);
            caches.Add(obj);
        }

        public void Remove(GameObject obj) {
            caches.Remove(obj);
        }
    }

    public class GameObjectPoolManager
    {
        Dictionary<string, GameObjectPool> caches = new Dictionary<string, GameObjectPool>();

        GameObjectPool GetPool(string path = null) {
            if (string.IsNullOrEmpty(path)) {
                return null;
            }

            GameObjectPool pool;
            if (!caches.TryGetValue(path, out pool)) {
                pool = new GameObjectPool(path);
                caches[path] = pool;
            }
            return pool;
        }

        public GameObject Get(string path, float delay = -1) {
            GameObjectPool pool = GetPool(path);
            if (pool == null) {
                return null;
            }

            GameObject obj = pool.Get(delay);
            if (obj == null) {
                return null;
            }

            return obj;
        }

        public void Prepare(string path, int n = 1) {
            GameObjectPool pool = GetPool(path);
            if (pool == null) {
                return;
            }
            pool.Prepare(n);
        }

        public void Prepare(string path, GameObject prefab, int n = 1) {
            GameObjectPool pool;
            if (!caches.TryGetValue(path, out pool)) {
                pool = new GameObjectPool(path, prefab);
                caches[path] = pool;
            }
            pool.Prepare(n);
        }

        public void Clear() {
            foreach(var kv in caches) {
                kv.Value.Clear();
            }
            caches.Clear();
        }

        public void Release(GameObject obj, float delay = 0) {
            RecycleObject rc = obj.GetComponent<RecycleObject>();
            if (delay <= 0) {
                if (rc == null) {
                    GameObject.Destroy(obj);
                } else {
                    rc.Release();
                }
            } else {
                if (rc == null) rc = obj.AddComponent<RecycleObject>();
                rc.releaseAfter = delay;
            }
        }

        static GameObjectPoolManager _instance = null;
        public static GameObjectPoolManager getInstance() {
            if (_instance == null) {
                _instance = new GameObjectPoolManager();
            }
            return _instance;
        }
    }

    public class RecycleObject : MonoBehaviour
    {
        public float releaseAfter = -1.0f;
        public GameObjectPool pool = null;

        void Start() {

        }

        // Update is called once per frame
        void Update() {
            if (releaseAfter < 0) {
                return;
            }

            releaseAfter -= Time.deltaTime;

            if (releaseAfter < 0) {
                Release();
            }
        }

        public void Release() {
            releaseAfter = -1;

            if (pool == null) {
                Destroy(gameObject);
            } else {
                pool.Release(gameObject);
            }
        }

        void OnDestroy() {
            if (pool != null) {
                pool.Remove(gameObject);
            }
        }
    }
}