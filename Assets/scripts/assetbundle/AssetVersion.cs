using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

public class AssetVersion
{

    public static string VersionFileName = "AssetVersion";

    static string mVersion;
    static string mAssetCoreVersion;
    static Dictionary<string, List<string>> mBundles;
    static List<string> mCurrent;
    static List<string> mVersionList = new List<string>();

    static bool inited = false;
    static void init()
    {
        if (inited)
        {
            return;
        }
        inited = true;

        string fdata = null;
        string path = Path.Combine(Application.persistentDataPath, VersionFileName + ".txt");
        if (File.Exists(path))
        {
            fdata = File.ReadAllText(path);
        }

        if (string.IsNullOrEmpty(fdata))
        {
            var ta = Resources.Load<TextAsset>(VersionFileName);
            if (ta)
            {
                fdata = ta.text.Replace("\n", "");
            }
        }

        if (string.IsNullOrEmpty(fdata))
        {
            fdata = "0";
        }

        mBundles = new Dictionary<string, List<string>>();
        string[] ds = fdata.Split('\n');
        if (ds.Length == 0)
        {
            return;
        }

        mVersion = ds[0];
        Debug.LogFormat("Asset version : {0}, asset core version : {1}", fdata, AssetCoreVersion);
        List<string> last = null;
        string str = null;
        for (int i = 1; i < ds.Length; ++i)
        {
            str = ds[i];
            if (string.IsNullOrEmpty(str))
            {
                continue;
            }
            if (str.IndexOf("v:") >= 0)
            {
                last = new List<string>();
                mBundles.Add(str.Replace("v:", ""), last);
            }
            else
            {
                last.Add(str.Trim());
            }
        }
    }

    public static string Version
    {
        get
        {
            init();
            if (mVersion != null)
                return mVersion;
            mVersion = "0";
            return mVersion;
        }
        set
        {
            if (Version.Equals(value))
                return;
            mVersion = value;
        }
    }

    public static string AssetCoreVersion
    {
        get
        {
            if (mAssetCoreVersion != null)
                return mAssetCoreVersion;

            var ta = Resources.Load<TextAsset>(VersionFileName);
            mAssetCoreVersion = ta.text.Replace("\n", "");

            mVersionList.Add(mAssetCoreVersion);

            return mAssetCoreVersion;
        }
    }

    public static Dictionary<string, List<string>> Version2Bundles
    {
        get
        {
            init();
            return mBundles;
        }
    }

    public static void ClearBundle(string v)
    {
        List<string> l = null;
        if (mBundles.TryGetValue(v, out l))
        {
            l.Clear();
            mBundles.Remove(v);
        }
    }

    public static void StartAddBundle(string v)
    {
        if (mBundles.TryGetValue(v, out mCurrent))
        {
            mCurrent.Clear();
        }
        else
        {
            mCurrent = new List<string>();
            mBundles.Add(v, mCurrent);
        }
    }

    public static void EndAddBundle()
    {
        mCurrent = null;
    }

    public static void AddBundle(string bundle)
    {
        // mCurrent.Add(bundle.ToLower());
        mCurrent.Add(bundle);
    }

    public static void Flush()
    {
        string path = Path.Combine(Application.persistentDataPath, VersionFileName + ".txt");
        if (!File.Exists(path))
        {
            var f = File.Create(path);
            f.Close();
        }
        string value = mVersion;
        foreach (var iter in mBundles)
        {
            value += "\nv:" + iter.Key;
            for (int i = 0; i < iter.Value.Count; ++i)
            {
                value += "\n" + iter.Value[i];
            }
        }

        File.WriteAllText(path, value);
    }

    public static void AddVersionList(string ver)
    {
        mVersionList.Add(ver);
    }

    public static bool Equals(string ver)
    {
        return mVersionList[mVersionList.Count - 1].Equals(ver);
    }

    public static bool GreaterThan(string ver)
    {
        int idx = mVersionList.IndexOf(ver);

        return idx >= 0 && idx < mVersionList.Count - 1;
    }

    public static bool Contains(string ver)
    {
        return mVersionList.Contains(ver);
    }
}
