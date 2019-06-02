using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class BuildPackageShell {

    //1.gen asset bundle package
    [MenuItem("build shell/MakeAssetBundleAndroid")]
    static void MakeAssetBundleAndroid()
    {
        CSObjectWrapEditor.Generator.ClearAll();
        CSObjectWrapEditor.Generator.GenAll();

        CreateAssetBundles.ClearLuaFiles();
        CreateAssetBundles.CopyLuaFilesToRes();

        AssetBundleGen.NamedAssetBundleName();
        AssetBundleTool.CreateAndroidAssetBundle();
    }

    [MenuItem("build shell/MakePackageAndroid")]
    static void MakePackageAndroid()
    {
        string UNITY_CACHE_SERVER = System.Environment.GetEnvironmentVariable("UNITY_CACHE_SERVER");
        if (!string.IsNullOrEmpty(UNITY_CACHE_SERVER))
        {
            EditorPrefs.SetBool("CacheServerEnabled", false);
            EditorPrefs.SetInt("CacheServerMode", 1);
            EditorPrefs.SetString("CacheServerIPAddress", UNITY_CACHE_SERVER);
        }

        string ANDROID_HOME = System.Environment.GetEnvironmentVariable("ANDROID_HOME");
        if (!string.IsNullOrEmpty(ANDROID_HOME))
        {
            EditorPrefs.SetString("AndroidSdkRoot", System.Environment.GetEnvironmentVariable("ANDROID_HOME"));
        }
        BuildPipeline.BuildPlayer(CreateAssetBundles.scenes, "build/sgk.apk", BuildTarget.Android, BuildOptions.Development);
    }
}
