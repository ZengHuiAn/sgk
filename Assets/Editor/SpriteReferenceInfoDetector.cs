using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class SpriteReferenceInfoDetector : AssetPostprocessor
{
    public static bool watchEditorChange = false;
    static void OnPostprocessAllAssets(
        string[] importedAssets,
        string[] deletedAssets,
        string[] movedAssets,
        string[] movedFromAssetPaths) {

        if (!watchEditorChange) {
            return;
        }

        HashSet<string> objs = new HashSet<string>();
        foreach (string str in importedAssets) {
            Debug.Log("Reimported Asset: " + str);
            GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(str);
            if (obj != null) {
                objs.Add(str);
            }
        }

        foreach (string str in deletedAssets) {
            Debug.Log("Deleted Asset: " + str);
        }

        for (int i = 0; i < movedAssets.Length; i++) {
            // Debug.Log("Moved Asset: " + movedAssets[i] + " from: " + movedFromAssetPaths[i]);
        }

        SpriteReferenceInfo.Instance.OnAssetChange(objs);
    }
}