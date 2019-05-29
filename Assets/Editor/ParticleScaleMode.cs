using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class ParticleScaleMode : EditorWindow
{
    [MenuItem("Tools/ParticleScale/Hierarchy")]
    static void Uncompressed() {
        UpdateScaleMode(ParticleSystemScalingMode.Hierarchy);
    }

    [MenuItem("Tools/ParticleScale/Local")]
    static void CompressedHQ() {
        UpdateScaleMode(ParticleSystemScalingMode.Local);
    }

    [MenuItem("Tools/ParticleScale/Shape")]
    static void Compressed() {
        UpdateScaleMode(ParticleSystemScalingMode.Shape);
    }

    static void UpdateScaleMode(ParticleSystemScalingMode mode) {
        ParticleSystemProcess((particleSystem) => {
            if (particleSystem.main.scalingMode != mode) {
                particleSystem.scalingMode = mode;
                /*
                SerializedObject so = new SerializedObject(particleSystem);

                so.FindProperty(" ParticleSystem.MainModule.scalingMode").enumValueIndex = 1;

                so.ApplyModifiedProperties();
                particleSystem.main.scalingMode = mode;
                */
                return true;
            }
            return false;
        });
    }

    delegate bool ParticleSystemAction(ParticleSystem particleSystem);

    static void ParticleSystemProcess(ParticleSystemAction func) {
        Object[] objs = Selection.GetFiltered(typeof(GameObject), SelectionMode.DeepAssets);

        int n = objs.Length;

        Selection.objects = new Object[0];
        for (int i = 0; i < n; i++) {
            GameObject go = objs[i] as GameObject;
            string path = AssetDatabase.GetAssetPath(go);
            Debug.LogFormat("reimport {0}/{1}: {2}", i + 1, n, path);

            if (forParticleSystem(go, func)) {
                AssetDatabase.ImportAsset(path);
            }
        }
    }

    static bool forParticleSystem(GameObject go, ParticleSystemAction func) {
        ParticleSystem particleSystem = go.GetComponent<ParticleSystem>();
        bool b = false;
        if (particleSystem != null) {
            b = func(particleSystem) || b;
        }

        Transform trans = go.GetComponent<Transform>();
        for (int i = 0; i < trans.childCount; i++) {
            b = forParticleSystem(trans.GetChild(i).gameObject, func) || b;
        }

        return b;
    }
}
