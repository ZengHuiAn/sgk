using UnityEngine;
using Spine.Unity;
using System.Collections.Generic;
using System.Collections;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace SGK {
    public class ResourcesManager {
        struct PatchInfo {
            public string shortName;
            public string fullName;
            public AssetBundle assetBundle;

            public PatchInfo(string fullName, AssetBundle assetBundle) {
                shortName = fullName.ToLower();
                int index = -1;

                // remove assets/patchs/x.x.x/ from path
                if (shortName.StartsWith("assets/patchs/")) {
                    // skip version
                    index = shortName.Substring(14).IndexOf('/');
                    if (index != -1) {
                        shortName = shortName.Substring(15+index);
                    }
                }

                /*
                // remove file extension
                index = shortName.LastIndexOf('.');
                if (index != -1) {
                    shortName = shortName.Substring(0, index);
                }
                */

                this.fullName = fullName;
                this.assetBundle = assetBundle;
            }
        };

        public static bool SHOW_WARNING = false;
        static HashSet<string> mUnloadAssets = new HashSet<string>();
        static Dictionary<string, PatchInfo> patchFiles = new Dictionary<string, PatchInfo>();
		public static void AddPatch(AssetBundle assetBundle) {
            string [] fileNames = assetBundle.GetAllAssetNames();
            for (int i = 0; i < fileNames.Length; i++) {
                PatchInfo info = new PatchInfo(fileNames[i], assetBundle);
                patchFiles[info.shortName] = info;
            }
		}

        public static Object LoadFromPatch(string path)
        {
            Object obj = null;
            PatchInfo info;
            if (patchFiles.TryGetValue(path.ToLower(), out info))
            {
                obj = info.assetBundle.LoadAsset<Object>(info.fullName);
            }
            return obj;
        }

        public static Object Load(string path) {
            return Load<Object>(path);
        }

        static string GetResourceName (string path) {
            string ext = System.IO.Path.GetExtension(path);
            if (string.IsNullOrEmpty(ext)) {
                return path;
            }
            return path.Substring(0, path.Length - ext.Length);
        }

        public static T Load<T>(string path) where T : Object {
            // Debug.Log("LoadAsset:" + path);
            path = AddFileExtension(path);
            string fullPath = "Assets/" + ResourceBundle.RESOURCES_DIR + "/" + path;

            Statistics.AddAsset(fullPath);

            Object asset = null;
            PatchInfo info;
            if (patchFiles.TryGetValue(path.ToLower(), out info))
            {
                return info.assetBundle.LoadAsset<T>(info.fullName);
            }
#if UNITY_EDITOR
            if (AssetManager.SimulateMode)
            {
                asset = AssetDatabase.LoadAssetAtPath<T>(fullPath);
                if (asset == null)
                {
                    asset = Resources.Load<T>(GetResourceName(path));
                }
                if (asset == null)
                {
                    Debug.LogErrorFormat("load error {0}", path);
                    return null;
                }
                return asset as T;
            }
#endif
            asset = AssetManager.Load<T>(fullPath);
            if (asset== null)
            {
                asset = Resources.Load<T>(GetResourceName(path));
            }
            if (asset == null)
            {
                Debug.LogErrorFormat("load error {0}", path);
                return null;
            }

            return asset as T;
        }

        public static Object Load(string path, System.Type type) {
            // Debug.Log("LoadAsset:" + path);
            path = AddFileExtension(path);
            string fullPath = "Assets/" + ResourceBundle.RESOURCES_DIR + "/" + path;

            Statistics.AddAsset(fullPath);

            Object asset = null;
            PatchInfo info;
            if (patchFiles.TryGetValue(path.ToLower(), out info))
            {
                return info.assetBundle.LoadAsset(info.fullName, type);
            }
#if UNITY_EDITOR
            if (AssetManager.SimulateMode)
            {
                asset = AssetDatabase.LoadAssetAtPath(fullPath, type);
                if (asset == null)
                {
                    asset = Resources.Load(GetResourceName(path), type);
                }
                if (asset == null)
                {
                    Debug.LogErrorFormat("load error {0}", path);
                }
                return asset;
            }
#endif

            asset = AssetManager.Load(fullPath, type);
            if (asset == null)
            {
                asset = Resources.Load(GetResourceName(path), type);
            }
            if (asset == null)
            {
                Debug.LogErrorFormat("load error {0}", path);
            }

            return asset;
        }

        static ResourceLoader per_scene_resources_loader = null;   
        public static void ResetLoader() {
            Debug.LogFormat("ResourcesManager:ResetLoader");
            per_scene_resources_loader = null;
        }

        // static int loader_counter = 0;
        public static ResourceLoader GetLoader() {
            if (!per_scene_resources_loader) {
                var obj = new GameObject();
                per_scene_resources_loader = obj.AddComponent<ResourceLoader>();
                per_scene_resources_loader.name = "scene_resouces_loader";
            }
            return per_scene_resources_loader;
        }

        #region unload asset
        public static void LoadUnloadAsset()
        {
            foreach (var asset in mUnloadAssets)
            {
                LoadAsync(asset);
            }
        }

        public static void AddUnLoadAsset(string asset, bool assetbundle = true)
        {
            string fullPath = "Assets/" + (assetbundle ? ResourceBundle.RESOURCES_DIR : "") + "/" + AddFileExtension(asset);
            if (mUnloadAssets.Contains(fullPath))
            {
                return;
            }

            mUnloadAssets.Add(fullPath);
        }

        public static void RemoveUnLoadAsset(string asset, bool assetbundle = true)
        {
            mUnloadAssets.Remove("Assets/" + (assetbundle ? ResourceBundle.RESOURCES_DIR : "") + "/" + AddFileExtension(asset));
        }

        public static void ClearUnLoadAssets()
        {
            mUnloadAssets.Clear();
        }

        #endregion

        public static void LoadAsync(string path, System.Action<Object> callback = null) {
            LoadAsync(GetLoader(), path, callback);
        }

        public static void LoadAsync(string path, System.Type type, System.Action<Object> callback) {
            LoadAsync(GetLoader(), path, type, callback);
        }

        public static void LoadAsync(MonoBehaviour dependObject, string path, System.Action<Object> callback = null) {
            LoadAsync(dependObject, path, typeof(Object), callback);
        }

        public static void LoadAsync(MonoBehaviour dependObject, string path, System.Type type, System.Action<Object> callback)  {
           //  Debug.Log("LoadAsset Aysnc:" + path);
            if (!patchFiles.ContainsKey(path.ToLower()))
            {
                string fullPath = path.StartsWith("Assets/") ? path : ("Assets/" + ResourceBundle.RESOURCES_DIR + "/" + AddFileExtension(path));

                Statistics.AddAsset(fullPath);

#if UNITY_EDITOR
                if (AssetManager.SimulateMode)
                {
                    GetLoader().StartCoroutine(SimulateLoadThread(path, type, callback, dependObject));
                    return;
                }
#endif
                string ab = BundleInfoManager.GetBundleNameWithFullPath(fullPath);
                if (!string.IsNullOrEmpty(ab))
                {
                    AssetManager.LoadAsync(GetLoader(), fullPath, type, callback);
                    return;
                }
            }
            GetLoader().StartCoroutine(LoadThread(path, type, callback, dependObject));
        }


#if UNITY_EDITOR
        static IEnumerator SimulateLoadThread(string path, System.Type type, System.Action<Object> callback, Object dependObject) {
            yield return null;

            if (!dependObject) {
                yield break;
            }

            string fullPath = path.StartsWith("Assets/") ? path : ("Assets/" + ResourceBundle.RESOURCES_DIR + "/" + AddFileExtension(path));

            var asset = AssetDatabase.LoadAssetAtPath(fullPath, type);
            if (asset == null) {
                asset = Resources.Load(GetResourceName(path), type);
            }
            if (asset == null) {
                Debug.LogErrorFormat("load error {0}", path);
            }

            yield return null;
            if (!dependObject) {
                yield break;
            }
            if (callback != null) {
                callback(asset);
            }
        }
#endif

        static IEnumerator LoadThread(string path, System.Type type,  System.Action<Object> callback, Object dependObject)
        {
            path = AddFileExtension(path);
            //var watch = new System.Diagnostics.Stopwatch();
            //watch.Start();
            
            Object asset = null;
            PatchInfo info;
            if (patchFiles.TryGetValue(path.ToLower(), out info))
            {
                AssetBundleRequest areq = info.assetBundle.LoadAssetAsync(info.fullName, type);
                if (areq.asset == null)
                {
                    yield return areq;
                    if (!dependObject) {
                        yield break;
                    }
                }
                asset = areq.asset;
            } else
            {
                ResourceRequest rrequest = Resources.LoadAsync(GetResourceName(path), type);
                if (rrequest != null)
                {
                    if (rrequest.asset == null)
                    {
                        yield return rrequest;
                        if (!dependObject) {
                            yield break;
                        }
                    }
                    asset = rrequest.asset;                     
                }
            }
            //watch.Stop();
           // UnityEngine.Debug.LogError(string.Format("LOAD THREAD {0}, {1}ms, {2}", path, watch.ElapsedMilliseconds, Time.deltaTime * 1000));
           // watch.Reset();
           // watch.Start();
            if (callback != null) {
                callback(asset);
            }
           // watch.Stop();
           // UnityEngine.Debug.LogError(string.Format("LOAD THREAD CALLBACK {0}, {1}ms", path, watch.ElapsedMilliseconds));
        }

        public static void UnloadUnusedAssets() {
            GetLoader();
            if (per_scene_resources_loader)
            {
                per_scene_resources_loader.StartCoroutine(UnloadThread());
            }
        }
        public static IEnumerator UnloadThread()
        {
            Debug.LogFormat("ResourcesManager.UnloadUnusedAssets");
            var op = AssetManager.UnloadAll(false);

            while (op != null && !op.isDone)
            {
                yield return null;
            }
            LuaController.Collect();
            System.GC.Collect();
            Debug.LogFormat("ResourcesManager.UnloadUnusedAssets completed");
        }

        public static void Cleanup() {
            UnloadUnusedAssets();
            patchFiles.Clear();
        }

        public static string AddFileExtension(string path) {
            if (string.IsNullOrEmpty(path)) {
                Debug.LogError("path is null");
                return path;
            }

            if (!string.IsNullOrEmpty(System.IO.Path.GetExtension(path))) {
                return path;
            }

#if UNITY_EDITOR
            throw new KeyNotFoundException();
#endif
            if (path.EndsWith("_SkeletonData")) {
                return path + ".asset";
            } else if (path.EndsWith("_Material")) {
                return path + ".mat";
            } else if (path.StartsWith("prefabs/")) {
                string [] cc = path.Split('/');
                if (cc.Length == 2) {
                    path = "prefabs/base/" + cc[1];
                }

                if (!path.EndsWith(".prefab")) {
                    return path + ".prefab";
                }
            } else if (path.StartsWith("sound/")) {
                return path + ".mp3";
            }

            return path + ".png";
        }
    }
}
