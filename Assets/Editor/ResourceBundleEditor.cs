using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Text;

public class ResourceBundleEditor : MonoBehaviour {
    // [MenuItem("Tools/Resource Bundle/Scan")]
    public static void ScanResourcesBundle() {
        try {
            if (ScanDir("Assets/" + ResourceBundle.RESOURCES_DIR)) {
                return;
            }

            if (ScanScenesInBuild()) {
                return;
            }

           if (CollectDependencies()) {
               return;
           }
        } finally {
            EditorUtility.ClearProgressBar();
        }
        AssetDatabase.RemoveUnusedAssetBundleNames();
    }

    // [MenuItem("Tools/Resource Bundle/Clean")]
    static void CleanResourcesBundle() {
        AssetDatabase.RemoveAssetBundleName("assetbundle/scenes", true);
        // AssetDatabase.RemoveAssetBundleName("assetbundle/shared/scenes", true);

        /*
        string[] abNames = AssetDatabase.GetAllAssetBundleNames();
        foreach (string s in abNames) {
            if (s == "assetbundle/scenes") {
                AssetDatabase.RemoveAssetBundleName(s, true);
            }
        }
        */
    }

    public static bool ScanDir(string dirName, string bundleName = "",  bool root = true) {
        DirectoryInfo dir = new DirectoryInfo(dirName);
        FileInfo[] files = dir.GetFiles("*", SearchOption.TopDirectoryOnly);

        List<FileInfo> lf = new List<FileInfo>(files);
        lf.RemoveAll(s => s.Name.EndsWith(".meta"));
        files = lf.ToArray();

        try {
            if (root) {
                AssetDatabase.StartAssetEditing();
            }
            
            if (string.IsNullOrEmpty(bundleName) && ((files.Length > 0) || File.Exists(dirName + "/.bundle"))) {
                bundleName = dir.FullName.Replace('\\', '/').Replace(Application.dataPath + "/", "");
            }

            for (int i = 0; i < files.Length; ++i) {
                FileInfo f = files[i];
                string filePath = f.FullName.Replace('\\', '/').Replace(Application.dataPath, "Assets");
                if (EditorUtility.DisplayCancelableProgressBar(bundleName, filePath, (float)i / (float)files.Length)) {
                    return true;
                }

                var importer = AssetImporter.GetAtPath(filePath);
                if (importer == null) {
                    return false;
                }

                importer.assetBundleName = bundleName;
            }

            DirectoryInfo[] dirs = dir.GetDirectories();
            for (int i = 0; i < dirs.Length; i++) {
                string childDirName = dirs[i].FullName.Replace('\\', '/').Replace(Application.dataPath, "Assets");
                if (ScanDir(childDirName, bundleName, false)) {
                    return true;
                }
            }
        } finally {
            if (root) {
                EditorUtility.ClearProgressBar();
                AssetDatabase.StopAssetEditing();
                AssetDatabase.SaveAssets();
            }
        }
        return false;
    }
    
    /*
    [MenuItem("Tools/Resource Bundle/Test")]
    static void Test() {
    }
    */

    static bool ScanScenesInBuild() {
        try {
            AssetDatabase.StartAssetEditing();

            var scenes = EditorBuildSettings.scenes;

            for (int i = 3; i < scenes.Length; i++) {
                string path = scenes[i].path;

                if (EditorUtility.DisplayCancelableProgressBar(string.Format("scene {1}/{2}", path, i + 1, scenes.Length), path, (float)i / (float)scenes.Length)) {
                    return true;
                }

                var importer = AssetImporter.GetAtPath(path);
                if (importer != null) {
                    importer.assetBundleName = ResourceBundle.RESOURCES_DIR + "/scenes/" + Path.GetFileNameWithoutExtension(path);
                }
            }
        } finally {
            EditorUtility.ClearProgressBar();
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
        }

        return false;
    }

    class DependInfo
    {
        string fileName;
        HashSet<string> dependBy;
        public DependInfo(string fileName) {
            this.fileName = fileName;
            this.dependBy = new HashSet<string>();
        }

        public void AddDep(string abName) {
            dependBy.Add(abName);

            string ext = System.IO.Path.GetExtension(fileName).ToLower();

            if (abName.StartsWith("assetbundle/scenes") 
                || (ext == ".png")
                || (ext == ".jpg")
                || (ext == ".fbx")
                || (ext == ".tga")
                || (ext == ".mp4")
                || (ext == ".mp3")
                || (ext == ".wav")
                || (ext == ".ttf")
                ) {
                dependBy.Add(abName + "__");
                return;
            }
        }

        public void MakeName(ref HashSet<string> dirs) {
            var importer = AssetImporter.GetAtPath(fileName);
            if (importer == null) {
                return;
            }

            if (dependBy.Count == 0) {
                importer.assetBundleName = "";
                return;
            }

#if true
            string ext = System.IO.Path.GetExtension(fileName).ToLower();
            if (ext == ".shader") {
                importer.assetBundleName = ResourceBundle.RESOURCES_DIR + "/shared/material";
                return;
            }

            if (dependBy.Count == 1) {
                var ite = dependBy.GetEnumerator();
                ite.MoveNext();
                importer.assetBundleName = ite.Current;
                return;
            }
#endif
            importer.assetBundleName = ResourceBundle.RESOURCES_DIR + "/shared/" + makeBundleName(fileName, ref dirs);
            return;
        }

        public int Count() {
            return dependBy.Count;
        }
    }

    static bool CollectDependencies() {
        Dictionary<string, DependInfo> deps = new Dictionary<string, DependInfo>();

        try {
            AssetDatabase.StartAssetEditing();

            string[] cc = AssetDatabase.GetAllAssetBundleNames();
            for (int i = 0; i < cc.Length; i++) {
                if (!cc[i].StartsWith(ResourceBundle.RESOURCES_DIR.ToLower() + "/")) {
                    continue;
                }

                if (cc[i].StartsWith((ResourceBundle.RESOURCES_DIR + "/shared/").ToLower())) {
                    continue;
                }

                if (CollectDependencies(cc[i], ref deps, i, cc.Length)) {
                    return true;
                }
            }

            HashSet<string> dirs = new HashSet<string>();
            foreach(var ite in deps) {
                string dir = System.IO.Path.GetDirectoryName(ite.Key);
                dirs.Add(dir);
            }

            int j = 0;
            foreach(var ite in deps) {

                var s = ite.Key;
                if (EditorUtility.DisplayCancelableProgressBar(string.Format("name depend {0}/{1}", j + 1, deps.Count), s, (float)j / deps.Count)) {
                    return true;
                }

                ite.Value.MakeName(ref dirs);

                /*
                var importer = AssetImporter.GetAtPath(s);
                if (importer != null) {
                    importer.assetBundleName = ResourceBundle.RESOURCES_DIR + "/shared/" + makeBundleName(s, ref dirs);
                }
                */

                j++;
            }


        } finally {
            EditorUtility.ClearProgressBar();
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
        }

        try {
            AssetDatabase.StartAssetEditing();

            string[] cc = AssetDatabase.GetAllAssetBundleNames();
            for (int j = 0; j < cc.Length; j++) {
                if (!cc[j].StartsWith((ResourceBundle.RESOURCES_DIR + "/shared/").ToLower())) {
                    continue;
                }

                string[] assets = AssetDatabase.GetAssetPathsFromAssetBundle( cc[j] );

                // float pp = 1.0f / assets.Length;
                for (int i = 0; i < assets.Length; i++) {
                    var a = assets[i];
                    if (EditorUtility.DisplayCancelableProgressBar(string.Format("clean {0} {1}/{2}", cc[j],  i + 1, assets.Length), "", (float)i / assets.Length)) {
                        return true;
                    }

                    if (!deps.ContainsKey(a)) {
                        var importer = AssetImporter.GetAtPath(a);
                        if (importer != null) {
                            importer.assetBundleName = "";
                        }
                    }
                }
            }
        } finally {
            EditorUtility.ClearProgressBar();
            AssetDatabase.StopAssetEditing();
            AssetDatabase.SaveAssets();
        }
        return false;
    }

    static string makeBundleName(string path, ref  HashSet<string> dirs) {
        string[] paths = path.Split('/');
        string name = "";
        for (int i = 1; i < paths.Length; i++) {
            if (string.IsNullOrEmpty(name)) {
                name = paths[i];
            } else {
                name = name + "/" + paths[i];
            }

            if (dirs.Contains(paths[0] + "/" + name)) {
                return name;
            }

            if (File.Exists(paths[0] + "/" + name + "/.bundle")) {
                dirs.Add(paths[0] + "/" + name);
                return name;
            }
        }
        return name;
    }

    static bool CollectDependencies(string assetBundleName, ref Dictionary<string, DependInfo> deps, int cur, int max) {
        string[] assets = AssetDatabase.GetAssetPathsFromAssetBundle(assetBundleName.ToLower());
        if (assets.Length == 0) {
            Debug.LogFormat("asset bundle {0} is empty", assetBundleName);
            return false;
        }

        float pp = 1.0f / assets.Length;

        for (int i = 0; i < assets.Length; i++) {
            string fileName = assets[i];
            if (!fileName.EndsWith(".unity") && !fileName.StartsWith(("Assets/" + ResourceBundle.RESOURCES_DIR + "/"))) {
                if (!deps.ContainsKey(fileName)) {
                    var info = new DependInfo(fileName);
                    deps[fileName] = info;
                }
                continue;
            }

            string[] ds = AssetDatabase.GetDependencies(fileName, true);
            float ppp = pp / ds.Length;
            for (int j = 0; j < ds.Length; j++) {
                string dep = ds[j];
                if (EditorUtility.DisplayCancelableProgressBar(string.Format("Collect {0} {1}/{2}", assetBundleName, cur + 1, max), dep, i * pp + ppp * j)) {
                    return true;
                }

                if (dep.StartsWith(("Assets/" + ResourceBundle.RESOURCES_DIR + "/"))) {
                    continue;
                }

                if (dep.EndsWith(".cs") || dep.EndsWith(".unity") || dep.EndsWith(".dll")) { 
                    continue;
                }

                DependInfo info;
                if (!deps.TryGetValue(dep, out info)) {
                    info = new DependInfo(dep);
                    deps[dep] = info;
                }
                info.AddDep(assetBundleName);
            }
        }

        return false;
    }

    class EncryptStream : System.IO.Stream {
        Stream _stream;
        public EncryptStream(Stream stream) {
            _stream = stream;
        }

        public override bool CanRead { get { return true; } }

        public override bool CanSeek { get { return true; } }

        public override bool CanWrite { get { return false; } }

        public override long Length { get { return _stream.Length; } }

        public override long Position {
            get { return _stream.Position; }
            set { _stream.Position = value;  }
        }

        public override void Flush() {
            _stream.Flush();
        }

        public override int Read(byte[] buffer, int offset, int count) {
            int ret = _stream.Read(buffer, offset, count);
            // TODO: decode;

            return ret;
        }

        public override long Seek(long offset, SeekOrigin origin) {
            return _stream.Seek(offset, origin);
        }

        public override void SetLength(long value) {
            _stream.SetLength(value);
        }

        public override void Write(byte[] buffer, int offset, int count) {
            // encode


            _stream.Write(buffer, offset, count);
        }
    }

    [MenuItem("Tools/Resource Bundle/Update Button")]
    static void CollectDepend() {
        DirectoryInfo dir = new DirectoryInfo("Assets/Resources/prefabs");
        FileInfo[] files = dir.GetFiles("*.prefab", SearchOption.AllDirectories);

        List<FileInfo> lf = new List<FileInfo>(files);
        lf.RemoveAll(s => s.Name.EndsWith(".meta"));
        files = lf.ToArray();
        try {
            // FileStream outFile = File.OpenWrite("Assets/depend.txt");

            // AssetDatabase.StartAssetEditing();

            Font font = AssetDatabase.LoadAssetAtPath<Font>("Assets/fonts/default.ttf");

            for (int i = 0; i < files.Length; ++i) {
                FileInfo f = files[i];
                string filePath = f.FullName.Replace('\\', '/').Replace(Application.dataPath, "Assets");
                if (EditorUtility.DisplayCancelableProgressBar(string.Format("prefab {1}/{2}", filePath, i + 1, files.Length), filePath, (float)i / (float)files.Length)) {
                    return;
                }

                GameObject oobj = AssetDatabase.LoadAssetAtPath<GameObject>(filePath);
                TryUpdateButton(oobj, font);

                /*
                string[] ds = AssetDatabase.GetDependencies(filePath, true);
                for (int j = 0; j < ds.Length; j++) {
                    string s = filePath + "," + ds[j] + "\n";
                    byte[] bs = new UTF8Encoding(true).GetBytes(s);
                    // outFile.Write(bs, 0, bs.Length);
                }
                */
            }
            /*
            var scenes = EditorBuildSettings.scenes;
            for (int i = 0; i < scenes.Length; i++) {
                string path = scenes[i].path;
                if (EditorUtility.DisplayCancelableProgressBar(string.Format("scene {1}/{2}", path, i + 1, scenes.Length), path, (float)i / (float)files.Length)) {
                    return;
                }
                string[] ds = AssetDatabase.GetDependencies(path, true);
                for (int j = 0; j < ds.Length; j++) {
                    string s = path + "," + ds[j] + "\n";
                    byte[] bs = new UTF8Encoding(true).GetBytes(s);
                    outFile.Write(bs, 0, bs.Length);
                }
            }
            outFile.Close();
            */
        } finally {
            AssetDatabase.SaveAssets();
            EditorUtility.ClearProgressBar();

            // AssetDatabase.StopAssetEditing();
        }
    }

    static void TryUpdateButton(GameObject oobj, Font font) {
        SGK.QualityConfig.ButtonConfig[] cfgs = SGK.QualityConfig.GetInstance().buttonConfig;
        var rt = oobj.GetComponent<RectTransform>();
        if (rt == null) {
            return;
        }

        UnityEngine.UI.Image image = oobj.GetComponent<UnityEngine.UI.Image>();
        if (image != null) {
            do {
                /*
                if (image.sprite == SGK.QualityConfig.GetInstance().closeButtonSprite) {
                    image.SetNativeSize();
                    var listener = image.gameObject.GetComponent<UGUIClickEventListener>();
                    if (listener != null) {
                        listener.disableTween = false;
                    }
                    break; ;
                }
                */

                for (int x = 0; x < cfgs.Length; x++) {
                    if (image.sprite == cfgs[x].sprite) {
                        var size = rt.sizeDelta;
                        if (size.y != image.sprite.textureRect.height) {
                            size.y = image.sprite.textureRect.height;
                            rt.sizeDelta = size;
                        }

                        for (int n = 0; n < rt.childCount; n++) {
                            Transform crt = rt.GetChild(n);
                            UnityEngine.UI.Text text = crt.gameObject.GetComponent<UnityEngine.UI.Text>();
                            if (text != null) {
                                text.font = font;
                                text.fontSize = 22;
                                text.color = Color.black;

                                var shadow = text.GetComponent<UnityEngine.UI.Shadow>();
                                if (shadow != null) {
                                    DestroyImmediate(shadow, true);
                                }

                            }
                        }
                        EditorUtility.SetDirty(oobj);
                        break;
                    }
                }
            } while (false);
        }

        for (int n = 0; n < rt.childCount; n++) {
            Transform crt = rt.GetChild(n);
            TryUpdateButton(crt.gameObject, font);
        }
    }



    public static string PATH = "Assets/Resources";

    public class AssetBundleInfo
    {
        public string fullPath;
        public bool haveBundle;
        public AssetBundle assetBundle;
        public Dictionary<string, AssetBundleInfo> children;

        public static AssetBundleManifest _manifest;

        public AssetBundleInfo(string fullPath, bool haveBundle) {
            this.fullPath = fullPath;
            this.haveBundle = haveBundle;
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

        public AssetBundle GetAssetBundle() {
            if (assetBundle == null) {
                assetBundle = AssetBundle.LoadFromFile(Application.streamingAssetsPath + "/" + fullPath);
            }
            return assetBundle;
        }

        public IEnumerable LoadAsync() {
            if (assetBundle != null) {
                AssetBundleCreateRequest request = AssetBundle.LoadFromFileAsync(Application.streamingAssetsPath + "/" + fullPath);
                if (request != null) {
                    yield return request;
                    assetBundle = request.assetBundle;
                }
            }
        }
    }

    public static AssetBundleManifest _asserBundleManifest = null;
    static AssetBundleInfo root = null;

    public static void Clear() {
        AssetBundle.UnloadAllAssetBundles(false);
        root = null;
        _asserBundleManifest = null;
    }

#region patch
    public static void SetManifest(AssetBundleManifest manifest) {
        _asserBundleManifest = manifest;
    }

    public static void Replace(string path, AssetBundle assetBundle) {
        string[] keys = path.Split('/');
        AssetBundleInfo parent = root;
        for (int j = 0; j < keys.Length; j++) {
            parent = parent.Add(keys[j], j == (keys.Length - 1));
        }
        parent.assetBundle = assetBundle;
    }
#endregion

    public static void Reload() {
        if (_asserBundleManifest == null) {
            AssetBundle manifestBundle = AssetBundle.LoadFromFile(Application.streamingAssetsPath + "/assetbundle/" + SGK.PatchManager.GetPlatformName());
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

        AssetBundle.LoadFromFile(Application.streamingAssetsPath + "/assetbundle/scenes");
    }

    public static AssetBundleInfo FindAssetBundleInfo(string path) {
        string[] keys = path.Split('/');
        AssetBundleInfo parent = root;
        AssetBundleInfo find = null;
        for (int j = 0; j < keys.Length; j++) {
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

    static AssetBundle LoadAssetBundle(AssetBundleInfo info) {
        if (info != null) {
            if (_asserBundleManifest != null) {
                string[] depends = _asserBundleManifest.GetAllDependencies(info.fullPath);
                for (int i = 0; i < depends.Length; i++) {
                    AssetBundleInfo depend_info = FindAssetBundleInfo(depends[i]);
                    depend_info.GetAssetBundle();
                }
            }
        }
        return info.GetAssetBundle();
    }

    public static T Load<T>(string path) where T : Object {
        AssetBundle assetBundle = LoadAssetBundle(FindAssetBundleInfo(path));
        if (assetBundle == null) {
            return null;
        }
        return assetBundle.LoadAsset<T>(path);
    }

    public static Object Load(string path) {
        AssetBundle assetBundle = LoadAssetBundle(FindAssetBundleInfo(path));
        if (assetBundle == null) {
            return null;
        }
        return assetBundle.LoadAsset(path);
    }

    public static Object Load(string path, System.Type type) {
        AssetBundle assetBundle = LoadAssetBundle(FindAssetBundleInfo(path));
        if (assetBundle == null) {
            return null;
        }
        return assetBundle.LoadAsset(path, type);
    }

    public static IEnumerable LoadAssetBundleAsync(AssetBundleInfo info) {
        if (info != null) {
            if (_asserBundleManifest != null) {
                string[] depends = _asserBundleManifest.GetAllDependencies(info.fullPath);
                for (int i = 0; i < depends.Length; i++) {
                    AssetBundleInfo depend_info = FindAssetBundleInfo(depends[i]);
                    yield return depend_info.LoadAsync();
                }
            }
            yield return info.LoadAsync();
        }
    }
}
