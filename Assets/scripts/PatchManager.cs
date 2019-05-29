using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;
using UnityEngine.Networking;
using System.IO;
using ICSharpCode.SharpZipLib.Zip;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace SGK
{
    public class PatchManager : MonoBehaviour {
        protected enum Step
        {
            Check,
            Down,
            Unzip,
            Install,
            Enter,
        }
        Step step = Step.Check;
        float process = 0;

        public Slider slider;
        public Text message;
        public GameObject loadingView;
        public GameObject [] waitingObject;

        public Text versionText;
        public TextAsset configFile;
        public List<AssetBundle> loadedBundles = new List<AssetBundle>();

        public GameObject reloadButton;
        public GameObject FPSCanvas;

        public static string gameURL;
        public static string announcementURL = "http://ndss.cosyjoy.com/sgk/login/announcement.php";
        public static string bundleURL = null;//"http://10.1.2.22/bundles";
        public static string versionString = "v 0.1.0";
        public static string svn_version = "";
        public static string versionTag = "test";
        public static string serverTag = "";
        public static string sdk_channel = "0";

        [XLua.GCOptimize]
        [Serializable]
        public struct ServerInfo {
            public int id;
            public string name;
            public string host;
            public int port;
            public int flag;
            public int group;
        };

        [Serializable]
        public struct PatchInfo {
            public string file;
            public uint crc;
            public string version;
            public int size;
            public int force;
        }

        [Serializable]
        public struct LoadingInfo {
            public string version;
            public string asset_version;
            public string tag;
            public string patchURL;
            public string bundleURL;
            public ServerInfo [] server_list;
            public PatchInfo [] patch_list;
        }

        public static Dictionary<string, string> PatchFiles = new Dictionary<string, string>();
        static ServerInfo [] server_list = new ServerInfo[0];
        public static ServerInfo [] GetServerList() {
            return server_list;
        }
        void Start () {
            // ResourceBundle.Clear();
            // ResourceBundle.Reload();
            Debug.Log("persistentDataPath : " + Application.persistentDataPath);
            gameURL = "http://ndss.cosyjoy.com/sgk/";

#if UNITY_EDITOR
            versionTag = "dev";
#endif

            if (configFile != null) {
                string [] lines = configFile.text.Split('\n');
                ParseConfig(lines);
            }

            string filePath = Application.persistentDataPath + "/config.txt";
            if (System.IO.File.Exists(filePath)) {
                string [] lines = System.IO.File.ReadAllLines(filePath);
                ParseConfig(lines);
            }

            string _gameURL = PlayerPrefs.GetString("gameURL", "");
            if (!string.IsNullOrEmpty(_gameURL)) {
                gameURL = _gameURL;
            }

            string _announcementURL = PlayerPrefs.GetString("announcementURL", "");
            if (!string.IsNullOrEmpty(_announcementURL)) {
                announcementURL = _announcementURL;
            }

            StartCoroutine(LoadPatch());

            Application.lowMemory += OnLowMemory;

            if (FPSCanvas != null) {
                DontDestroyOnLoad(FPSCanvas);
            }
        }

        private void OnLowMemory() {
            Debug.LogErrorFormat("OnLowMemory");
            SGK.ResourcesManager.UnloadUnusedAssets();
        }

        void ParseConfig(string [] lines) {
            if (lines == null) return;

            for (int i = 0; i < lines.Length; i++) {
                if (lines[i].Length > 0 && lines[i][0] == '#') {
                    continue;
                }

                int pos = lines[i].IndexOf('=');
                if (pos <= 0) {
                    continue;
                }

                string key = lines[i].Substring(0, pos).Trim();
                string value = lines[i].Substring(pos + 1).Trim();

                if (key == "game_url") {
                    gameURL = value;
                } else if (key == "client_tag") {
                    if (!string.IsNullOrEmpty(value)) {
                        versionTag = value;
                    }
                } else if (key == "svn_version") {
                    svn_version = value;
                } else if (key == "announcement_url") {
                    announcementURL = value;
                }
            }
        }

        void OnDestroy() {
            Debug.Log("release all patch bundles");
            foreach (AssetBundle bundle in loadedBundles) {
                bundle.Unload(false);
            }
            loadedBundles.Clear();
        }

        ZipFile zip_package;
        int total_count = 0;
        int loaded_count = 0;
        // string current_file;
        WWW loading_www = null;
        // bool hided_download = false;
        bool patch_is_ready = false;

        public static string GetPlatformName() {
#if UNITY_EDITOR
            return GetPlatformForAssetBundles(EditorUserBuildSettings.activeBuildTarget);
#else
            return GetPlatformForAssetBundles(Application.platform);
#endif
        }

#if UNITY_EDITOR
        static string GetPlatformForAssetBundles(BuildTarget target) {
            switch (target) {
                case BuildTarget.Android:
                    return "Android";
                case BuildTarget.iOS:
                    return "iOS";
                case BuildTarget.StandaloneWindows:
                case BuildTarget.StandaloneWindows64:
                    return "Windows";
                default:
                    return null;
            }
        }
#else
        public static string GetPlatformForAssetBundles(RuntimePlatform platform) {
            switch (platform) {
                case RuntimePlatform.Android:
                    return "Android";
                case RuntimePlatform.IPhonePlayer:
                    return "iOS";
                case RuntimePlatform.WindowsPlayer:
                    return "Windows";
                default:
                    return null;
            }
        }
#endif
        public static string HTTPQueryStr { 
            get {
                string platfrom = GetPlatformName();
                if (string.IsNullOrEmpty(platfrom)) {
                    platfrom = Application.platform.ToString();
                }

                string queryStr = "platform=" + platfrom + "&v=" + Application.version + "&t=" + versionTag + "&c=" + sdk_channel +
                    "&core_version=" + Application.version + "&asset_version=" + AssetVersion.Version + "&asset_core_version=" + AssetVersion.AssetCoreVersion; 
                if (!string.IsNullOrEmpty(svn_version)) {
                    queryStr = queryStr + "&sv=" + svn_version;
                }
                return queryStr;
            }
        }

        IEnumerator LoadPatch() {
            string platfrom = GetPlatformName();
            if (string.IsNullOrEmpty(platfrom)) {
                platfrom = Application.platform.ToString();
            }
            step = Step.Check;
            string fullURL = gameURL + "patch/index2.php?" + HTTPQueryStr; // He platform=" + platfrom + "&v=" + Application.version + "&t=" + versionTag;
            Debug.LogFormat(fullURL);

            WWW www = new WWW(fullURL);
            yield return www;

            if (!string.IsNullOrEmpty(www.error)) {
                Debug.Log(www.error);
                message.text = "加载补丁列表失败";

                if (reloadButton != null && (versionTag == "test" || versionTag == "dev")) {
                    reloadButton.SetActive(true);
                }

                yield break;
            }

#if UNITY_EDITOR
            if (!AssetManager.SimulateMode)
#endif
            {
                ResourceBundle.Clear();
                AssetManager.Clear();
            }

            LoadingInfo info = JsonUtility.FromJson<LoadingInfo>(www.text);
            Debug.Log(www.text);

            if (!string.IsNullOrEmpty(info.bundleURL))
            {
                bundleURL = info.bundleURL;
            }

            server_list = info.server_list;

            serverTag = info.tag;

            if (string.IsNullOrEmpty(info.asset_version))
                info.asset_version = AssetVersion.Version;
            versionString = string.Format("{0}:{1}:{2}", Application.version, AssetVersion.Version, info.asset_version);
            versionText.text = versionString;
            Debug.Log("version:" + versionString);

            Dictionary<string, string> localbundles = new Dictionary<string, string>();
            do
            {
#if UNITY_EDITOR
                if (AssetManager.SimulateMode) break;
#endif
                if (AssetVersion.Version == info.asset_version) break;

                List<PatchInfo> lpds = GetLocalBundles(info, ref localbundles);

                total_count = lpds.Count;
                loaded_count = 0;

                int patchDownLoadTotalSize = 0;
                for (int i = 0; i < total_count; ++i)
                {
                    patchDownLoadTotalSize += lpds[i].size;
                }

                OSTools.AlertDialog("提示", string.Format("您将下载 {0} MB 的资源", patchDownLoadTotalSize/1024/1024),
                    "确认", () =>
                    {
                        patchDownLoadTotalSize = 0;
                    },
                    "取消", () =>
                    {
                        Application.Quit();
                    });

                while(patchDownLoadTotalSize > 0)
                {
                    yield return null;
                }

                for (int i = 0; i < total_count; ++i)
                {
                    var patch = lpds[i];
                    string url = patch.file;
                    if (!url.StartsWith("http://"))
                    {
                        url = info.patchURL + "/" + url;
                    }

                    step = Step.Down;

                    // current_file = patch.file;
                    Debug.LogFormat("down patch {0}", url);
                    loading_www = new WWW(url);
                    yield return loading_www;
                    if (loading_www.error != null && !loading_www.error.Equals(""))
                    {
                        message.text = "下载补丁文件失败";
                        yield break;
                    }

                    if (loading_www.bytesDownloaded != patch.size)
                    {
                        Debug.LogError("down load patch error, patch file:" + patch.file);
                        break;
                    }

                    step = Step.Unzip; 
                    message.text = "解压文件..."; process = 1; yield return new WaitForSeconds(0.1f);

                    List<string> files = new List<string>();
                    unzipFile(loading_www.bytes, Application.persistentDataPath + "/" + patch.version, (string name) =>
                    {
                        files.Add(name);
                    });

                    step = Step.Install;
                    message.text = "安装补丁..."; process = 0; yield return new WaitForSeconds(0.1f);
                    bool flag = false;
                    AssetVersion.StartAddBundle(patch.version);
                    int c = 0;
                    foreach (var p in files)
                    {
                        if (!MergePatch(p, patch, ref localbundles))
                        {
                            flag = true;
                            break;
                        }
                        AssetVersion.AddBundle(p.Replace(".patch", ""));
                        message.text = string.Format("正在安装补丁：{0}/{1}", ++c, files.Count) ;
                        process = c / (float)files.Count; yield return null;
                    }
                    AssetVersion.EndAddBundle();
                    message.text = "安装补丁结束"; process = 1; yield return null;

                    if (flag)
                    {
                        AssetVersion.ClearBundle(patch.version);
                        break;
                    }

                    AssetVersion.Version = patch.version;
                    AssetVersion.Flush();
                    loaded_count += 1;
                }

                if (loaded_count != total_count) break;

                versionText.text = string.Format("{0}:{1}:{2}", Application.version, AssetVersion.Version, info.asset_version);
                loading_www = null;
                Caching.ClearCache();
            } while (false);

            if (loaded_count != total_count || total_count == 0)
            {
                localbundles.Clear();
                GetLocalBundles(info, ref localbundles);
            }

            foreach (var iter in localbundles)
            {
                var v = iter.Value;
                string bundlename = iter.Key;
                string abrepath = v + "/" + bundlename;
                string fullpath = Application.persistentDataPath + "/" + abrepath;
                if (Path.GetFileName(abrepath).StartsWith("hotfix"))
                {
                    ResourceBundle.Replace(bundlename, fullpath);
                }
                else
                {
                    if (PatchFiles.ContainsKey(bundlename))
                    {
                        PatchFiles[bundlename] = v;
                    }
                    else
                    {
                        PatchFiles.Add(bundlename, v);
                    }
                }
            }

            SetVersionList(info);

            Statistics.GetCache(this);

            AssetManager.Init();
            message.text = total_count != 0 && loaded_count != total_count ? "补丁更新失败，正在使用本地版本进入游戏" : "加载游戏中...";
            step = Step.Enter;
            process = 0;

            versionString = string.Format("{0}:{1}:{2}", Application.version, AssetVersion.Version, info.asset_version);
            yield return new WaitForSeconds(0.22f);
            patch_is_ready = true;
            StartCoroutine(BundleManager.DownAndLoadThread());
            StartCoroutine(AssetManager.CheckMemoryThread());
        }

        void StartGame()
        {
            for (int i = 0; i < waitingObject.Length; i++) {
                if (waitingObject[i] != null) {
                    waitingObject[i].SetActive(true);
                }
            }
            // gameObject.SetActive(false);
        }
        
        // Update is called once per frame
        void Update () {
            if (slider == null) { return; }

            switch(step)
            {
                case Step.Check:
                    break;
                case Step.Down:
                    message.text = string.Format("下载补丁 {0}% {1}/{2}", Math.Floor(loading_www.progress * 100), loaded_count, total_count);
                    process = loading_www.progress;
                    break;
                case Step.Unzip:
                    break;
                case Step.Install:
                    break;
                case Step.Enter:
                    process += 0.01f;
                    break;
                default:
                    break;
            }

            slider.value = process;

            if (patch_is_ready) {
                patch_is_ready = false;
                StartGame();
                slider = null;
            }
        }

        public List<PatchInfo> GetLocalBundles(LoadingInfo info, ref Dictionary<string, string> localbundles)
        {
            List<PatchInfo> lpds = new List<PatchInfo>();
            var bundles = AssetVersion.Version2Bundles;
            for (int i = 0; i < info.patch_list.Length; i++)
            {
                var p = info.patch_list[i];
                if (bundles.ContainsKey(p.version))
                {
                    var value = bundles[p.version];
                    for (int k = 0; k < value.Count; ++k)
                    {
                        if (localbundles.ContainsKey(value[k]))
                        {
                            localbundles[value[k]] = p.version;
                        }
                        else
                        {
                            localbundles.Add(value[k], p.version);
                        }
                    }
                }
                else
                {
                    lpds.Add(p);
                }
            }
            return lpds;
        }

        void SetVersionList(LoadingInfo info)
        {
            for (int i = 0; i < info.patch_list.Length; i++)
            {
                var p = info.patch_list[i];
                AssetVersion.AddVersionList(p.version);
            }
        }

        public string GetOutputFile(string path)
        {
            string[] dirs = path.Split('/');
            string npath = Application.persistentDataPath;
            for (int i = 0; i < dirs.Length - 1; ++i)
            {
                npath += "/" + dirs[i];
                if (!Directory.Exists(npath))
                {
                    Directory.CreateDirectory(npath);
                }
            }

            return Application.persistentDataPath + "/" + path;
        }

        public string GetBundlePathFromPackage(string path, string npath, bool inPackage)
        {
            Stream r,w;
            byte[] bytes = new byte[1024 * 32];
            if (inPackage)
            {
                if (zip_package == null)
                {
    #if UNITY_EDITOR
                    zip_package = new ZipFile(Application.dataPath.Replace("Assets", "") + "build/fairy.apk");
    #else
                    zip_package = new ZipFile(Application.dataPath);
    #endif
                }
                var idx = zip_package.FindEntry("Assets/" + path, true);
                if (idx < 0)
                {
                    return null;
                }
                r = zip_package.GetInputStream(idx);
            }else
            {
                r = File.OpenRead(path);
            }

            w = File.Create(npath);
            while(true)
            {
                int count = r.Read(bytes, 0, bytes.Length);
                if (count > 0)
                {
                    FileEncrypt.decode(bytes, (int)r.Position - count, count);
                    w.Write(bytes, 0, count);
                }
                else
                    break;
            }
            r.Flush();
            w.Flush();
            r.Close();
            w.Close();
            return npath;
        }

        public bool MergePatch(string patch, PatchInfo info, ref Dictionary<string, string> localbundles)
        {
            int ret = -1;
            string bundleName = patch.Replace(".patch", "");
            string fullpatch = Application.persistentDataPath + "/" + info.version + "/" + patch;
            string fullbundle = Application.persistentDataPath + "/" + info.version + "/" + bundleName;
            try
            {
                if (patch == bundleName)
                {
                    ret = 0;
                }
                else
                {
                    string old_file = "";
                    if (localbundles.ContainsKey(bundleName))
                    {
                        old_file = GetBundlePathFromPackage(Application.persistentDataPath + "/" + localbundles[bundleName] + "/" + bundleName, fullbundle, false);
                    }
                    else
                    {
#if UNITY_ANDROID && !UNITY_EDITOR
                        old_file = GetBundlePathFromPackage(bundleName, fullbundle, true);
#else
                        old_file = GetBundlePathFromPackage(Application.streamingAssetsPath + "/" + bundleName, fullbundle, false);
#endif
                    }

                    if (!string.IsNullOrEmpty(old_file))
                    {
                        ret = BSPatch.bspatch_merge(old_file, fullbundle, fullpatch);
                    }
                }
            }
            catch (Exception ex)
            {
                Debug.LogError(ex);
                return false;
            }

            if (ret == 0)
            {
                FileEncrypt.Encrypt(fullbundle, fullbundle);

                if (!localbundles.ContainsKey(bundleName))
                {
                    localbundles.Add(bundleName, info.version);
                }
                else
                {
                    localbundles[bundleName] = info.version;
                }

                return true;
            }
            return false;
        }

        public bool unzipFile(string path, string outputPath, System.Action<string> cb = null) {
            if (string.IsNullOrEmpty(path) || string.IsNullOrEmpty(outputPath))
                return false;
            FileStream rfs = File.Open(path, FileMode.Open);
            byte[] bts = new byte[rfs.Length];
            int count = rfs.Read(bts, 0, (int)rfs.Length);
            rfs.Close();
            if (count != bts.Length) {
                return false;
            }
            return unzipFile(bts, outputPath, cb);
        }

        public bool unzipFile(byte[] fileBytes, string outputPath, System.Action<string> cb = null) {
            if ((null == fileBytes) || string.IsNullOrEmpty(outputPath))
                return false;
            return unzipFile(new MemoryStream(fileBytes), outputPath, cb);
        }

        public bool unzipFile(Stream inputStream, string outputPath, System.Action<string> cb = null) {
            if (!Directory.Exists(outputPath))
                Directory.CreateDirectory(outputPath);

            ZipEntry entry = null;
            using (ZipInputStream zipInputStream = new ZipInputStream(inputStream)) {
                while (null != (entry = zipInputStream.GetNextEntry())) {
                    if (string.IsNullOrEmpty(entry.Name))
                        continue;

                    string filePathName = Path.Combine(outputPath, entry.Name);
                    if (entry.IsDirectory) {
                        Directory.CreateDirectory(filePathName);
                        continue;
                    }
                    try {
                        using (FileStream fileStream = File.Create(filePathName)) {
                            byte[] bytes = new byte[1024 * 1024];
                            while (true) {
                                int count = zipInputStream.Read(bytes, 0, bytes.Length);
                                if (count > 0)
                                    fileStream.Write(bytes, 0, count);
                                else
                                    break;
                            }
                            if (cb != null) {
                                cb(entry.Name);
                            }
                        }
                    } catch (System.Exception e) {
                        Debug.LogError("un zip error, msg:" + e.ToString());
                        return false;
                    }
                }
            }

            return true;
        }

        public void ResetGameURL() {
            PlayerPrefs.SetString("gameURL", "");
            GameObject obj = new GameObject();
            obj.AddComponent<GameReload>();
        }
    }
}
