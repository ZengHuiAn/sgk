using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(UGUISelectorGroup))]
public class UGUISelectorEditor : Editor {
    public override void OnInspectorGUI() {
        base.OnInspectorGUI();

        if (GUILayout.Button("next")) {
            UGUISelector selector = (UGUISelector)serializedObject.targetObject;
            selector.NextValue();
        }
    }
}
