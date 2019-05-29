using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

public class ReplaceTexture : EditorWindow
{
    
    static void Init() {
        ReplaceTexture window = (ReplaceTexture)EditorWindow.GetWindow(typeof(ReplaceTexture));
        window.Show();
    }

    GameObject obj;

    void OnGUI() {
        // obj = (GameObject)EditorGUILayout.ObjectField("target", obj, typeof(GameObject), false);
        // if ()
    }

    [MenuItem("Tools/Replace Texture")]
    public static void Replace() {
        string dir = "common";

        try {
            // AssetDatabase.StartAssetEditing();
            TextureImporter packed_importer = AssetImporter.GetAtPath("Assets/UI8/" + dir + ".png") as TextureImporter;
            List<SpriteMetaData> newDataList = new List<SpriteMetaData>(packed_importer.spritesheet);
            // packed_importer.spriteImportMode = SpriteImportMode.Single;

            for (int i = 0; i < newDataList.Count; i++) {
                SpriteMetaData metaData = newDataList[i];

                TextureImporter single_importer = AssetImporter.GetAtPath("Assets/UI8/" + dir + "/" + metaData.name + ".png") as TextureImporter;
                if (metaData.border != single_importer.spriteBorder) {
                    if (single_importer.spriteBorder.sqrMagnitude < 0.1f) {
                        Debug.LogFormat("change signel border {2} {0} <- {1}", metaData.border, single_importer.spriteBorder, metaData.name);
                        single_importer.spriteBorder = metaData.border;
                        AssetDatabase.ImportAsset("Assets/UI8/" + dir + ".png", ImportAssetOptions.ForceUpdate);
                    } else {
                        Debug.LogFormat("change packed border {2} {0} -> {1}", metaData.border, single_importer.spriteBorder, metaData.name);
                        metaData.border = single_importer.spriteBorder;
                    }

                    AssetDatabase.ImportAsset(single_importer.assetPath, ImportAssetOptions.ForceUpdate);
                }
                newDataList[i] = metaData;

                /*
                List < SpriteMetaData > metaData = new List<SpriteMetaData>();

                SpriteMetaData smd = new SpriteMetaData();
                smd.pivot = new Vector2(0.5f, 0.5f);
                smd.alignment = 9;
                smd.name = (myTexture.height - j) / SliceHeight + ", " + i / SliceWidth;
                smd.rect = new Rect(i, j - SliceHeight, SliceWidth, SliceHeight);
                smd.border = sprite.border;

                importer.spritesheet = smd;

                Sprite sep = AssetDatabase.LoadAssetAtPath<Sprite>();

                sep.border = sprite.border;
                */
            }

            // packed_importer.spriteImportMode = SpriteImportMode.Single;
            // AssetDatabase.ImportAsset(packed_importer.assetPath, ImportAssetOptions.ForceUpdate);

            packed_importer.spritesheet = newDataList.ToArray();
            packed_importer.spriteImportMode = SpriteImportMode.Multiple;
            EditorUtility.SetDirty(packed_importer);
            AssetDatabase.ImportAsset(packed_importer.assetPath, ImportAssetOptions.ForceUpdate);
        } catch (System.Exception e) {
            Debug.LogError(e);
        } finally {
            // AssetDatabase.StopAssetEditing();
        }

        // AssetDatabase.FindAssets("");

        // ScanDir("Assets");


        EditorUtility.ClearProgressBar();
    }

    void ScanDir(string dir) {

    }


    [MenuItem("Tools/Button Title")]
    public static void ReplaceButtonTitle() {
        Object[] objects = Selection.GetFiltered(typeof(GameObject), SelectionMode.DeepAssets);
        int n = objects.Length;

        for (int i = 0; i < n; i++) {
            GameObject obj = objects[i] as GameObject;
            if (obj == null) {
                continue;
            }
            Debug.Log(AssetDatabase.GetAssetPath(obj));
            EditorUtility.DisplayProgressBar(string.Format("working {0}/{1}", i + 1, objects.Length), AssetDatabase.GetAssetPath(obj), i * 1.0f / objects.Length);
            // continue;
            Image[] images = obj.GetComponentsInChildren<Image>();
            for (int j = 0; j < images.Length; j++) {
                Image image = images[j];
                string path = AssetDatabase.GetAssetPath(image.sprite);
/*
                Color color;
                if (path == "Assets/UI7/common/bn_07.png") {
                    color = Color.
                }

                    按钮上的字30号，按钮在这里的宽度：226，高度是默认的。

按钮上的字色：

红 431409

黄 43230b

蓝 042a33

绿 1d4309

灰 5e5e5e
                }
                */
                if (path.StartsWith("Assets/UI7/common/")) {
                    Debug.Log(path);
                    if (path == "Assets/UI7/common/bn_guanbi.png") {
                        image.SetNativeSize();
                        UGUIClickEventListener.Get(image.gameObject).disableTween = true;
                        Button btn = image.gameObject.GetComponent<Button>();
                        if (btn == null) {
                            btn = image.gameObject.AddComponent<Button>();
                        }
                        btn.transition = Selectable.Transition.SpriteSwap;
                        btn.targetGraphic = image;
                        // btn.spriteState = spriteState;
                    } else if (image.type == Image.Type.Sliced) {
                        RectTransform transform = image.GetComponent<RectTransform>();
                        if (transform.rect.size.y < image.sprite.rect.height || transform.rect.size.x < image.sprite.rect.width) {
                            if (transform.anchorMin == transform.anchorMax) {
                                transform.sizeDelta = new Vector2(
                                    Mathf.Max(transform.rect.size.x, image.sprite.rect.width),
                                    Mathf.Max(transform.rect.size.y, image.sprite.rect.height));
                            }
                        }
                    }

                }
            }
        }
        EditorUtility.ClearProgressBar();
    }

}
