using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[XLua.LuaCallCSharp]
public class GameObjectPool : MonoBehaviour {
    public GameObject prefab;
    public int count;

    public int lowWater = 0;
    public int highWater = 0;

    static Dictionary<string, GameObjectPool> pools = new Dictionary<string, GameObjectPool>();
    public static GameObjectPool GetPool(string name) {
        GameObjectPool pool;
        if (pools.TryGetValue(name, out pool)) {
            return pool;
        }
        return null;
    }

    private void Start() {
        pools[this.gameObject.name] = this;
        Prepare(count);

        // TODO: 
        if (GetComponent<DontDestroy>()) {
            // AssetManager.MarkCommonResource(prefab);
        }
    }

    private void Update() {
        if (lowWater > 0 && caches.Count < lowWater) {
            GameObject o = Instantiate(prefab, transform);
            o.SetActive(false);
            caches.Enqueue(o);
        }

        if (highWater < lowWater) {
            highWater = lowWater;
        }

        if (highWater > 0 && caches.Count > highWater) {
            GameObject.Destroy(caches.Dequeue());
        }
    }

    private void OnDestroy() {
        pools.Remove(this.gameObject.name);
    }

    Queue <GameObject> caches = new Queue<GameObject>();
    public void Prepare(int count = 1) {
        for (int i = 0; i < count; i ++) {
            caches.Enqueue(Instantiate(prefab, transform));
        }
    }

    public GameObject Get(Transform parent = null) {
        if (caches.Count > 0) {
            GameObject o = caches.Dequeue();
            if (parent != null) {
                o.transform.SetParent(parent, false);
            }
            return o;
        } else {
            return Instantiate(prefab, (parent == null) ? transform : parent);
        }
    }

    public void Release(GameObject o) {
        o.SetActive(false);
        o.transform.SetParent(transform, false);
        GameObjectPoolItem rl = o.GetComponent<GameObjectPoolItem>();
        if (rl != null) {
            rl.Release();
        }
        caches.Enqueue(o);
    }
}
