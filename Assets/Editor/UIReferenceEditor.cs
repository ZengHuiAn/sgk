using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;

[CustomEditor(typeof(SGK.UIReference))]
public class UIReferenceEditor : Editor {
    private void OnEnable() {

    }

    public override void OnInspectorGUI() {
        SGK.UIReference refs = (SGK.UIReference)serializedObject.targetObject;
        if (GUILayout.Button("append to children)")) {
            refs.DoSomething();
            return;
        }

        base.OnInspectorGUI();

        Image image = refs.GetComponent<Image>();
        if (image == null) {
            return;
        }

        FindButton(image, refs);
    }

    void FindButton(Image image, SGK.UIReference refs) { 
        SGK.QualityConfig.ButtonConfig [] cfgs = SGK.QualityConfig.GetInstance().buttonConfig;

        int find =  -1;
        for (int i = 0; i < cfgs.Length; i++) {
            if (image.sprite == cfgs[i].sprite) {
                find = i;
                break;
            }
        }

        if (find == -1) {
            return;
        }

        if (!GUILayout.Button(string.Format("切换按钮风格 ({0})", find + 1))) {
            return;
        }

        find = (find + 1) % cfgs.Length;

        SerializedObject image_obj = new SerializedObject(image);
        image_obj.Update();
        SerializedProperty sprite = image_obj.FindProperty("m_Sprite");
        sprite.objectReferenceValue = cfgs[find].sprite;
        image_obj.ApplyModifiedProperties();

        for (int i = 0; i < refs.refs.Length; i++) {
            if (refs.refs[i] == null) {
                continue;
            }
            Text text = refs.refs[i].GetComponent<Text>();
            if (text == null) {
                continue;
            }

            SerializedObject obj = new SerializedObject(text);

            obj.Update();

            SerializedProperty ite2 = obj.GetIterator();
            while (ite2.NextVisible(true)) {
                if (ite2.name == "m_FontSize") {
                    ite2.intValue = 30;
                } else if (ite2.name == "m_Font") {
                    ite2.objectReferenceValue = AssetDatabase.LoadAssetAtPath<Font>("Assets/fonts/MFXingYan-Noncommercial-Regular.ttf");
                } else if (ite2.name == "m_Color") {
                    ite2.colorValue = Color.black; // cfgs[find].textColor;
                }
            }
            ite2.Reset();

            obj.ApplyModifiedProperties();

            Outline outline = text.GetComponent<Outline>();
            if (outline) {
                DestroyImmediate(outline);
            }
        }
    }
}
