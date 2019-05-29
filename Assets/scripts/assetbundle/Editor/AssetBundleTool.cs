using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
public class AssetBundleTool {
    
    [MenuItem("Tools/Simulate Mode", false, 101)]
    public static void ToggleSimulationMode()
    {
        AssetManager.SimulateMode = !AssetManager.SimulateMode;
    }

    [MenuItem("Tools/Simulate Mode", true, 101)]
    public static bool ToggleSimulationModeValidate()
    {
        Menu.SetChecked("Tools/Simulate Mode", AssetManager.SimulateMode);
        return true;
    }

    [MenuItem("Tools/Simulate Lua", false, 102)]
    public static void ToggleSimulationLua()
    {
        AssetManager.SimulateLua = !AssetManager.SimulateLua;
    }

    [MenuItem("Tools/Simulate Lua", true, 102)]
    public static bool ToggleSimulationLuaValidate()
    {
        Menu.SetChecked("Tools/Simulate Lua", AssetManager.SimulateLua);
        return true;
    }

    [MenuItem("Tools/Log File Read", false, 103)]
    public static void ToggleLogFileRead() {
        SGK.FileUtils.LogFileRead = !SGK.FileUtils.LogFileRead;
    }

    [MenuItem("Tools/Log File Read", true, 103)]
    public static bool ToggleLogFileReadValidate() {
        Menu.SetChecked("Tools/Log File Read", SGK.FileUtils.LogFileRead);
        return true;
    }

    [MenuItem("Tools/MapScene_add_map_scene.lua")]
    public static void MapSceneAddLua()
    {
        string[] assets = AssetDatabase.FindAssets("t:scene", new string[] { "Assets/scenes/maps" });
        //string[] assets = AssetDatabase.FindAssets("t:prefab", new string[] { "Assets/assetbundle/prefabs/base" });
        Debug.LogError("scene :"+assets.Length);
        bool temp = true;
        if (temp)
        {
            for (int i = 0; i <= assets.Length; i++)
            {
                string fileName = AssetDatabase.GUIDToAssetPath(assets[i]);
               // Debug.LogError(i + fileName);
                EditorSceneManager.OpenScene(fileName);
                GameObject MapSceneRoot = GameObject.Find("MapSceneRoot");
                if (MapSceneRoot)
                {
                    //obj.AddComponent<BoxCollider>();
                    SGK.LuaBehaviour LuaBehaviour = MapSceneRoot.GetComponent<SGK.LuaBehaviour>();
                    if (LuaBehaviour || LuaBehaviour.luaScriptFileName == "")
                    {
                        //MapSceneRoot.AddComponent<SGK.LuaBehaviour>().luaScriptFileName = "view/map_scene.lua";
                        //EditorSceneManager.SaveScene(EditorSceneManager.GetActiveScene());
                    }else {
                        Debug.LogError(fileName);
                    }
                }
                else
                {
                    Debug.LogError(fileName + " => not MapSceneRoot");
                }
            }
        }else { 
            //AssetDatabase.SaveAssets();
            EditorSceneManager.OpenScene("Assets/scenes/maps/cemetery_scene.unity");
            GameObject a = GameObject.Find("MapSceneRoot");
            a.AddComponent<BoxCollider>();
            a.AddComponent<SGK.LuaBehaviour>().luaScriptFileName = "view/map_scene.lua";
            EditorSceneManager.SaveScene(EditorSceneManager.GetActiveScene());
        }
    }

    [MenuItem("Tools/生成资源包/Windows")]
    public static void CreateWindowsAssetBundle() {
        var watch = new System.Diagnostics.Stopwatch();
        watch.Start();
        try {
            string dpath = "AssetBundles/Windows";
            DirectoryInfo ndir = new DirectoryInfo(dpath);
            if (!ndir.Exists) {
                ndir.Create();
            }

            BuildAssetBundleOptions ops = BuildAssetBundleOptions.None;
            ops |= BuildAssetBundleOptions.ChunkBasedCompression;
            ops |= BuildAssetBundleOptions.DisableLoadAssetByFileNameWithExtension;
            ops |= BuildAssetBundleOptions.DisableLoadAssetByFileName;

            BuildPipeline.BuildAssetBundles(dpath, ops, BuildTarget.StandaloneWindows64);
            RemoveUnusedBundles(dpath);
            CopyAssetBundle(dpath);
        } catch (System.Exception ex) {
            Debug.LogError("create android assetbundle failed, " + ex.ToString());
        }
        watch.Stop();
        UnityEngine.Debug.Log(string.Format("build windows asset bundle dela time {0}ms, {1}s, {2}min", watch.ElapsedMilliseconds, watch.ElapsedMilliseconds / 1000, watch.ElapsedMilliseconds / 1000 / 60));
    }

    [MenuItem("Tools/生成资源包/Andorid")]
    public static void CreateAndroidAssetBundle()
    {
        var watch = new System.Diagnostics.Stopwatch();
        watch.Start();
        try
        {
            string dpath = "AssetBundles/Android";
            if (!Directory.Exists(dpath)) {
                Directory.CreateDirectory(dpath);
            }

            BuildAssetBundleOptions ops = BuildAssetBundleOptions.None;
            ops |= BuildAssetBundleOptions.ChunkBasedCompression;
            ops |= BuildAssetBundleOptions.DisableLoadAssetByFileNameWithExtension;
            ops |= BuildAssetBundleOptions.DisableLoadAssetByFileName;

            BuildPipeline.BuildAssetBundles(dpath, ops, BuildTarget.Android);
            RemoveUnusedBundles(dpath);
            CopyAssetBundle(dpath);
        }
        catch (System.Exception ex)
        {
            Debug.LogError("create android assetbundle failed, " + ex.ToString());
        }
        watch.Stop();
        UnityEngine.Debug.Log(string.Format("build android asset bundle dela time {0}ms, {1}s, {2}min", watch.ElapsedMilliseconds, watch.ElapsedMilliseconds / 1000, watch.ElapsedMilliseconds / 1000 / 60));
    }

    [MenuItem("Tools/生成资源包/IOS")]
    public static void CreateIOSAssetBundle()
    {
        var watch = new System.Diagnostics.Stopwatch();
        watch.Start();
        string dpath = "AssetBundles/iOS";
        DirectoryInfo ndir = new DirectoryInfo(dpath);
        if (!ndir.Exists)
        {
            ndir.Create();
        }

        BuildPipeline.BuildAssetBundles(dpath, BuildAssetBundleOptions.ChunkBasedCompression, BuildTarget.iOS);
        RemoveUnusedBundles(dpath);
        CopyAssetBundle(dpath);
        watch.Stop();
        UnityEngine.Debug.Log(string.Format("build ios asset bundle dela time {0}ms, {1}s, {2}min", watch.ElapsedMilliseconds, watch.ElapsedMilliseconds/1000, watch.ElapsedMilliseconds/1000/60));
    }

    /*
    public static void CopyAssetBundle(string dpath)
    {
        if (Directory.Exists(Application.streamingAssetsPath)) {
            Directory.Delete(Application.streamingAssetsPath, true);
        }
        Directory.CreateDirectory(Application.streamingAssetsPath);

        string encrypt = dpath + "_encrypt";
        if (Directory.Exists(encrypt))
        {
            Directory.Delete(encrypt, true);
        }
        Directory.CreateDirectory(encrypt);

        DirectoryInfo ndir = new DirectoryInfo(dpath);
        FileInfo[] files = ndir.GetFiles("*.*", SearchOption.AllDirectories);
        for (int i = 0; i < files.Length; ++i)
        {
            EditorUtility.DisplayProgressBar("copy assets", string.Format("正在拷贝资源 {0}/{1}", i, files.Length), (float)i / (float)files.Length);
            FileInfo f = files[i];
            if (!f.Name.EndsWith(".manifest"))
            {
                string name = f.FullName.Replace("\\", "/");
                name = name.Substring(name.IndexOf(dpath) + dpath.Length);
                string path = f.Directory.FullName.Replace("\\", "/");
                path = path.Substring(path.IndexOf(dpath) + dpath.Length);

                if (!Directory.Exists(Application.streamingAssetsPath + path))
                {
                    Directory.CreateDirectory(Application.streamingAssetsPath + path);
                }

                if (!Directory.Exists(encrypt + path))
                {
                    Directory.CreateDirectory(encrypt + path);
                }

                FileEncrypt.Encrypt(f.FullName, encrypt +name);
                File.Copy(encrypt + name, Application.streamingAssetsPath + name, true);
            }else
            {
                File.Delete(f.FullName);
            }
        }
        EditorUtility.ClearProgressBar();
        AssetDatabase.Refresh();
    }
    */

    public static void RemoveUnusedBundles(string dpath)
    {
        DirectoryInfo ndir = new DirectoryInfo(dpath);
        FileInfo[] files = ndir.GetFiles("*.*", SearchOption.AllDirectories);
        List<string> l = new List<string>();
        HashSet<string> hbs = new HashSet<string>();

        string[] bs = AssetDatabase.GetAllAssetBundleNames();
        foreach (var b in bs)
        {
            hbs.Add(Path.GetFileName(b));
        }
        hbs.Add(AssetBundles.Utility.GetPlatformName());

        for (int i = 0; i < files.Length; ++i)
        {
            FileInfo f = files[i];
            if (!f.Name.EndsWith(".manifest"))
            {
                if (!hbs.Contains(f.Name))
                {
                    l.Add(f.FullName);
                }
            }
        }

        for (int i = 0; i < l.Count; ++i)
        {
            File.Delete(l[i]);
            File.Delete(l[i] + ".manifest");
        }
    }

    public static void CopyAssetBundle(string dpath)
    {
        if (Directory.Exists(Application.streamingAssetsPath))
        {
            Directory.Delete(Application.streamingAssetsPath, true);
        }
        Directory.CreateDirectory(Application.streamingAssetsPath);

        DirectoryInfo ndir = new DirectoryInfo(dpath);
        FileInfo[] files = ndir.GetFiles("*.*", SearchOption.AllDirectories);
        for (int i = 0; i < files.Length; ++i)
        {
            EditorUtility.DisplayProgressBar("copy assets", string.Format("正在拷贝资源 {0}/{1}", i, files.Length), (float)i / (float)files.Length);
            FileInfo f = files[i];
            if (!f.Name.EndsWith(".manifest"))
            {
                string name = f.FullName.Replace("\\", "/");
                name = name.Substring(name.IndexOf(dpath) + dpath.Length);
                string path = f.Directory.FullName.Replace("\\", "/");
                path = path.Substring(path.IndexOf(dpath) + dpath.Length);

                if (!Directory.Exists(Application.streamingAssetsPath + path))
                {
                    Directory.CreateDirectory(Application.streamingAssetsPath + path);
                }
                
                FileEncrypt.Encrypt(f.FullName, Application.streamingAssetsPath + name);
            }
        }
        EditorUtility.ClearProgressBar();
        AssetDatabase.Refresh();
    }
}
