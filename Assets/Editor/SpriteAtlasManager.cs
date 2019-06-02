using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


// [CreateAssetMenu(fileName = "SpriteAtlasManager", menuName = "config/SpriteAtlas", order = 2)]
public class SpriteAtlasManager : ScriptableObject
{
    public static SpriteAtlasData Get(Texture2D texture) {
        return Get(AssetDatabase.GetAssetPath(texture));
    }

    public static SpriteAtlasData Get(string path) {
        TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
        if (importer == null || importer.textureType != TextureImporterType.Sprite) {
            return null;
        }

        if (importer.spriteImportMode == SpriteImportMode.Single) {
            return null;
        }

        if (importer.spriteImportMode != SpriteImportMode.Multiple) {
                return null;
        }

        string atlas_guid = AssetDatabase.AssetPathToGUID(path);
        if (string.IsNullOrEmpty(atlas_guid)) {
            return null;
        }

        string data_path = string.Format("{0}/{1}_SpriteAtlasData.asset",
                System.IO.Path.GetDirectoryName(path),
                System.IO.Path.GetFileNameWithoutExtension(path));

        SpriteAtlasData data = AssetDatabase.LoadAssetAtPath<SpriteAtlasData>(data_path);
        if (data == null) {
            data = ScriptableObject.CreateInstance<SpriteAtlasData>();
            data.texture = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            data.Scan();
            AssetDatabase.CreateAsset(data, data_path);
        } else {
            if (data.texture == null) {
                data.texture = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            }
        }
        return data;
    }

    public static SpriteAtlasData CreateTexture(string path) {
        if (System.IO.File.Exists(path)) {
            Debug.LogErrorFormat("file exists: {0}", path);
            return null;
        }

        Texture2D texture = new Texture2D(1, 1);
        AssetDatabase.CreateAsset(texture, path);
        TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
        importer.textureType = TextureImporterType.Sprite;
        importer.spriteImportMode = SpriteImportMode.Multiple;
        importer.isReadable = false;
        importer.textureCompression = TextureImporterCompression.Compressed;
        importer.SaveAndReimport();

        return Get(path);
    }

    [SerializeField]
    List<SpriteAtlasData> _spriteAtlasInfo = null;

    List<Sprite> singleSpriteList = new List<Sprite>();

    public List<SpriteAtlasData> atlas {
        get {
            if (_spriteAtlasInfo == null) {
                _spriteAtlasInfo = new List<SpriteAtlasData>();
                Reload();
            }
            return _spriteAtlasInfo;
        }
    }

    public void Clear() {
        _spriteAtlasInfo = null;
    }

    public void Reload() {
        try {
            atlas.Clear();
            string[] assets = AssetDatabase.FindAssets("t:SpriteAtlasData");
            for (int i = 0; i < assets.Length; i++) {
                _spriteAtlasInfo.Add(AssetDatabase.LoadAssetAtPath<SpriteAtlasData>(AssetDatabase.GUIDToAssetPath(assets[i])));
            }
            _spriteAtlasInfo.Sort((a, b) => {
                return string.Compare(a.path, b.path);
            });
        } catch (System.Exception e) {
            Debug.LogError(e);
        }
    }

    public void Scan(bool single = false) {
        List<SpriteAtlasData> list = new List<SpriteAtlasData>();
        try {
            int findCount = 0;
            string[] assets = AssetDatabase.FindAssets("t:texture");
            for (int i = 0; i < assets.Length; i++) {
                string path = AssetDatabase.GUIDToAssetPath(assets[i]);

                if (EditorUtility.DisplayCancelableProgressBar(string.Format("{0}", path), string.Format("{0}/{1}, {2}", i + 1, assets.Length, findCount), (float)i / (float)assets.Length)) {
                    break;
                }

                if (InBlacklist(path)) {
                    continue;
                }

                TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                if (importer == null) {
                    continue;
                }

                if (importer.textureType != TextureImporterType.Sprite) { 
                    continue;
                }

                if (importer.spriteImportMode == SpriteImportMode.Single) {
                    if (single) {
                        singleSpriteList.Add(AssetDatabase.LoadAssetAtPath<Sprite>(path));
                        findCount++;
                    }
                } else {

                    SpriteAtlasData data = Get(path);
                    if (data != null) {
                        data.Scan();
                        list.Add(data);
                        findCount++;
                    }
                }
            }

            list.Sort((a, b) => {
                return string.Compare(a.path, b.path);
            });
        } catch (System.Exception e) {
            Debug.LogError(e);
            EditorUtility.ClearProgressBar();
            return;
        }

        _spriteAtlasInfo.Clear();
        _spriteAtlasInfo.AddRange(list);

        EditorUtility.ClearProgressBar();
    }

    public void RemoveAtlas(SpriteAtlasData atlas, bool delete = false) {
        if (_spriteAtlasInfo.Contains(atlas)) {
            _spriteAtlasInfo.Remove(atlas);
            if (delete) {
                string path = AssetDatabase.GetAssetPath(atlas);
                if (!string.IsNullOrEmpty(path)) {
                    Debug.LogFormat("Delete {0}", path);
                    AssetDatabase.DeleteAsset(path);
                }
            }
        }
    }

    [SerializeField]
    string[] blackList;
    bool InBlacklist(string path) {
        if (blackList == null) return true;
        for (int i = 0; i < blackList.Length; i++) {
            if (!string.IsNullOrEmpty(blackList[i])) {
                if (path.StartsWith(blackList[i])) {
                    return true;
                }
            }
        }
        return false;
    }
}