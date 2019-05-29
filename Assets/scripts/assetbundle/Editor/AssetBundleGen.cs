using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using UnityEditor;
using System;
using System.Text.RegularExpressions;
using System.Text;

public class FileComparer : IComparer<FileInfo>
{
    public int Compare(FileInfo x, FileInfo y)
    {
        if (!x.Exists)
        {
            return 1;
        }
        if ( !y.Exists)
        {
            return -1;
        }

        if (x.Length > y.Length)
        {
            return 1;
        }else if (x.Length == y.Length)
        {
            return 0;
        }
        else
        {
            return -1;
        }
    }
}

public class AssetBundleGen
{

    static string RootDir = "assetbundle";

    static int BundleMinSize = 1024 * 1024 * 10;
    static string[] igs = new string[] {
        ".meta",
        ".cs",
        ".dll",
        ".unity",
    };

    public static string CommonAssets = "common";
    public static string DataAssets = "data";

    /*
    static char[] BASE32 = new char[]
    {
        'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
    };
    */

    static Dictionary<string, float> FileSizeWight = new Dictionary<string, float>()
    {
        { ".png", 0.8f },
        { ".tga", 0.8f },
        { ".jpg", 5f },
        { ".bytes", 0.5f },
        { ".txt", 0.5f },
        { ".prefab", 0.1f},
        { ".mat", 0.6f},
        { ".asset", 0.8f}
    };

    static string GetBundlesInfoName(string path)
    {
        path = path.ToLower();
        if (path.IndexOf(".unity") > 0)
        {
            return Path.GetFileName(path);
        }

        return path;
    }

    static long GetFileSize(string path, long size)
    {
        float w = 1f;
        string ext = Path.GetExtension(path).ToLower();
        if (!FileSizeWight.TryGetValue(ext, out w))
        {
            w = 1f;
        }
        return (long) Mathf.FloorToInt(w * size);
    }

    static bool CheckIgnore(string path)
    {
        for (int i = 0; i < igs.Length; ++i)
        {
            if (path.IndexOf(igs[i]) > 0)
            {
                return true;
            }
        }

        if (path.ToLower().IndexOf("/resources/") > 0)
        {
            return true;
        }

        return false;
    }

    static string ToBaseString(string str)
    {
        return str.Replace("/", "").Replace(".", "").Replace("_", "");
        /*
        var strsStrings = str.ToCharArray();
        char[] ret = new char[strsStrings.Length];
        for (int index = 0; index < strsStrings.Length; index++)
        {
            char v = strsStrings[index];
            ret[index] = BASE32[(int)v % BASE32.Length];
        }
        return new string(ret);
        */
    }

    public static string ReplaceChinese(string str)
    {
        string retValue = str;
        if (Regex.IsMatch(str, @"[\u4e00-\u9fa5]"))
        {
            // 65 -- 90
            retValue = string.Empty;
            var strsStrings = str.ToCharArray();
            for (int index = 0; index < strsStrings.Length; index++)
            { 
                char v = strsStrings[index];
                if (v >= 0x4e00 && v <= 0x9fa5)
                {
                    // 65 - 90 A - Z
                    v = (char)((int)v % 25 + 65);
                }
                retValue += v;
            }
        }
        return retValue;
    }

    static string GetAssetBundleNameWithFullDirectoryName(string fullName)
    {
        return fullName.Replace("\\", "/").Replace(Application.dataPath + "/" + RootDir + "/", "").ToLower();
    }

    static void SetAssetBundleName(string filePath, string name)
    {
        var importer = AssetImporter.GetAtPath(filePath);
        name = ReplaceChinese(name);
        if (importer)
        {
            if (importer.assetBundleName != name)
            {
                importer.assetBundleName = name;
            }
        }
    }

    static bool ReBuildAssetBundles(string directory, List<FileInfo> ofiles, List<FileInfo> nfiles, 
        ref List<BundleInfo> bundles, ref int count, 
        bool igoresize = false)
    {
        List<BundleInfo> oldlbds = new List<BundleInfo>();
        ofiles.Sort(new FileComparer());
        nfiles.Sort(new FileComparer());
        directory = directory == CommonAssets ? CommonAssets : DataAssets;

        for (int i = 0; i < ofiles.Count; ++i)
        {
            var f = ofiles[i];
            string filePath = f.FullName.Replace('\\', '/').Replace(Application.dataPath, "Assets");
            string nfp = GetBundlesInfoName(filePath);// filePath.Replace("Assets/" + RootDir + "/", "").ToLower();
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("name {0}/{1}", i, ofiles.Count), filePath, (float)i / (float)ofiles.Count))
            {
                return false;
            }
            var bdi = BundleInfoManager.GetBundleInfoWithFullPath(nfp);
            var nbdi = bundles.Find((info) =>
            {
                return info.name == bdi.name;
            });
            if (nbdi == null)
            {
                nbdi = new BundleInfo(bdi.name);

                bundles.Add(nbdi);
            }

            if (!oldlbds.Contains(nbdi))
            {
                oldlbds.Add(nbdi);
            }
            count++;

            nbdi.files.Add(nfp);
            nbdi.size += f.Length;
            SetAssetBundleName(filePath, nbdi.name);
        }

        BundleInfo cbdi = null;
        // find min bundle, ready for insert
        for (int i = 0; i < oldlbds.Count; ++i)
        {
            var v = oldlbds[i];
            if (cbdi != null)
            {
                if (v.size < cbdi.size)
                {
                    cbdi = v;
                }
                
                continue;
            }

            if (v.size < BundleMinSize)
            {
                cbdi = v;
            }
        }

        for (int i = 0; i < nfiles.Count; ++i)
        {
            var f = nfiles[i];
            string filePath = f.FullName.Replace('\\', '/').Replace(Application.dataPath, "Assets");

            if (EditorUtility.DisplayCancelableProgressBar(string.Format("name {0} {1}/{2}", directory, i, nfiles.Count), filePath, (float)i / (float)nfiles.Count))
            {
                return false;
            }

            string nfp = GetBundlesInfoName(filePath);
            long size = GetFileSize(filePath, f.Length);

            if (cbdi == null)
            {
                cbdi = new BundleInfo(directory + "/" + BundleInfoManager.GetEmptyBundleName());
                bundles.Add(cbdi);
            }

            if (size > BundleMinSize * 1.5 && !igoresize)
            {
                var nbdi = new BundleInfo(directory + "/" + BundleInfoManager.GetEmptyBundleName());
                bundles.Add(nbdi);
                nbdi.files.Add(nfp);
                SetAssetBundleName(filePath, nbdi.name);
                Debug.LogFormat("file '{0}' is large {1}", filePath, size);
            }
            else
            {
                cbdi.files.Add(nfp);
                cbdi.size += f.Length;
                SetAssetBundleName(filePath, cbdi.name);

                if (cbdi.size > BundleMinSize && !igoresize)
                {
                    cbdi = null;
                }
            }
            count++;
        }

        return true;
    }

    static long MatchFileInfoWithDeps(string path, ref List<FileInfo> olist, ref List<FileInfo> nlist, ref Dictionary<string, List<string>> buildin, ref HashSet<string> named, ref long csize)
    {
        long size = MatchFileInfo(path, ref olist, ref nlist, ref buildin, ref named, ref csize);
        if (size == 0)
        {
            return size;
        }
        string [] deps = AssetDatabase.GetDependencies(path, false);
        foreach (var dep in deps)
        {
            if (path.Equals(dep) || dep.EndsWith(".spriteatlas"))
            {
                continue;
            }

            if (CheckIgnore(dep))
            {
                continue;
            }

            size += MatchFileInfoWithDeps(dep, ref olist, ref nlist, ref buildin, ref named, ref csize);
        }

        return size;
    }

    static long MatchFileInfo(string path, ref List<FileInfo>  olist, ref List<FileInfo> nlist, 
        ref Dictionary<string, List<string>> buildin, 
        ref HashSet<string> named, ref long csize, HashSet<string> obs = null)
    {
        if (buildin != null)
        {
            foreach (var b in  buildin)
            {
                if(path.IndexOf(b.Key) >= 0)
                {
                    b.Value.Add(path);
                    return 0;
                }
            }
        }

        if (named.Contains(path))
        {
            return 0;
        }

        try
        {
            string fullpath = Path.Combine(Application.dataPath.Replace("Assets", ""), path);
            FileInfo fs = new FileInfo(fullpath);
            if (!fs.Exists)
            {
                return 0;
            }

            string nfp = GetBundlesInfoName(path);
            var bi = BundleInfoManager.GetBundleInfoWithFullPath(nfp);
            if (bi == null)
            {
                nlist.Add(fs);
            }
            else if (obs != null && Path.GetDirectoryName(bi.name) != CommonAssets)
            {
                nlist.Add(fs);
            }
            else if (obs == null && Path.GetDirectoryName(bi.name) == CommonAssets)
            {
                nlist.Add(fs);
            }
            else
            {
                olist.Add(fs);
            }

            named.Add(path);
            long fsize = GetFileSize(path, fs.Length);
            csize += fsize;
            return fsize;
        }catch(Exception ex)
        {
            Debug.Log(ex);
        }
        return 0;
    }

    static string GetImplicitAssetBundleName(string path)
    {
        var importer = AssetImporter.GetAtPath(path);
        if (importer)
        {
            return importer.assetBundleName;
        }
        return "";
    }

    static bool CollectDependcies(string filepath, ref Dictionary<string, int> redeps, 
        ref Dictionary<string, List<string>> assets, ref HashSet<string> searched, ref HashSet<string> igorelist, 
        ref HashSet<string> obs, bool isobs = false)
    {
        if (obs.Contains(filepath))
        {
            return true;
        }

        if (isobs)
        {
            obs.Add(filepath);
        }else
        {
            try
            {
                string vn = GetImplicitAssetBundleName(filepath);
                if (vn.IndexOf(CommonAssets) == 0)
                {
                    isobs = true;
                    obs.Add(filepath);
                }
            }
            catch (System.Exception)
            {
                // Debug.Log("CollectDependcies:" + e.ToString());
            }
        }

        if (searched.Contains(filepath))
        {
            return isobs;
        }

        List<string> ass = null;
        searched.Add(filepath);

        if (filepath.EndsWith(".spriteatlas"))
        {
            igorelist.Add(filepath);
            return false;
        }
        
        
        string[] deps = AssetDatabase.GetDependencies(filepath, false);
        foreach (var dep in deps)
        {
            if (filepath.Equals(dep))
            {
                continue;
            }

            if (CheckIgnore(dep))
            {
                continue;
            }

            if (dep.EndsWith(".spriteatlas"))
            {
                igorelist.Add(dep);
                continue;
            }

            bool ret = CollectDependcies(dep, ref redeps, ref assets, ref searched, ref igorelist, ref obs, isobs);
            if (!ret)
            { 
                if (ass == null)
                {
                    ass = new List<string>();
                    assets.Add(filepath, ass);
                }
                ass.Add(dep);
                if (!redeps.ContainsKey(dep))
                {
                    redeps[dep] = 0;
                }
                redeps[dep] += 1;
            }
        }

        return isobs;
    }
    
    static void MergeAssets(string filepath, ref Dictionary<string, List<string>> assets, ref Dictionary<string, int> redeps, ref HashSet<string> merged, ref HashSet<string> removed)
    {
        if (merged.Contains(filepath))
        {
            return;
        }
        merged.Add(filepath);

        List<string> deps = null;
        if (!assets.TryGetValue(filepath, out deps))
        {
            return;
        }

        List<string> ndeps = new List<string>();
        for (int i = 0; i < deps.Count; ++i)
        {
            int ct = 0;
            string dep = deps[i];
            redeps.TryGetValue(dep, out ct);

            if ((ct <= 1))
            // if (assets.ContainsKey(dep) && ! removed.Contains(dep))
            {
                if (assets.ContainsKey(dep))
                {
                    MergeAssets(dep, ref assets, ref redeps, ref merged, ref removed);
                    ndeps.AddRange(assets[dep]);
                    removed.Add(dep);
                }
                ndeps.Add(dep);
            }
        }
        deps.Clear();
        deps.AddRange(ndeps);
    }

    static bool NameAssets(string directory, List<string> assetkeys, ref Dictionary<string, List<string>> assets, 
        ref Dictionary<string, int> redeps, 
        ref HashSet<string> named, 
        ref Dictionary<string, List<string>> buildin,
        ref List<BundleInfo> bundles, ref int count, ref long ctsize)
    {
        long csize = 0;
        List<FileInfo> ofiles = new List<FileInfo>();
        List<FileInfo> nfiles = new List<FileInfo>();
        
        for (int i = 0; i < assetkeys.Count; ++i)
        {
            var filepath = assetkeys[i];
            var deps = assets[filepath];
            // var size = AssetSize[filepath];
            var depc = 0;
            long size = 0;
            redeps.TryGetValue(filepath, out depc);

            if (filepath.EndsWith(".png") || filepath.EndsWith(".tga") || filepath.EndsWith(".jpg"))
            {
                continue;
            }

            if (EditorUtility.DisplayCancelableProgressBar(string.Format("name dep file {0}/{1}", i, assetkeys.Count), filepath, (float)i / (float)assetkeys.Count))
            {
                return true;
            } 

            // NameDependcies(filepath, ref redeps, ref commons, ref bundles, ref count);
            if (!filepath.EndsWith(".unity"))
            {
                size += MatchFileInfo(filepath, ref ofiles, ref nfiles, ref buildin, ref named, ref ctsize);
            }

            for (int d = 0; d < deps.Count; ++d)
            {
                string dep = deps[d];
                if (directory == "shareobject")
                {
                    size += MatchFileInfoWithDeps(dep, ref ofiles, ref nfiles, ref buildin, ref named, ref ctsize);
                }else
                {
                    size += MatchFileInfo(dep, ref ofiles, ref nfiles, ref buildin, ref named, ref ctsize);
                }
                
            }

            csize += size;
            if (csize >= BundleMinSize)
            {
                if (ofiles.Count > 0 || nfiles.Count > 0)
                {
                    string ndir = directory + "/" + ToBaseString(filepath);// filepath.Replace("Assets/", "").Replace(".", "").Replace("/", "").Replace("_", "");// Path.GetDirectoryName(filepath.Replace("Assets/", "")) + "/" + Path.GetFileNameWithoutExtension(filepath).Replace('.', '@') + "_dep";
                    ReBuildAssetBundles(ndir, ofiles, nfiles, ref bundles, ref count, true);
                }
                ofiles.Clear();
                nfiles.Clear();
                csize = 0;
            }
        }

        if (ofiles.Count > 0 || nfiles.Count > 0)
        {
            string filepath = "";
            if (ofiles.Count > 0)
            {
                filepath = ofiles[0].FullName.Replace("\\", "/").Replace(Application.dataPath, "Assets");
            }
            else
            {
                filepath = nfiles[0].FullName.Replace("\\", "/").Replace(Application.dataPath, "Assets");
            }
            string nd = directory + "/" + ToBaseString(filepath);// filepath.Replace("Assets/", "").Replace(".", "").Replace("/", "").Replace("_", "");// Path.GetDirectoryName(filepath.Replace("Assets/", "")) + "/" + Path.GetFileNameWithoutExtension(filepath).Replace('.', '@') + "_dep";
            ReBuildAssetBundles(nd, ofiles, nfiles, ref bundles, ref count, true);
        }

        return false;
    }

    public static List<string> GetPackeredScenes()
    {
        List<string> bscenes = new List<string>();
        for (int i = 0; i < EditorBuildSettings.scenes.Length; ++i)
        {
            var scene = EditorBuildSettings.scenes[i];
            if (!scene.enabled || string.IsNullOrEmpty(scene.path))
            {
                continue;
            }

            if (!bscenes.Contains(scene.path))
            {
                bool b = true;
                foreach (var ig in CreateAssetBundles.scenes)
                {
                    if (ig == scene.path)
                    {
                        b = false;
                        break;
                    }
                }
                if (b)
                {
                    bscenes.Add(scene.path);
                }
            }
        }
        return bscenes;
    }

    static HashSet<string> DependedCount(string path, ref List<BundleInfo> bundles, ref int count, ref long csize)
    {
        DirectoryInfo dir = new DirectoryInfo(path);
        var files = dir.GetFiles("*", SearchOption.AllDirectories);

        HashSet<string> searched = new HashSet<string>();
        Dictionary<string, int> redeps = new Dictionary<string, int>();
        Dictionary<string, List<string>> assets = new Dictionary<string, List<string>>();
        Dictionary<string, List<string>> buildin = new Dictionary<string, List<string>>() {
            { "Assets/assetbundle/config/", new List<string>() },
            { "Assets/assetbundle/Lua/", new List<string>() },
            { ".shader", new List<string>() },
        };

        List<FileInfo> ofiles = new List<FileInfo>();
        List<FileInfo> nfiles = new List<FileInfo>();
        HashSet<string> named = new HashSet<string>();
        HashSet<string> igorelist = new HashSet<string>();
        HashSet<string> obs = new HashSet<string>();

        try
        {
            // 1. collect scenes
            List<string> bscenes = GetPackeredScenes();
            for (int i = 0; i < bscenes.Count; ++i)
            {
                var scene = bscenes[i];
                if (EditorUtility.DisplayCancelableProgressBar(string.Format("collect dependencies scene {0}/{1}", i, bscenes.Count), scene, (float)i / (float)bscenes.Count))
                {
                    return null;
                }
                CollectDependcies(scene, ref redeps, ref assets, ref searched, ref igorelist, ref obs, false);
            }

            // 2. collect 'asset bundle' files
            for (int i = 0; i < files.Length; ++i)
            {
                var f = files[i];
                string filepath = f.FullName.Replace('\\', '/').Replace(Application.dataPath, "Assets");
                if (EditorUtility.DisplayCancelableProgressBar(string.Format("collect dependencies prefab {0}/{1}", i, files.Length), filepath, (float)i / (float)files.Length))
                {
                    return null;
                }
                CollectDependcies(filepath, ref redeps, ref assets, ref searched, ref igorelist, ref obs, false);
            }

            // sprite atlas.
            foreach (var p in igorelist)
            {
                string [] deps = AssetDatabase.GetDependencies(p, true);
                ofiles.Clear();
                nfiles.Clear();
                foreach (var dep in deps)
                {
                    assets.Remove(dep);
                    redeps.Remove(dep);
                    MatchFileInfo(dep, ref ofiles, ref nfiles, ref buildin, ref named, ref csize);
                }
                ReBuildAssetBundles("spriteatlas/"+ Path.GetDirectoryName(p).Replace("/", ""), ofiles, nfiles, ref bundles, ref count);
            }

            //
            ofiles.Clear(); nfiles.Clear();
            foreach (var a in obs)
            {
                MatchFileInfo(a, ref ofiles, ref nfiles, ref buildin, ref named, ref csize, obs);
            }
            ReBuildAssetBundles(CommonAssets, ofiles, nfiles, ref bundles, ref count);

            // 3. name 'asset bundle' files
            int idx = 0;
            // merge
            searched.Clear();
            var removed = new HashSet<string>();
            foreach (var p in assets)
            {
                MergeAssets(p.Key, ref assets, ref redeps, ref searched, ref removed);
            }

            foreach (var filepath in removed)
            {
                assets.Remove(filepath);
            }
            Debug.LogFormat("merged asset count {0}, current asset count {1}", removed.Count, assets.Count);
            List<string> assetkeys =  new List<string>();
            foreach (var p in assets)
            {
                assetkeys.Add(p.Key);
            }
             
            assetkeys.Sort((a, b) => {
                int ac = 0;
                int bc = 0;
                redeps.TryGetValue(a, out ac);
                redeps.TryGetValue(b, out bc);

                return ac.CompareTo(bc);
            });

            List<string> deps1 = new List<string>();
            List<string> depsother = new List<string>();
            idx = 0;
            foreach (var a in assetkeys)
            {
                int ctc = 0;
                redeps.TryGetValue(a, out ctc);
                if (ctc <= 1)
                {
                    deps1.Add(a);
                }else
                {
                    depsother.Add(a);
                }

                if (ctc <= 2)
                {
                    ++idx;
                }
            }

            depsother.Sort((a, b) => {
                int ac = redeps[a];
                int bc = redeps[b];
                return bc.CompareTo(ac);
            });

            Debug.Log("object dep one:" + deps1.Count + " object dep multi:" + depsother.Count + " xx2:" + idx);
            if (NameAssets("object", deps1, ref assets, ref redeps, ref named, ref buildin, ref bundles, ref count, ref csize) ||
                NameAssets("shareobject", depsother, ref assets, ref redeps, ref named, ref buildin, ref bundles, ref count, ref csize))
            {
                return null;
            }
            
            // 4. common
            List<string> depcount1 = new List<string>();
            List<string> depcountohter = new List<string>();
            foreach (var c in redeps)
            {
                var dep = c.Key;
                if (named.Contains(dep))
                {
                    continue;
                }
                List<string> deps;
                if (assets.TryGetValue(dep, out deps) || c.Value > 1)
                {
                    depcountohter.Add(dep);
                }else
                {
                    depcount1.Add(dep);
                }
            }
            depcountohter.Sort((a, b) => {
                return redeps[b].CompareTo(redeps[a]);
            });

            Debug.Log("common dep count one:" + depcount1.Count + " common dep multi:" + depcountohter.Count);
            idx = 0;
            ofiles.Clear();
            nfiles.Clear();
            foreach (var dep in depcountohter)
            {
                MatchFileInfo(dep, ref ofiles, ref nfiles, ref buildin, ref named, ref csize);
            }
            ReBuildAssetBundles("shared/multi", ofiles, nfiles, ref bundles, ref count);

            ofiles.Clear();
            nfiles.Clear();
            foreach (var dep in depcount1)
            {
                MatchFileInfo(dep, ref ofiles, ref nfiles, ref buildin, ref named, ref csize);
            }
            ReBuildAssetBundles("shared/single", ofiles, nfiles, ref bundles, ref count);

            // 5. scenes
            foreach (var spath in bscenes)
            {
                ofiles.Clear();
                nfiles.Clear();
                MatchFileInfo(spath, ref ofiles, ref nfiles, ref buildin, ref named, ref csize);
                ReBuildAssetBundles(Path.GetDirectoryName(spath.Replace("Assets/", "")) + "/" + Path.GetFileNameWithoutExtension(spath), ofiles, nfiles, ref bundles, ref count);
            }
            
            ofiles.Clear();
            nfiles.Clear();
            idx = 0;
            for (int i = 0; i < files.Length; ++i)
            {
                var fs = files[i];
                var filepath = fs.FullName.Replace("\\", "/").Replace(Application.dataPath, "Assets");
                if (filepath.EndsWith(".meta") || 
                    named.Contains(filepath) ||
                    filepath.IndexOf(BundleInfoManager.AssetName) >= 0)
                {
                    continue;
                }

                if (EditorUtility.DisplayCancelableProgressBar(string.Format("name dy file {0}/{1}", i, files.Length), filepath, (float)idx / (float)files.Length))
                {
                    return null;
                }
                
                if(MatchFileInfo(filepath, ref ofiles, ref nfiles, ref buildin, ref named, ref csize) > 0)
                {
                    ++idx;
                }
            }
            Debug.Log("dy file count: " + idx);
            ReBuildAssetBundles("dy", ofiles, nfiles, ref bundles, ref count);

            //
            foreach (var it in buildin)
            {
                ofiles.Clear(); nfiles.Clear();
                Dictionary<string, List<string>> xx = null;
                foreach (var dep in it.Value)
                {
                    MatchFileInfo(dep, ref ofiles, ref nfiles, ref xx, ref named, ref csize);
                }
                ReBuildAssetBundles(it.Key, ofiles, nfiles, ref bundles, ref count);
            }

        }
        catch (System.Exception ex)
        {
            Debug.LogError(ex);
            return null;
        }
        
        return named;
    }

    static bool RemoveUnusedAssetBundles(BundleInfoAsset rsd)
    {
        HashSet<string> unusedbundles = new HashSet<string>();
        var a = BundleInfoManager.GetAsset();
        if (a)
        {
            foreach (var v in a.BundleInfos)
            {
                unusedbundles.Add(v.name);
            }
        }
        foreach (var v in rsd.BundleInfos)
        {
            unusedbundles.Remove(v.name);
        }
        int i = 0;
        foreach (var name in unusedbundles)
        {
            i++;
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("remove unused {0}/{1}", i, unusedbundles.Count), name, (float)i / (float)unusedbundles.Count))
            {
                return false;
            }
            AssetDatabase.RemoveAssetBundleName(name, true);
        }

        return true;
    }

    static void RemoveUnusedBundles(BundleInfoAsset rsd)
    {
        string[] bs = AssetDatabase.GetAllAssetBundleNames();
        int i = 0;
        foreach (var name in bs)
        {
            i++;
            if (null == rsd.BundleInfos.Find((info) =>
            {
                return info.name == name;
            }))
            {

                if (EditorUtility.DisplayCancelableProgressBar(string.Format("remove unused {0}", name), name, 1))
                {
                    EditorUtility.ClearProgressBar();
                    return;
                }
                AssetDatabase.RemoveAssetBundleName(name, true);
            }
        }
        EditorUtility.ClearProgressBar();
    }

    static void SortFileList(BundleInfoAsset infos)
    {
        try
        {
            infos.BundleInfos.Sort((x, y) =>
            {
                return x.name.CompareTo(y.name);
            });

            foreach (var b in infos.BundleInfos)
            {
                b.files.Sort((x, y) =>
                {
                    return x.CompareTo(y);
                });
            }
        }
        catch (System.Exception ex)
        {
            Debug.Log(ex);
        }

    }

    static void RemoveAssetFromBundle(BundleInfoAsset rsd)
    {
        BundleInfoAsset o = BundleInfoManager.GetAsset();
        if (o == null)
        {
            return;
        }
        
        HashSet<string> oas = new HashSet<string>();
        foreach (var b in o.BundleInfos)
        {
            foreach (var a in b.files)
            {
                oas.Add(a);
            }
        }

        int c = 0;
        int cc = oas.Count;
        foreach (var b in rsd.BundleInfos)
        {
            foreach (var a in b.files)
            {
                oas.Remove(a);
                c++;
            }
        }

        Debug.Log("remove asset count : " + oas.Count + ", n count : " + c + ", o count : " + cc);
        int i = 0;
        foreach(var a in oas)
        {
            ++i;
            EditorUtility.DisplayProgressBar(string.Format("remove unused asset {0}/{1}", i, oas.Count), a, (float)i / (float)oas.Count);
            SetAssetBundleName(a, "");
        }
    }

    static void CreateBundleInfoAsset(BundleInfoAsset rsd)
    {
        string assetpath = "Assets/" + RootDir + "/" + BundleInfoManager.AssetBundleName + "/" + BundleInfoManager.AssetName;
        SortFileList(rsd);
       
        UnityEngine.Object o = AssetDatabase.LoadAssetAtPath<BundleInfoAsset>(assetpath);
        if (o == null)
        {
            Directory.CreateDirectory(Application.dataPath + "/" + RootDir + "/" + BundleInfoManager.AssetBundleName);
            AssetDatabase.CreateAsset(rsd, assetpath);
            // AssetDatabase.SaveAssets();
            var importer = AssetImporter.GetAtPath(assetpath);
            importer.assetBundleName = BundleInfoManager.AssetBundleName;
        }
        else
        {
            EditorUtility.CopySerialized(rsd, o);
        }
    }

    public static void FindSpine(string path, ref Dictionary<string, List<string>> ret)
    {
        if (path.IndexOf("/character/") >= 0)
        {
            return;
        }

        var deps = AssetDatabase.GetDependencies(path, true);
        for (int i = 0; i < deps.Length; ++i)
        {
            string dep = deps[i];
            if (dep.IndexOf("SkeletonData") > 0 && !dep.EndsWith(".cs") && dep != path)
            {
                List<string> l = null;
                if (!ret.TryGetValue(path, out l))
                {
                    l = new List<string>();
                    ret.Add(path, l);
                }

                l.Add(dep);
            }
        }
    }

    [MenuItem("AssetBundle/Find Spine")]
    public static void SearchSpineDepended()
    {
        DirectoryInfo dir = new DirectoryInfo(Application.dataPath + "/" + RootDir);
        var files = dir.GetFiles("*", SearchOption.AllDirectories);
        Dictionary<string, List<string>> ret = new Dictionary<string, List<string>>();
        // 1. collect scenes
        List<string> bscenes = new List<string>();
        for (int i = 3; i < EditorBuildSettings.scenes.Length; ++i)
        {
            var scene = EditorBuildSettings.scenes[i];
            if (!bscenes.Contains(scene.path))
            {
                bscenes.Add(scene.path);
            }
        }

        for (int i = 0; i < bscenes.Count; ++i)
        {
            var scene = bscenes[i];
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("collect dependencies scene {0}/{1}", i, bscenes.Count), scene, (float)i / (float)bscenes.Count))
            {
                break;
            }
            FindSpine(scene, ref ret);
        }

        // 2. collect 'asset bundle' files
        for (int i = 0; i < files.Length; ++i)
        {
            var f = files[i];
            string filepath = f.FullName.Replace('\\', '/').Replace(Application.dataPath, "Assets");
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("collect dependencies prefab {0}/{1}", i, files.Length), filepath, (float)i / (float)files.Length))
            {
                break;
            }
            FindSpine(filepath, ref ret);
        }

        string nf = Application.dataPath.Replace("Assets", "") + "spine.csv";
        if (File.Exists(nf))
        {
            File.Delete(nf);
        }
        File.Create(nf);
        string str = "";
        foreach (var it in ret)
        {
            str += it.Key;
            foreach (var p in it.Value)
            {
                str = str + "," + p;
            }
            str += "\n";
        }
        File.WriteAllText(nf, str);

        EditorUtility.ClearProgressBar();
    }

    [MenuItem("AssetBundle/Named Asset Bundle Min")]
    public static void NamedAssetBundleName()
    {
        int count = 0;
        long csize = 0;
        BundleInfoAsset rsd = ScriptableObject.CreateInstance<BundleInfoAsset>();
        rsd.BundleInfos = new List<BundleInfo>();
        {
            BundleInfo bi = new BundleInfo(BundleInfoManager.AssetBundleName);
            bi.files.Add("Assets/" + RootDir + "/" + BundleInfoManager.AssetBundleName + "/" + BundleInfoManager.AssetName);
            rsd.BundleInfos.Add(bi);
        }

        BundleInfoManager.InitEditor();
        AssetDatabase.StartAssetEditing();
        bool completed = false;
        do 
        {
            if(null == DependedCount(Application.dataPath + "/" + RootDir, ref rsd.BundleInfos, ref count, ref csize))
            {
                break;
            }
            
            Debug.LogFormat("bundle count {0}, file count {1}, files size {2} MB", rsd.BundleInfos.Count, count, csize/1024/1024);
            

            completed = true;
        } while (false);

        

        if (completed)
        {
            RemoveAssetFromBundle(rsd);
            RemoveUnusedAssetBundles(rsd);

            CreateBundleInfoAsset(rsd);
            RemoveUnusedBundles(rsd);

            AssetDatabase.RemoveUnusedAssetBundleNames();
        }

        Debug.Log(completed ? "completed" : "use canceled");

        AssetDatabase.StopAssetEditing();
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        EditorUtility.ClearProgressBar();
    }

   
    [MenuItem("AssetBundle/Removed All Asset Bundle Name")]
    static void RemoveAllAssetBundleName()
    {
        string[] names = AssetDatabase.GetAllAssetBundleNames();
        AssetDatabase.StartAssetEditing();
        for (int i = 0; i < names.Length; ++i)
        {
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("remove assetbundle {0}/{1}", i, names.Length), names[i], (float)i / (float)names.Length))
            {
                AssetDatabase.StopAssetEditing();
                AssetDatabase.SaveAssets();
                EditorUtility.ClearProgressBar();
                return;
            }

            AssetDatabase.RemoveAssetBundleName(names[i], true);
        }
        AssetDatabase.StopAssetEditing();
        AssetDatabase.SaveAssets();
        EditorUtility.ClearProgressBar();
    }

    [MenuItem("AssetBundle/检查资源包是否有重复资源")]
    public static void CheckAssetbundles()
    {
        // string path = Application.dataPath.Replace("Assets", "") + "AssetBundles/" + AssetBundles.Utility.GetPlatformName();
        string path = Application.dataPath.Replace("Assets", "") + "AssetBundles/ABoutput_red";
        var dir = new DirectoryInfo(path);
        var files = dir.GetFiles("*", SearchOption.AllDirectories);
        HashSet<string> names = new HashSet<string>();
        Debug.Log("check start : " + path);
        int ig = 0;
        for (int i = 0; i < files.Length; ++i)
        {
            var f = files[i];
            if (f.FullName.EndsWith(".manifest"))
            {
                ig++;
                continue;
            }
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("check {0}/{1}", i, files.Length), f.Name, (float)i / (float)files.Length))
            {
                EditorUtility.ClearProgressBar();
                return;
            }


            var ab = AssetBundle.LoadFromFile(f.FullName);
            string[] abnames = ab.GetAllAssetNames();
            ab.Unload(true);
            foreach (var ass in abnames)
            {
                if (names.Contains(ass))
                {
                    Debug.LogError("repeat asset: " + ass);
                }
                else
                {
                    names.Add(ass);
                }
            }
        }
        EditorUtility.ClearProgressBar();
        Debug.Log("check complete file count : " + names.Count + ", bundle count:" + (files.Length - ig));
    }
    

}
