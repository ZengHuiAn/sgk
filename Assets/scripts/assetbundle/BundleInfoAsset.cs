using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

[System.Serializable]
public class BundleInfo
{
    public long size;
    public string name;
    public List<string> files;


    public BundleInfo()
    {
        size = 0;
        name = null;
        files = new List<string>();
    }

    public BundleInfo(string name)
    {
        this.name = name;
        this.size = 0;
        this.files = new List<string>();
    }
}

[CreateAssetMenu]
public class BundleInfoAsset : ScriptableObject
{
    public List<BundleInfo> BundleInfos;
}

public class BundleInfoManager
{
    public static string AssetName = "BundleAsset.asset";
    public static string AssetBundleName = "bundleasset";

    static BundleInfoAsset mBundleAsset;
    static Dictionary<string, BundleInfo> mBundles;
    
#if UNITY_EDITOR
    static List<string> EmptyBundleNames = new List<string>();

    public static void InitEditor()
    {
        EmptyBundleNames = new List<string>();
        for (int i = 0; i < 10; ++i)
        {
            for (int k = 0; k < 10; ++k)
            {
                for (int j = 0; j < 10; ++j)
                {
                    for (int a = 0; a < 10; ++a)
                    {
                        string str = "";
                        str += i.ToString();
                        str += k.ToString();
                        str += j.ToString();
                        str += a.ToString();
                        EmptyBundleNames.Add(str);
                    }
                }
            }
        }
        try
        {
            mBundleAsset = UnityEditor.AssetDatabase.LoadAssetAtPath<BundleInfoAsset>(AssetManager.RootPath + "/" + AssetBundleName + "/" + AssetName);
        }
        catch (System.Exception)
        {
            Debug.Log("BundleInfoManager can not found asset");
        }

        if (mBundleAsset == null)
        {
            mBundles = null;
            mBundleAsset = null;
            return;
        }

        BundleInfo d = null;
        mBundles = new Dictionary<string, BundleInfo>();

        for (int i = 0; i < mBundleAsset.BundleInfos.Count; ++i)
        {
            d = mBundleAsset.BundleInfos[i];
            EmptyBundleNames.Remove(Path.GetFileName(d.name));

            for (int k = 0; k < d.files.Count; ++k)
            {
                if (mBundles.ContainsKey(d.files[k]))
                {
                    Debug.Log(d.files[k] + "   " + d.name + "  " + mBundles[d.files[k]].name);
                }
                mBundles.Add(d.files[k], d);
            }
        }
    }

    public static string GetEmptyBundleName()
    {
        string str = "";
        if (EmptyBundleNames.Count > 0)
        {
            str = EmptyBundleNames[0];
            EmptyBundleNames.RemoveAt(0);
        }

        return str;
    }

#endif

    public static void Init()
    {
#if UNITY_EDITOR
        if (AssetManager.SimulateMode)
        {
            return;
        }
#endif
        try
        {
            mBundleAsset = AssetManager.LoadAssetWithBundle<BundleInfoAsset>(AssetBundleName, AssetManager.RootPath + "/" + AssetBundleName + "/" + AssetName);
        }
        catch (System.Exception)
        {
            Debug.Log("BundleInfoManager can not found asset");
        }

        if (mBundleAsset == null)
        {
            mBundles = null;
            mBundleAsset = null;
            return;
        }

        BundleInfo d = null;
        mBundles = new Dictionary<string, BundleInfo>();

        for (int i = 0; i < mBundleAsset.BundleInfos.Count; ++i)
        {
            d = mBundleAsset.BundleInfos[i];

            for (int k = 0; k < d.files.Count; ++k)
            {
                if (mBundles.ContainsKey(d.files[k]))
                {
                    Debug.Log(d.files[k] + "   " + d.name + "  " + mBundles[d.files[k]].name);
                }
                mBundles.Add(d.files[k], d);
            }
        }
    }

    public static string GetBundleNameWithFullPath(string path)
    {
#if UNITY_EDITOR
        if (AssetManager.SimulateMode)
        {
            return path;
        }
#endif 
        // return path.Substring(0, path.LastIndexOf('/'));
        string str = null;
        BundleInfo d = null;
        if (mBundles != null && mBundles.TryGetValue(path.ToLower(), out d))
        {
            str = d.name;
        }else
        {
        //    Debug.LogErrorFormat("GetBundleNameWithFullPath not found file '{0}'", path);
        }
        return str;
    }

    public static BundleInfo GetBundleInfoWithFullPath(string path)
    {
        if (mBundles == null)
        {
            return null;
        }
        BundleInfo d = null;
        mBundles.TryGetValue(path.ToLower(), out d);

        return d;
    }

    public static bool CheckContainBundle(string name)
    {
        if (mBundles == null)
        {
            return false;
        }

        return null == mBundleAsset.BundleInfos.Find((info) => {
            return info.name == name;
        });
    }

    public static BundleInfoAsset GetAsset()
    {
        return mBundleAsset;
    }
}