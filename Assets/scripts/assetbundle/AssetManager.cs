using AssetBundles;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.Threading;

public class AssetManager
{
#region static const value

    public static string RootPath = "Assets/assetbundle";
    public const string simulatemode = "AssetManagerSimulateInEditor";
    public const string simulatelua = "AssetManagerSimulateLuaInEditor";
    public static int mSimulateMode = -1;
    public static int mSimulateLua = -1;

    public static bool unloadAll = true;

    public static int MemoryThreshold = 1000;

    public static bool SimulateMode
    {
#if UNITY_EDITOR
        get
        {
            if (mSimulateMode == -1)
                mSimulateMode = UnityEditor.EditorPrefs.GetBool(simulatemode, true) ? 1 : 0;

            return mSimulateMode != 0;
        }
        set
        {
            int newValue = value ? 1 : 0;
            if (newValue != mSimulateMode)
            {
                mSimulateMode = newValue;
                UnityEditor.EditorPrefs.SetBool(simulatemode, value);
            }
        }
#else
        get
        {
            return false;
        }
        set
        {
            
        }
#endif
    }

    public static bool SimulateLua
    {
#if UNITY_EDITOR
        get
        {
            if (mSimulateLua == -1)
                mSimulateLua = UnityEditor.EditorPrefs.GetBool(simulatelua, true) ? 1 : 0;

            return mSimulateLua != 0;
        }
        set
        {
            int newValue = value ? 1 : 0;
            if (newValue != mSimulateLua)
            {
                mSimulateLua = newValue;
                UnityEditor.EditorPrefs.SetBool(simulatelua, value);
            }
        }
#else
        get
        {
            return false;
        }
        set
        {
            
        }
#endif
    }

    static HashSet<string> mCommonAssets = new HashSet<string>();
    static HashSet<string> mSignleAssets = new HashSet<string>();
    static HashSet<string> mAssetsBundleWithDeps = new HashSet<string>();
    static Dictionary<string, Bundle> mAssetBundles = new Dictionary<string, Bundle>();
    
    static AssetBundleManifest mManifest;
    static Bundle mMainBundle;
    #endregion

    public class LoadingSceneAsync: CustomYieldInstruction
    {
        public bool completed = false;

        public override bool keepWaiting
        {
            get
            {
                return !completed;
            }
        }

        public LoadingSceneAsync()
        {
          
        }
    }
    
    public static IEnumerator CheckMemoryThread()
    {
        while(true)
        {
            int memory = OSTools.GetCurrentMemory();
            if (memory > MemoryThreshold * 0.9)
            {
                foreach (var db in mSignleAssets)
                {
                    Bundle b = null;
                    if (mAssetBundles.TryGetValue(db, out b))
                    {
                        b.Unload(false);
                        mAssetBundles.Remove(db);
                    }
                }
            }
            Debug.Log(string.Format("CheckMemoryThread memory {0}, {1}, {2}", memory, mSignleAssets.Count, mAssetBundles.Count));
            yield return new WaitForSeconds(300);
        }

    }
    static bool CheckCommonAssets(string b)
    {
        return mCommonAssets.Contains(b);
    }
    
    public static void Init()
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            BundleInfoManager.Init();
        }else
#endif
        {
            mMainBundle = BundleManager.LoadAssetBundle(Utility.GetPlatformName());
            mManifest = mMainBundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
            BundleInfoManager.Init();

            var bds = mManifest.GetAllAssetBundles();
            foreach (var bd in bds)
            {
                if (bd.IndexOf("common/") >= 0)
                {
                    mCommonAssets.Add(bd);
                    string[] deps = mManifest.GetAllDependencies(bd);
                    if (deps != null && deps.Length > 0)
                    {
                        for (int k = 0; k < deps.Length; ++k)
                        {
                            mCommonAssets.Add(deps[k]);
                        }
                    }
                }
                else
                {
                    string[] deps = mManifest.GetAllDependencies(bd);
                    if (deps.Length == 0)
                    {
                        mSignleAssets.Add(bd);
                    }
                }
            }
        }

        foreach (var bd in mCommonAssets)
        {
            LoadAssetBundle(bd);
        }

        UnityEngine.SceneManagement.SceneManager.sceneLoaded += (Scene scene, LoadSceneMode mode) => {
            Debug.Log("SceneManager sceneLoaded:" + scene.name);
            Bundle.StartAsyncOperator();
        };
    }

    public static void Clear()
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            return;
        }
#endif
        foreach (var b in mAssetBundles)
        {
            b.Value.Unload(unloadAll);
        }
        mAssetBundles.Clear();
        mAssetsBundleWithDeps.Clear();
        mCommonAssets.Clear();
        
        mManifest = null;
        if (mMainBundle != null)
        {
            mMainBundle.Unload(unloadAll);
            mMainBundle = null;
        }
        BundleManager.Clear();
    }

    public static AsyncOperation UnloadAll(bool all = true)
    {
        List<Bundle> bs = new List<Bundle>();
        foreach (var b in mAssetBundles)
        {
            if (!CheckCommonAssets(b.Key))
            {
                b.Value.Unload(all);
            }
            else
            {
                bs.Add(b.Value);
            }
        }

        mAssetBundles.Clear();
        mAssetsBundleWithDeps.Clear();

        foreach (var b in bs)
        {
            mAssetBundles.Add(b.Asset.name, b);
        }

        BundleManager.Clear();

        return Resources.UnloadUnusedAssets();
    }
  
    /*  
    public static void LoadScene(string name)
    {
        Debug.Log("SceneManager LoadScene:" + name);
#if UNITY_EDITOR
        if (SimulateMode)
        {
            return;
        }
#endif
        string ab = BundleInfoManager.GetBundleNameWithFullPath(name + ".unity");
        if (ab != null)
        {
            LoadAssetBundle(ab);
        }
    }
    */

    public static LoadingSceneAsync LoadScene(string name)
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            return null;
        }
#endif
        string ab = BundleInfoManager.GetBundleNameWithFullPath(name + ".unity");
        LoadingSceneAsync async = null;
        if (ab != null)
        {
            async = new LoadingSceneAsync();
            LoadAssetBundle(ab, true, (Bundle b)=> {
                async.completed = true;
            });
        }

        return async;
    }


#region load asset bundle

    static void LoadAssetBundleDeped(string name, System.Action<bool> cb)
    {
        if (mAssetsBundleWithDeps.Contains(name))
        {
            cb(true);
            return;
        }

        string[] deps = mManifest.GetAllDependencies(name);
        if (deps != null && deps.Length > 0)
        {
            int count = 0;
            bool ret = true;
            for (int i = 0; i < deps.Length; ++i)
            {
                LoadAssetBundle(deps[i], (Bundle b)=> {
                    if (ret)
                    {
                        ret = b != null;
                    }

                    if( ++count == deps.Length )
                    {
                        cb(ret);
                    }
                });
            }
        }else
        {
            cb(true);
        }
        mAssetsBundleWithDeps.Add(name);
    }

    static Bundle LoadAssetBundle(string name, System.Action<Bundle> cb)
    {
        Bundle bundle = null;
        if (mAssetBundles.TryGetValue(name, out bundle))
        {
            cb(bundle);
            return bundle;
        }
        
        return BundleManager.LoadAssetBundle(name, (Bundle b) => {
            if (b == null)
            {
                Debug.LogErrorFormat("load asset bundle failed! asset bundle '{0}'", name);
            }else
            {
                if (!mAssetBundles.ContainsKey(name))
                {
                    mAssetBundles.Add(name, b);
                }
            }
            cb(b);
        });
    }

    public static Bundle LoadAssetBundle(string name, bool force = true)
    {
        if (force)
        {
            LoadAssetBundleDeped(name, (bool compeleted) =>{ });
        }

        return LoadAssetBundle(name, (b) => { });
    }

    public static void LoadAssetBundle(string name, bool force, System.Action<Bundle> callback)
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            if (BundleInfoManager.CheckContainBundle(name))
            {
                return ;
            }
            else
            {
                Debug.LogErrorFormat("load asset bundle failed! asset bundle '{0}'", name);
                return ;
            }
        }
#endif
        bool loadDepenedcompeleted = force == false;
        bool loadBundlecompeleted = false;
        Bundle bundle = null;

        System.Action cb = () => {
            if (loadDepenedcompeleted && loadBundlecompeleted)
            {
                callback(bundle);
            }
        };

        if (force)
        {
            LoadAssetBundleDeped(name, (bool completed) =>
            {
                loadDepenedcompeleted = true;
                cb();
            });
        }

        LoadAssetBundle(name, (Bundle b) => {
            loadBundlecompeleted = true;
            bundle = b;
            cb();
        });
    }

#endregion

#region unload asset bundle
    public static void UnloadAssetBundle(string name, bool all, bool force = true)
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            if (!BundleInfoManager.CheckContainBundle(name))
            {
                Debug.LogWarningFormat("unload asset bundle failed! asset bundle '{0}'", name);
                return;
            }
        }
#endif
        Bundle b;
        
        if (CheckCommonAssets(name) ||!mAssetBundles.TryGetValue(name, out b))
        {
            return;
        }

        if (b.Unload(all))
        {
            mAssetBundles.Remove(name);
        }

        if (!force)
        {
            return;
        }

        string[] deps = mManifest.GetDirectDependencies(name);
        if (deps != null && deps.Length > 0)
        {
            for (int i = 0; i < deps.Length; ++i)
            {
                UnloadAssetBundle(deps[i], all, false);
            }
        }
    }

#endregion

#region load function
    // Assets/assetbundle/ + path
    public static T Load<T>(string path) where T : Object
    {
        Debug.Assert(!string.IsNullOrEmpty(path), string.Format("asset manager load fail!, path {0}, name {0}", path));

        T obj = null;
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            return obj;
        }

#if UNITY_EDITOR
        if (SimulateMode)
        {
//             if (!LoadAssetBundle(ab))
//             {
//                 return null;
//             }
            return UnityEditor.AssetDatabase.LoadAssetAtPath<T>(path);
        }
#endif
        Bundle b = LoadAssetBundle(ab);
        if (b == null)
        {
            return obj;
        }
        obj = b.LoadAsset<T>(path);

        return obj;
    }

    public static Object Load(string name)
    {
        return Load<Object>(name);
    }

    public static Object Load(string path, System.Type type)
    {
        Debug.Assert(!string.IsNullOrEmpty(path), string.Format("asset manager load fail!, path {0}, name {0}", path));
        Object obj = null;
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            return obj;
        }
#if UNITY_EDITOR
        if (SimulateMode)
        {
//             if (!LoadAssetBundle(ab))
//             {
//                 return null;
//             }

            return UnityEditor.AssetDatabase.LoadAssetAtPath(path, type);
        }
#endif
        Bundle b = LoadAssetBundle(ab);
        if (b == null)
        {
            return obj;
        }

        obj = b.LoadAsset(path, type);
        return obj;
    }

    public static void LoadAsync(MonoBehaviour mb, string path, System.Action<Object> callback)
    {
        LoadAsync(mb, path, typeof(Object), callback);
    }

    public static void LoadAsync(MonoBehaviour mb, string path, System.Type type, System.Action<Object> callback)
    {
#if UNITY_EDITOR
        if (SimulateMode)
        {
            callback(Load(path, type));
            return;
        }
#endif
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            if (callback != null)
            {
                callback(null);
            }
            return;
        }
        
        LoadAssetBundle(ab, true, (Bundle b) =>
        {
            if (b != null && mb != null)
            {
                b.LoadAssetAsync(mb, path, type, callback);
            }
            else
            {
                callback(null);
            }
        });
    }

    public static Sprite LoadSpriteMultiple(string path, string sub)
    {
        string ab = BundleInfoManager.GetBundleNameWithFullPath(path);
        if (string.IsNullOrEmpty(ab))
        {
            return null;
        }
#if UNITY_EDITOR
        if (SimulateMode)
        {
            Object[] objs = UnityEditor.AssetDatabase.LoadAllAssetsAtPath(path);
            for (int i = 0; i < objs.Length; ++ i)
            {
                if (objs[i].name == sub)
                {
                    return objs[i] as Sprite;
                }
            }
            return null;
        }
#endif
        Object obj = null;
        Bundle b = LoadAssetBundle(ab);
        if (b == null)
        {
            return null;
        }

        obj = mAssetBundles[ab].LoadAssetWithSubAssets(path, sub);

        if (obj == null)
        {
            Debug.LogWarningFormat("load asset failed! '{0}'", path);
            return null;
        }
       
        return obj as Sprite;
    }

    public static T LoadAssetWithBundle<T>(string ab, string name) where T : Object
    {
        Debug.Assert(ab != null && name != null, string.Format("asset manager load fail!, path {0}, name {0}", ab, name));
#if UNITY_EDITOR
        if (SimulateMode)
        {
//             if (!LoadAssetBundle(ab))
//             {
//                 return null;
//             }
            return UnityEditor.AssetDatabase.LoadAssetAtPath<T>(name);
        }
#endif
        T obj = null;
        Bundle b = LoadAssetBundle(ab, false);
        if (b == null)
        {
            return obj;
        }
        obj = b.LoadAsset<T>(name);

        return obj;
    }
#endregion
}
