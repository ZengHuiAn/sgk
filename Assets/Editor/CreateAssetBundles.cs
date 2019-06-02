using System.IO;
using UnityEditor;
using UnityEngine;
using System.Diagnostics;
using System.Collections.Generic;
using SGK;
using System;
using System.Runtime.InteropServices;

public class CreateAssetBundles {

    public static string[] scenes = new string[]
        {
            "Assets/scenes/FirstScene.unity",
            "Assets/scenes/PersistentScene.unity",
            "Assets/scenes/blank.unity",
            "Assets/scenes/loading.unity",
        };

    [MenuItem("Assets/Build Database")]
    static void BuildDataBase() {
        SGK.Database.LoadConfigFromServer();
        SGK.CharacterConfig.GenerateBattleCharacterConfig();
    }
    
    static void CompileLuaFile()
    {
        DirectoryInfo dir = new DirectoryInfo(Application.dataPath + "/Lua");
        var lfiles = dir.GetFiles("*.lua", SearchOption.AllDirectories);
        var bfiles = dir.GetFiles("*.bytes", SearchOption.AllDirectories);

        List<FileInfo> files = new List<FileInfo>();
        files.AddRange(lfiles);
        files.AddRange(bfiles);

        string[] luacs = new string[] { "x86", "x64" };
        int i = 0;
        foreach (var f in files)
        {
            ++i;
            string fname = f.FullName.Replace("\\", "/").Replace(Application.dataPath + "/Lua/", "");
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("{0}", fname), i + "/" + files.Count, (float)i / (float)files.Count))
            {
                return;
            }

            foreach (var luac in luacs)
            {
                string ndir = Application.dataPath + "/" + ResourceBundle.RESOURCES_DIR + "/" + luac + "/" + Path.GetDirectoryName(fname);
                if (!Directory.Exists(ndir))
                {
                    Directory.CreateDirectory(ndir);
                }
                string luacexe = Application.dataPath + "/../luac/" + luac + "/luac53.exe";
                string outname = Application.dataPath + "/" + ResourceBundle.RESOURCES_DIR + "/" + luac + "/" + fname;
                if (!outname.EndsWith(".bytes"))
                {
                    outname += ".bytes";
                }
                string args = " -s -o " + outname + " " + f.FullName;
                ProcessStartInfo psinfo = new ProcessStartInfo(luacexe, args);
                psinfo.CreateNoWindow = true;
                psinfo.UseShellExecute = false;
                Process.Start(psinfo);
            }
        }
        EditorUtility.ClearProgressBar();
        AssetDatabase.Refresh();
    }

    static void CompileLuaFile(XLua.LuaEnv L, string source, string output)
    {
        byte [] sbts = File.ReadAllBytes(source);
        sbts = FileUtils.utf8FiliterRom(sbts);

        int ret = L.LuacExport(System.Text.Encoding.UTF8.GetString(sbts));
        IntPtr ptr = L.LuacGetBytes();
        if (ret <= 0)
        {
            UnityEngine.Debug.Log(L.DoString(sbts, source));
        }
        byte[] buffer = new byte[ret];
        Marshal.Copy(ptr, buffer, 0, ret);
        
        File.WriteAllBytes(output, buffer);
    }

    static void CopyLuaBytesFiles(string sourceDir, string destDir, bool appendext = true, string searchPattern = "*.lua", SearchOption option = SearchOption.AllDirectories)
    {
        if (!Directory.Exists(sourceDir))
        {
            return;
        }

        string[] files = Directory.GetFiles(sourceDir, searchPattern, option);
        int len = sourceDir.Length;

        if (sourceDir[len - 1] == '/' || sourceDir[len - 1] == '\\')
        {
            --len;
        }
        XLua.LuaEnv L = new XLua.LuaEnv();
        for (int i = 0; i < files.Length; i++)
        {
            string str = files[i].Remove(0, len);
            string dest = destDir + "/" + str;
			if (appendext && !dest.EndsWith(".bytes")) dest += ".bytes";
            string dir = Path.GetDirectoryName(dest);
            Directory.CreateDirectory(dir);
            CompileLuaFile(L, files[i], dest);
            //File.Copy(files[i], dest, true);
        }

        L.LuacClear();
        L.GC();
        L.Dispose();
    }


    [MenuItem("XLua/Copy Lua  files to Resources", false, 51)]
    public static void CopyLuaFilesToRes()
    {
        ClearAllLuaFiles();
        string destDir = Application.dataPath + "/" + ResourceBundle.RESOURCES_DIR + "/Lua";
        CopyLuaBytesFiles(Application.dataPath + "/Lua", destDir);
        CopyLuaBytesFiles(Application.dataPath + "/Lua", destDir, true, "*.lua.bytes");
        AssetDatabase.Refresh();
        UnityEngine.Debug.Log("Copy lua files over");
    }


    [MenuItem("XLua/Clear all Lua files", false, 57)]
    public static void ClearLuaFiles()
    {
        ClearAllLuaFiles();
        AssetDatabase.Refresh();
        UnityEngine.Debug.Log("Clear all Lua files over");
    }


    static void ClearAllLuaFiles()
    {
        string path = Application.dataPath + "/" + ResourceBundle.RESOURCES_DIR + "/Lua";

        if (Directory.Exists(path))
        {
            Directory.Delete(path, true);
        }
    }


    [MenuItem("Tools/SGK/Build", false, 57)]
    public static void BuildPackage() 
    {
        ClearAllLuaFiles();
        CopyLuaFilesToRes();
        CSObjectWrapEditor.Generator.ClearAll();
        CSObjectWrapEditor.Generator.GenAll();

        SGK.Database.LoadConfigFromServer();
        SGK.CharacterConfig.GenerateBattleCharacterConfig();
    }


    [MenuItem("Tools/SGK/Clean", false, 57)]
    public static void CleanPackage() 
    {
        ClearAllLuaFiles();
        CSObjectWrapEditor.Generator.ClearAll();
    }

    [MenuItem("Tools/SGK/Build Android APK (no config)", false, 57)]
    public static void BuildAndroidAPK() {
        ClearAllLuaFiles();
        CopyLuaFilesToRes();

        CSObjectWrapEditor.Generator.ClearAll();
        CSObjectWrapEditor.Generator.GenAll();

        // SGK.Database.LoadConfigFromServer();

        SGK.CharacterConfig.GenerateBattleCharacterConfig();

        string UNITY_CACHE_SERVER = System.Environment.GetEnvironmentVariable("UNITY_CACHE_SERVER");
        if (!string.IsNullOrEmpty(UNITY_CACHE_SERVER)) {
            EditorPrefs.SetBool("CacheServerEnabled", false);
            EditorPrefs.SetInt("CacheServerMode", 1);
            EditorPrefs.SetString("CacheServerIPAddress", UNITY_CACHE_SERVER);
        }

        string ANDROID_HOME = System.Environment.GetEnvironmentVariable("ANDROID_HOME");
        if (!string.IsNullOrEmpty(ANDROID_HOME)) {
            EditorPrefs.SetString("AndroidSdkRoot", System.Environment.GetEnvironmentVariable("ANDROID_HOME"));
        }
        // http://ndss.cosyjoy.com/sgk/patch/list.php
        BuildPipeline.BuildPlayer(EditorBuildSettings.scenes, "build/sgk.apk", BuildTarget.Android, BuildOptions.None);
    }

    [MenuItem("Tools/SGK/1. Scan AssetBundle", false, 57)]
    public static void BuildStep1() {
        AssetBundleGen.NamedAssetBundleName();
    }

    [MenuItem("Tools/SGK/2. Build AssetBundle)", false, 57)]
    public static void BuildStep2() {
        AssetBundleTool.CreateAndroidAssetBundle();
    }

    [MenuItem("Tools/SGK/3. Build Android APK (DEBUG)", false, 57)]
    public static void BuildAndroidAPKDebug() {
        var watch = new System.Diagnostics.Stopwatch();
        watch.Start();

        string ANDROID_HOME = System.Environment.GetEnvironmentVariable("ANDROID_HOME");
        if (!string.IsNullOrEmpty(ANDROID_HOME)) {
            EditorPrefs.SetString("AndroidSdkRoot", System.Environment.GetEnvironmentVariable("ANDROID_HOME"));
        }
        
        BuildPipeline.BuildPlayer(scenes, "build/sgk_debug.apk", BuildTarget.Android, BuildOptions.Development|BuildOptions.SymlinkLibraries|BuildOptions.ConnectWithProfiler);

        watch.Stop();
        UnityEngine.Debug.Log(string.Format("build package dela time {0}ms, {1}s, {2}min", watch.ElapsedMilliseconds, watch.ElapsedMilliseconds / 1000, watch.ElapsedMilliseconds / 1000 / 60));
    }

    [MenuItem("Tools/SGK/Build Android APK (RELEASE)", false, 57)]
    public static void BuildAndroidAPKWithAssetBundle()
    {
        Build(BuildTarget.Android, "build/sgk.apk");
    }

    [MenuItem("Tools/SGK/Build iOS package (RELEASE)", false, 57)]
    public static void BuildIOSWithAssetBundle() {
        Build(BuildTarget.iOS, "build/sgk");
    }

    static void Build(BuildTarget target, string path, BuildOptions opts = BuildOptions.None)
    {
        var watch = new System.Diagnostics.Stopwatch();
        watch.Start();

        ClearAllLuaFiles();
        CopyLuaFilesToRes();

        AssetBundleGen.NamedAssetBundleName();
        AssetBundleTool.CreateAndroidAssetBundle();

        CSObjectWrapEditor.Generator.ClearAll();
        CSObjectWrapEditor.Generator.GenAll();

        // SGK.Database.LoadConfigFromServer();

        // SGK.CharacterConfig.GenerateBattleCharacterConfig();
        /*
        string UNITY_CACHE_SERVER = System.Environment.GetEnvironmentVariable("UNITY_CACHE_SERVER");
        if (!string.IsNullOrEmpty(UNITY_CACHE_SERVER)) {
            EditorPrefs.SetBool("CacheServerEnabled", false);
            EditorPrefs.SetInt("CacheServerMode", 1);
            EditorPrefs.SetString("CacheServerIPAddress", UNITY_CACHE_SERVER);
        }
        */

        string ANDROID_HOME = System.Environment.GetEnvironmentVariable("ANDROID_HOME");
        if (!string.IsNullOrEmpty(ANDROID_HOME)) {
            EditorPrefs.SetString("AndroidSdkRoot", System.Environment.GetEnvironmentVariable("ANDROID_HOME"));
        }

        BuildPipeline.BuildPlayer(scenes, path, target, opts);
        watch.Stop();
        UnityEngine.Debug.Log(string.Format("build package dela time {0}ms, {1}s, {2}min", watch.ElapsedMilliseconds, watch.ElapsedMilliseconds / 1000, watch.ElapsedMilliseconds / 1000 / 60));
    }

    [MenuItem("Tools/Reimport all spine assets", false)]
    public static void ReimprotSpineAssets()
    {
        DirectoryInfo dir = new DirectoryInfo(Application.dataPath);
        var files = dir.GetFiles("*_SkeletonData.asset", SearchOption.AllDirectories);
        for (int i = 0; i < files.Length; ++i)
        {
            string path = files[i].Directory.FullName;
            
            if (UnityEditor.EditorUtility.DisplayCancelableProgressBar(string.Format("reimprot {0}/{1}", i, files.Length), path, (float)i / (float)files.Length))
            {
                UnityEditor.EditorUtility.ClearProgressBar();
                return;
            }

            var nfiles = new DirectoryInfo(path).GetFiles("*", SearchOption.AllDirectories);
            for (int k = 0; k < nfiles.Length; ++k)
            {
                string name = nfiles[k].Name;
                if (name.EndsWith(".txt") || name.EndsWith(".png") || name.EndsWith(".bytes"))
                {
                    continue;
                }
                File.Delete(nfiles[k].FullName);
            }
        }
        
        UnityEditor.EditorUtility.ClearProgressBar();
        UnityEditor.AssetDatabase.Refresh();
    }
}
