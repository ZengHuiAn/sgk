using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

public class CompressTexture : EditorWindow {

    [MenuItem("Tools/Find Object By GUID")]
    static void Init() {
        CompressTexture window = (CompressTexture)EditorWindow.GetWindow(typeof(CompressTexture));
        window.Show();
    }

    string guid = "";

    void OnGUI()
    {
        string sguid = EditorGUILayout.TextField ("GUID", guid);
        string path = AssetDatabase.GUIDToAssetPath(sguid);
        EditorGUILayout.TextField ("Path", path);

        if (sguid == guid) {
            return;
        }

        Debug.Log(path);
        Selection.objects = AssetDatabase.LoadAllAssetsAtPath(path);
    }

    [MenuItem("Tools/Find build in sprite")]
    static void FindBuildinSprite() {
        List<GameObject> list = new List<GameObject>();
        Image[] images = FindObjectsOfType<Image>();
        foreach (var image in images) {
            if (!image.enabled) continue;

            if (false && image.sprite == null) {
                list.Add(image.gameObject);
            } else {
                if (AssetDatabase.GetAssetPath(image.sprite.texture) == "Resources/unity_builtin_extra") {
                    list.Add(image.gameObject);
                }
            }
        }

        Selection.objects = list.ToArray();
    }

    [MenuItem("Tools/Texture/Compress/None")]
    static void Uncompressed() {
        UpdateCompress(TextureImporterCompression.Uncompressed);
    }

    [MenuItem("Tools/Texture/Compress/Hight Quality")]
    static void CompressedHQ() {
        UpdateCompress(TextureImporterCompression.CompressedHQ);
    }

    [MenuItem("Tools/Texture/Compress/Normal Quality")]
    static void Compressed() {
        UpdateCompress(TextureImporterCompression.Compressed);
    }

    [MenuItem("Tools/Texture/Compress/Low Quality")]
    static void CompressedLQ() {
        UpdateCompress(TextureImporterCompression.CompressedLQ);
    }

    [MenuItem("Tools/Texture/Alpha/Transparen")]
    static void Transparen() {
        UpdateAlpha(true);
    }

    [MenuItem("Tools/Texture/Alpha/Premultiplied")]
    static void Premultiplied() {
        UpdateAlpha(false);
    }

    [MenuItem("Tools/Texture/Size/512")]
    static void MaxSize512() {
        UpdateSize(512);
    }

    [MenuItem("Tools/Texture/Size/1024")]
    static void MaSize1024() {
        UpdateSize(1024);
    }

    [MenuItem("Tools/Texture/Size/2048")]
    static void MaSize2048() {
        UpdateSize(2048);
    }

    [MenuItem("Tools/Texture/Mini map/clean")]
    static void MiniMapClean() {
        TextureProcess((textureImporter) => {
            if (textureImporter.mipmapEnabled) {
                textureImporter.mipmapEnabled = false;
                return true;
            }
            return false;
        });
    }

    static void UpdateSize(int size) {
        TextureProcess((textureImporter) => {
            if (textureImporter.maxTextureSize != size) {
                textureImporter.maxTextureSize = size;
                return true;
            }
            return false;
        });
    }

    static void UpdateAlpha(bool alphaIsTransparency) {
        TextureProcess((textureImporter) => {
            if (textureImporter.alphaIsTransparency != alphaIsTransparency) {
                textureImporter.alphaIsTransparency = alphaIsTransparency;
                return true;
            }
            return false;
        });
    }

    static void UpdateCompress(TextureImporterCompression compress) {
        TextureProcess((textureImporter) => {
            if (textureImporter.textureCompression != compress) {
                textureImporter.textureCompression = compress;
                return true;
            }
            return true;
        });
    }

    delegate bool TextureAction(TextureImporter importer);

    static void TextureProcess(TextureAction func) {
        Object[] textures = Selection.GetFiltered(typeof(Texture2D), SelectionMode.DeepAssets);

        int n = textures.Length;

        AssetDatabase.StartAssetEditing();

        Selection.objects = new Object[0];
        for (int i = 0; i < n; i++) {
            Texture2D texture = textures[i] as Texture2D;

            string path = AssetDatabase.GetAssetPath(texture);

            if (EditorUtility.DisplayCancelableProgressBar(string.Format("{0}", path), i + "/" + textures.Length, (float)i / (float)textures.Length)) {
                break;
            }

            // Debug.LogFormat("reimport {0}/{1}: {2}", i+1, n, path);
            TextureImporter textureImporter = AssetImporter.GetAtPath(path) as TextureImporter;
            if (func(textureImporter)) {
                AssetDatabase.ImportAsset(path);
            }
            // textureImporter.SaveAndReimport();
        }

        AssetDatabase.StopAssetEditing();
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        EditorUtility.ClearProgressBar();
    }

    static bool IsPowerOfTwo(int x) {
        return (x & (x - 1)) == 0;
    }

    [MenuItem("Tools/Texture/NPOT")]
    static void findNPOTTexture() {
        List<Object> findList = new List<Object>();

        Object[] textures = Selection.GetFiltered(typeof(Texture2D), SelectionMode.DeepAssets);
        foreach (Texture2D texture in textures) {
            if (!IsPowerOfTwo(texture.width) || !IsPowerOfTwo(texture.height)) {
                Debug.LogFormat("{0}x{1} {2}", texture.width, texture.height, texture);
                findList.Add(texture);
            }
        }

        Selection.objects = findList.ToArray();
    }


    [MenuItem("Tools/Append VolumeController")]
    static void AddVolumeControllerToAudioSource() {
        Object[] selection = Selection.GetFiltered(typeof(Object), SelectionMode.DeepAssets);
        foreach (Object obj in selection)
        {
            if (obj.GetType() == typeof(GameObject)) {
                AudioSource [] a = ((GameObject)obj).GetComponentsInChildren<AudioSource>();
                if (a.Length > 0) {
                    Debug.LogFormat("object {0}", obj.name);
                    for (int i = 0; i < a.Length; i++) {
                        Debug.LogFormat("    -> {0}", a[i].gameObject.name);
                        if (a[i].gameObject.GetComponent<SGK.AudioSourceVolumeController>() == null) {
                           a[i].gameObject.AddComponent<SGK.AudioSourceVolumeController>();
                        }
                    }
                }
            }
        }
    }
}