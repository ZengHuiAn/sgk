using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using SGK;

public class Bundle
{
    public AssetBundle Asset;
    public string FullName;
    Stream fileStream;
    Dictionary<string, Dictionary<string, Object>> mSubAssets = null;
    Dictionary<string, Object> mAssets = null;
    Dictionary<string, List<System.Action<Object>>> mAsyncs = null;

    
    
    public static Bundle LoadFromFile(string name)
    {
        var b = new Bundle(name);
        if (b.loadAssetBundle())
        {
            return b;
        }

        return null;
    }

    public Bundle(string FullName)
    {
        this.FullName = FullName;// name.ToLower();
    }

    public bool loadAssetBundle()
    {
        if (Asset == null)
        {
            Asset = FileEncrypt.LoadFromFile(FullName, out fileStream);
            mAssets = new Dictionary<string, Object>();
            mAsyncs = new Dictionary<string, List<System.Action<Object>>>();
        }
        return Asset != null;
    }

    IEnumerator loadAssetBundleSync()
    {
        if (Asset == null)
        {
            var req = FileEncrypt.LoadFromFileAsync(FullName, out fileStream);
            if (req.assetBundle == null)
            {
                yield return null;
            }
            Asset = req.assetBundle;
            if (Asset == null && fileStream != null) {
                fileStream.Dispose();
                fileStream = null;
            }
            mAssets = new Dictionary<string, Object>();
            mAsyncs = new Dictionary<string, List<System.Action<Object>>>();
        }
    }

    public bool Unload(bool all)
    {
        if ( Asset != null)
        {
            Asset.Unload(all);
            if (fileStream != null) {
                fileStream.Dispose();
                fileStream = null;
            }
            if (mSubAssets != null)
            {
                mSubAssets.Clear();
            }
            if (mAssets != null)
            {
                mAssets.Clear();
            }
            if (mAsyncs != null)
            {
                mAsyncs.Clear();
            }
            return true;
        }
        return false;
    }

    public Object LoadAsset(string name)
    {
        return LoadAsset<Object>(name);
    }

    public Object LoadAsset(string name, System.Type type)
    {
        if (Asset == null)
            return null;
        return Asset.LoadAsset(name, type);
    }

    public T LoadAsset<T>(string name) where T : Object
    {
        if (Asset == null)
            return null;
        return Asset.LoadAsset<T>(name);
    }

    public Object LoadAssetWithSubAssets(string name, string sub)
    {
        Object ret = null;
        if (Asset)
        {
            Dictionary<string, Object> assets = null;
            if (mSubAssets != null)
            {
                if (mSubAssets.TryGetValue(name, out assets))
                {
                    assets.TryGetValue(sub, out ret);
                    return ret;
                }
            }

            if (mSubAssets == null)
            {
                mSubAssets = new Dictionary<string, Dictionary<string, Object>>();
            }

            assets = new Dictionary<string, Object>();

            Object[] objs = Asset.LoadAssetWithSubAssets(name);
            Object temp = null;
            for (int i = 0; i < objs.Length; ++i)
            {
                temp = objs[i];
                assets.Add(temp.name, temp);
                if (ret == null && temp.name == sub)
                {
                    ret = temp;
                }
            }
            mSubAssets.Add(name, assets);
        }
        return ret;
    }

#region load asset async
    protected class AsyncOperator
    {
        public Bundle b;
        public System.Type t;
        public string path;

        public AsyncOperator(Bundle b, System.Type t, string path)
        {
            this.b = b;
            this.t = t;
            this.path = path;
        }
    }

    static List<AsyncOperator> ops = new List<AsyncOperator>();
    public static void StartAsyncOperator()
    {
        SGK.ResourcesManager.GetLoader().StartCoroutine(Async());
    }
    public static int Number = 1;
    static IEnumerator Async()
    {
        int c = 0;
        bool b = false;
        do 
        {
            b = false;

            if (ops.Count > 0)
            {
                var op = ops[0];
                ops.RemoveAt(0);
                if (op.b.Asset == null)
                {
                    continue;
                }
                SGK.ResourcesManager.GetLoader().StartCoroutine(AsyncLoad(op));
                b = true;
                c += 1;
            }
            if (c >= Number || !b)
            {
                c = 0;
                yield return null;
            }
        } while (true);
    }

    static IEnumerator AsyncLoad(AsyncOperator op)
    {
        var b = op.b;
        var path = op.path;
        AssetBundleRequest req = b.Asset.LoadAssetAsync(path, op.t);
        if (req.asset == null)
        {
            yield return req;
        }

        List<System.Action<Object>> cbs = null;
        if (b.mAsyncs.TryGetValue(path, out cbs))
        {
            for (int i = 0; i < cbs.Count; ++i)
            {
                cbs[i](req.asset);
            }
            cbs.Clear();
            b.mAsyncs.Remove(path);
        }
    }

    public void LoadAssetAsync(MonoBehaviour behaviour, string name, System.Action<Object> callback = null)
    {
        LoadAssetAsync(behaviour, name, typeof(Object), callback);
    }

    public void LoadAssetAsync(MonoBehaviour behaviour, string name, System.Type type, System.Action<Object> callback = null)
    {
        Object obj = null;

        if (Asset == null)
        {
            if (callback != null)
            {
                callback(obj);
            }
            return;
        }

        List<System.Action<Object>> list = null;
        if (mAsyncs.TryGetValue(name, out list))
        {
            if (callback != null)
            {
                list.Add(callback);
            }
            return;
        }

        list = new List<System.Action<Object>>();
        if (callback != null)
        {
            list.Add(callback);
        }

        mAsyncs.Add(name, list);

        string ext = Path.GetExtension(name);
        if(ext == ".png" || ext == ".jpg" || ext == ".tga")
        {
            ops.Add(new AsyncOperator(this, type, name));    
        }else
        {
            behaviour.StartCoroutine(LoadThread(name, type));    
        }
    }

    IEnumerator LoadThread(string path, System.Type type)
    {
        AssetBundleRequest req = Asset.LoadAssetAsync(path, type);
        if (req.asset == null)
        {
            yield return req;
        }
        
        List<System.Action<Object>> cbs = null;
        if (mAsyncs.TryGetValue(path, out cbs))
        {
            for (int i = 0; i < cbs.Count; ++i)
            {
                cbs[i](req.asset);
            }
            cbs.Clear();
            mAsyncs.Remove(path);
        }
    }
    #endregion
}
