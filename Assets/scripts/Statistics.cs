using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Net;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Statistics {
    Dictionary<string, Dictionary<string, int>> StatCount;
    Dictionary<string, int> ScenesLoadedCount;

    static int StatisticsCount = 25;
    static JsonData gData;
    static bool ispreload = false;
#if UNITY_EDITOR
    public static bool enable = true;
#else
    public static bool enable = true;
#endif

    Statistics()
    {
        if (!enable)
        {
            return;
        }
        StatCount = new Dictionary<string, Dictionary<string, int>>();
        ScenesLoadedCount = new Dictionary<string, int>();

        UnityEngine.SceneManagement.SceneManager.sceneLoaded += (Scene scene, LoadSceneMode mode) =>
        {
            string sname = scene.name;

            if (!ScenesLoadedCount.ContainsKey(sname))
            {
                ScenesLoadedCount.Add(sname, 1);
            }
            else
            {
                ScenesLoadedCount[sname] += 1;
            }
        };
        
    }

    private static Statistics mgStat = new Statistics();
    private static Statistics mgStatWithoutDep = new Statistics();

    void addAsset(string name, bool withdep)
    {
        // Debug.LogFormat("statistics: name:{0}, is preload:{1}", name, ispreload);
        if (ispreload || !enable)
        {
            return;
        }
        string sname = SceneManager.GetActiveScene().name;

        if (!StatCount.ContainsKey(sname))
        {
            StatCount.Add(sname, new Dictionary<string, int>());
        }

        var sta = StatCount[sname];
        if (withdep)
        {
#if UNITY_EDITOR
            string[] deps = UnityEditor.AssetDatabase.GetDependencies(name, true);
            foreach (var dep in deps)
            {
                if (dep.EndsWith(".cs") || dep.EndsWith(".unity") || dep.IndexOf(".lua") > 0)
                {
                    continue;
                }

                if (sta.ContainsKey(dep))
                {
                    sta[dep] += 1;
                }
                else
                {
                    sta.Add(dep, 1);
                }
            }
#endif
        }else
        {
            if (sta.ContainsKey(name))
            {
                sta[name] += 1;
            }
            else
            {
                sta.Add(name, 1);
            }
        }

    }

    public static void AddAsset(string name)
    {
        // mgStat.addAsset(name, true);
        mgStatWithoutDep.addAsset(name, false);
    }


    public static  void SendData()
    {
        //mgStat.ConvertToJson("http://10.1.2.79/stat/report.php", false);
        //mgStatWithoutDep.ConvertToJson("http://10.1.2.79/stat/report2.php", true);
    }

    public static void GetCache(MonoBehaviour mb)
    {
        mb.StartCoroutine(GetCache());
    }

    public static void PreLoadAsset(string name)
    {
        ispreload = true;
        if (gData != null )
        {
            for (int i = 0; i < gData.datas.Length; ++i)
            {
                var s = gData.datas[i];
                if (s.name == name)
                {

                    for (int k = 0; k < s.objects.Length; ++k)
                    {
                        SGK.ResourcesManager.LoadAsync(s.objects[k].asset);
                    }
                    Debug.LogFormat("statistics: scene: {0} preload asset count: {1}", name, s.objects.Length);
                    break;
                }
            }
        }
        ispreload = false;
    }

#region json
    [Serializable]
    class JsonObject
    {
        public string asset;
        public int count;
    }

    [Serializable]
    class JsonScene
    {
        public string name;
        public int count;
        public JsonObject[] objects;
    }

    [Serializable]
    class JsonData
    {
        public JsonScene[] datas;
    }
    
     void ConvertToJson(string url, bool limit)
    {
#if UNITY_EDITOR
        if (!enable)
        {
            return;
        }

        JsonData data = new JsonData();
        data.datas = new JsonScene[StatCount.Count];

        int i = 0, k = 0;
        foreach (var itc in StatCount)
        {
            Dictionary<string, int> assets = itc.Value;
            JsonScene scene = new JsonScene();
            data.datas[i++] = scene;
            scene.name = itc.Key; 
            scene.count = ScenesLoadedCount[itc.Key];

            List<string> l = new List<string>();
            foreach (var it in assets)
            {
                if (it.Value > 1 || !limit)
                {
                    l.Add(it.Key);
                }
            }

            l.Sort((a, b) => {
                if (assets[a] > assets[b])
                {
                    return -1;
                }
                else
                {
                    return 1;
                }
            });

            int c = l.Count;
            if (limit)
            {
                c = l.Count > StatisticsCount ? StatisticsCount : l.Count;
            }
            scene.objects = new JsonObject[c];

            for (k = 0; k < c; ++k)
            {
                JsonObject obj = new JsonObject();
                obj.asset = l[k];
                obj.count = assets[obj.asset];
                scene.objects[k] = obj;
            }
            
        }

        string str = JsonUtility.ToJson(data);
        Debug.Log(str);

        WebRequest myRequest = WebRequest.Create(url);
        myRequest.Method = "POST";
        myRequest.ContentType = "application/x-www-form-urlencoded";

        Stream reqs = myRequest.GetRequestStream();
        byte[] ds = System.Text.Encoding.UTF8.GetBytes("data=" + str);
        reqs.Write(ds, 0, ds.Length);
        reqs.Close();

        HttpWebResponse myResponse = (HttpWebResponse)myRequest.GetResponse();
        if (myResponse.StatusCode != HttpStatusCode.OK)
        {
            Debug.LogErrorFormat("send statistics failed", myResponse.StatusDescription);
            return;
        }
        
        Stream myStream = myResponse.GetResponseStream();
        StreamReader myReader = new StreamReader(myStream);

        string s = myReader.ReadToEnd();
        Debug.Log(s);
#endif
    }

    static IEnumerator GetCache()
    {
        string url = "http://10.1.2.79/stat/index3.php";
        WWW w = new WWW(url);
        yield return w;

        JsonData info = JsonUtility.FromJson<JsonData>(w.text);
        gData = info; 
    }
#endregion
}
