using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class ResourceBundle {
    public const string RESOURCES_DIR = "assetbundle";

    public static bool unloadAllLoadedObjects = true;

    public class AssetBundleInfo
    {
        public string fullPath;
        public string pathPath;
        public bool haveBundle;
        public Bundle assetBundle;
        public Dictionary<string, AssetBundleInfo> children;

        public static AssetBundleManifest _manifest;

        public AssetBundleInfo(string fullPath, bool haveBundle) {
            this.fullPath = fullPath;
            this.haveBundle = haveBundle;
            children = new Dictionary<string, AssetBundleInfo>();
        }

        public AssetBundleInfo Add(string name, bool haveBundle) {
            AssetBundleInfo info;
            if (children.TryGetValue(name, out info)) {
                Debug.Assert(haveBundle || !this.haveBundle);
                return info;
            }

            if (string.IsNullOrEmpty(fullPath)) {
                info = new AssetBundleInfo(name, haveBundle);
            } else {
                info = new AssetBundleInfo(fullPath + "/" + name, haveBundle);
            }

            children[name] = info;
            return info;
        }

        bool loaded = false;

        public bool isLoaded {
            get { return loaded; }
        }

        public Bundle GetAssetBundle() {
            if (assetBundle == null && !loaded) {
                loaded = true;
                try {
                    if (string.IsNullOrEmpty(pathPath)) {
                        assetBundle = Bundle.LoadFromFile(Application.streamingAssetsPath + "/" + fullPath);
                    } else {
                        assetBundle = Bundle.LoadFromFile(pathPath);
                    }
                } catch(System.Exception e) {
                    Debug.LogErrorFormat("load asset bundle error {0} {1}", fullPath, e);
                }
            }
            return assetBundle;
        }

//         public void SetAssetBundle(AssetBundle assetBundle) {
//             if (this.assetBundle != null && this.assetBundle != assetBundle) {
//                 this.assetBundle.Unload(false);
//             }
// 
//             this.assetBundle = assetBundle;
//             loaded = true;
//         }

        public void Unload(bool unloadAllLoadedObjects, bool recursive = true) {
            if (assetBundle != null) {
                assetBundle.Unload(unloadAllLoadedObjects);
                assetBundle = null;
                loaded = false;
            }

            if (recursive) {
                foreach (var child in children) {
                    child.Value.Unload(unloadAllLoadedObjects, recursive);
                }
            }
        }

        /*
        public IEnumerable LoadAsync() {
            if (assetBundle == null && !loaded) {
                loaded = true;
                AssetBundleCreateRequest request = FileEncrypt.LoadFromFileAsync(Application.streamingAssetsPath + "/" + fullPath);
                if (request != null) {
                    yield return request;
                    assetBundle = request.assetBundle;
                }
            }
        }
        */
    }

    public static AssetBundleManifest _asserBundleManifest = null;
    public static Stream manifestBundleFileStream = null;
    static AssetBundleInfo root = null;

    public static void Clear() {
        if (root != null) {
            root.Unload(unloadAllLoadedObjects, true); ;
        }
        AssetBundle.UnloadAllAssetBundles(true);
        root = null;
        _asserBundleManifest = null;

        if (manifestBundleFileStream != null) {
            manifestBundleFileStream.Dispose();
            manifestBundleFileStream = null;
        }
    }

#region patch
    public static void SetManifest(AssetBundleManifest manifest) {
        _asserBundleManifest = manifest;
    }


    public static void Replace(string path, string fullPath) {
        if (root == null) {
            return;
        }
        string[] keys = path.Split('/');
        AssetBundleInfo parent = root;
        for (int j = 0; j < keys.Length; j++) {
            parent = parent.Add(keys[j], j == (keys.Length - 1));
        }
        parent.pathPath = fullPath;
    }

#endregion
    public static void Reload() {
        if (_asserBundleManifest == null) {
            AssetBundle manifestBundle = FileEncrypt.LoadFromFile(Application.streamingAssetsPath + "/" + SGK.PatchManager.GetPlatformName(), out manifestBundleFileStream);
            if (manifestBundle != null) {
                _asserBundleManifest = manifestBundle.LoadAsset<AssetBundleManifest>("AssetBundleManifest");
            }
        }

        root = new AssetBundleInfo("", false);

        if (_asserBundleManifest == null) {
            return;
        }

        string[] bundles = _asserBundleManifest.GetAllAssetBundles();
        for (int i = 0; i < bundles.Length; i++) {
            string[] keys = bundles[i].Split('/');
            AssetBundleInfo parent = root;
            for (int j = 0; j < keys.Length; j++) {
                parent = parent.Add(keys[j], j == (keys.Length - 1));
            }
        }
    }

    public static void LoadScenes(string name) {
        AssetManager.LoadScene(name);
    }

    public static void UnloadAll() {
        if (root != null) {
            root.Unload(unloadAllLoadedObjects);
        }
        // LoadScenes();
    }

    public static AssetBundleInfo FindAssetBundleInfo(string path) {
        if (root == null) {
            return null;
        }
        string[] keys = path.ToLower().Split('/');
        AssetBundleInfo parent = root;
        AssetBundleInfo find = null;
        for (int j = 1; j < keys.Length; j++) {
            AssetBundleInfo info;
            if (!parent.children.TryGetValue(keys[j], out info)) {
                break;
            }
            if (info.haveBundle) {
                find = info;
            }
            parent = info;
        }

        return find;
    }

    static Bundle LoadAssetBundle(AssetBundleInfo info) {
        if (info != null && !info.isLoaded) {
            info.GetAssetBundle();
            if (_asserBundleManifest != null) {
                string[] depends = _asserBundleManifest.GetAllDependencies(info.fullPath);
                for (int i = 0; i < depends.Length; i++) {
                    AssetBundleInfo depend_info = FindAssetBundleInfo("Assets/" + depends[i]);
                    LoadAssetBundle(depend_info);
                }
            }
        }
        return (info != null) ? info.GetAssetBundle() : null;
    }

    public static Bundle GetAssetBundle(string path) {
        return LoadAssetBundle(FindAssetBundleInfo(path));
    }

    public static T Load<T>(string path) where T : Object {
        Bundle assetBundle = LoadAssetBundle(FindAssetBundleInfo(path));
        if (assetBundle == null) {
            return null;
        }
        return assetBundle.LoadAsset<T>(path);
    }

    public static Object Load(string path) {
        Bundle assetBundle = LoadAssetBundle(FindAssetBundleInfo(path));
        if (assetBundle == null) {
            return null;
        }
        return assetBundle.LoadAsset(path);
    }

    public static Object Load(string path, System.Type type) {
        Bundle assetBundle = LoadAssetBundle(FindAssetBundleInfo(path));
        if (assetBundle == null) {
            return null;
        }
        return assetBundle.LoadAsset(path, type);
    }

    /*
    public static IEnumerable LoadAssetBundleAsync(AssetBundleInfo info) {
        if (info != null && !info.isLoaded) {
            yield return info.LoadAsync();
            if (_asserBundleManifest != null) {
                string[] depends = _asserBundleManifest.GetAllDependencies(info.fullPath);
                for (int i = 0; i < depends.Length; i++) {
                    AssetBundleInfo depend_info = FindAssetBundleInfo(depends[i]);
                    yield return depend_info.LoadAsync();
                }
            }
           
        }
    }
    */
}
