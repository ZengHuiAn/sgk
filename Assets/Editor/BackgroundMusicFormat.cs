using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BackgroundMusicFormat {

    [MenuItem("Tools/Music/Load Type")]
    static void Uncompressed() {
        string[] folder = {
            "Assets/assetbundle/sound",
        };
        string [] acs = AssetDatabase.FindAssets("t:AudioClip", folder);

        int n = acs.Length;

        AssetDatabase.StartAssetEditing();

        for (int i = 0; i < n; i++) {
            string path = AssetDatabase.GUIDToAssetPath(acs[i]);
            if (EditorUtility.DisplayCancelableProgressBar(string.Format("{0}", path), i + "/" + acs.Length, (float)i / (float)acs.Length)) {
                break;
            }

            // Debug.LogFormat("reimport {0}/{1}: {2}", i+1, n, path);
            AudioImporter audioImporter = AssetImporter.GetAtPath(path) as AudioImporter;
            if (audioImporter == null) {
                continue;
            }

            AudioClipLoadType t = AudioClipLoadType.DecompressOnLoad;

            AudioClip clip = AssetDatabase.LoadAssetAtPath<AudioClip>(path);
            if (clip.length >= 5) {
                
                t = AudioClipLoadType.Streaming;
            }

            AudioImporterSampleSettings audioImporterSampleSettings = audioImporter.defaultSampleSettings;
            if (audioImporterSampleSettings.loadType != t) {
                Debug.LogFormat("{0} {1} {2}", path, clip.length, t);

                audioImporterSampleSettings.loadType = AudioClipLoadType.Streaming;
                audioImporter.defaultSampleSettings = audioImporterSampleSettings;
                audioImporter.SaveAndReimport();
            }
        }

        AssetDatabase.StopAssetEditing();
        // AssetDatabase.SaveAssets();
        // AssetDatabase.Refresh();
        EditorUtility.ClearProgressBar();
    }

}
