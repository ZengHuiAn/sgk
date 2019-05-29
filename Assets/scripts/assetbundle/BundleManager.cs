using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using System;
using System.Net;

public class BundleManager {

    static Dictionary<string, List<System.Action<Bundle>>> LoadingList = new Dictionary<string, List<System.Action<Bundle>>>();

    static void addList(string name, System.Action<Bundle> cb)
    {
        List<System.Action<Bundle>> l = null;
        if (!LoadingList.TryGetValue(name, out l))
        {
            l = new List<System.Action<Bundle>>();
            LoadingList.Add(name, l);
        }
        if (cb != null)
        {
            l.Add(cb);
        }
    }

    public static void Clear()
    {
        LoadingList.Clear();
    }

    public static bool isThreadOpened()
    {
        return !string.IsNullOrEmpty(SGK.PatchManager.bundleURL);
    }

    public static string GetFullName (string name)
    {
        string ret = null;
        do
        {
            // 1.
            string path = Application.persistentDataPath + "/" + AssetVersion.Version + "/" + name;
            if (File.Exists(path))
            {
                ret = path;
                break;
            }
            // 2.
            if (SGK.PatchManager.PatchFiles.ContainsKey(name))
            {
                ret = Application.persistentDataPath + "/" + SGK.PatchManager.PatchFiles[name] + "/" + name;
                break;
            }
            // 3.
            if (FileEncrypt.BundleExistInPackage(name))
            {
                ret = Application.streamingAssetsPath + "/" + name;
                break;
            }
        } while (false);

        return ret;
    }

    public static Bundle LoadAssetBundle(string name)
    {
        string fullname = GetFullName(name);
        if (fullname != null)
        {
            return Bundle.LoadFromFile(fullname);
        }

        if (isThreadOpened())
        {
            addList(name, null);
        }

        return null;
    }

    public static Bundle LoadAssetBundle(string name, System.Action<Bundle> cb)
    {
        string fullname = GetFullName(name);
        Bundle b = null;
        if (fullname != null)
        {
            b = Bundle.LoadFromFile(fullname);
            if (cb != null)
            {
                cb(b);
            }
        }
        else
        {
            if (isThreadOpened())
            {
                addList(name, cb);
            }
            else
            {
                if (cb != null)
                {
                    cb(b);
                }
            }
        }

        return b;
    }

    public static IEnumerator DownAndLoadThread()
    {
        while(isThreadOpened())
        {
            var it = LoadingList.GetEnumerator();
            if (it.MoveNext())
            {
                string name = it.Current.Key;
                string path = AssetVersion.Version + "/" + name;
                string url = SGK.PatchManager.bundleURL + "/" + name;

                Debug.Log("DownAndLoadThread url :" + url);
                WWW w = new WWW(url);
                yield return w;
                Debug.Log("DownAndLoadThread completed url :" + url);
                Bundle b = null;
                if (w.error != null && !w.error.Equals(""))
                {
                    Debug.LogError("bundle down error :" + w.error + ", url : " + url);
                }
                else
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

                    path = Application.persistentDataPath + "/" + AssetVersion.Version + "/" + name;
                    File.WriteAllBytes(path, w.bytes);
                    b = Bundle.LoadFromFile(path);
                }

                var l = it.Current.Value;
                foreach (var cb in l)
                {
                    cb(b);
                }

                LoadingList.Remove(name);
            }
            
            yield return null;
        }
    }
}
