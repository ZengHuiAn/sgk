using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class HorizontalFieldOfViewCamera : MonoBehaviour {
    public class ReadOnlyAttribute : PropertyAttribute {

    }

#if UNITY_EDITOR
    [CustomPropertyDrawer(typeof(ReadOnlyAttribute))]
    public class ReadOnlyDrawer : PropertyDrawer {
        public override float GetPropertyHeight(SerializedProperty property,
                                                GUIContent label) {
            return EditorGUI.GetPropertyHeight(property, label, true);
        }

        public override void OnGUI(Rect position,
                                   SerializedProperty property,
                                   GUIContent label) {
            GUI.enabled = false;
            EditorGUI.PropertyField(position, property, label, true);
            GUI.enabled = true;
        }
    }
#endif

    public float designWidth = 750;
    public float designHeight = 1334;
    public float designVerticalFOV = 60;
    public bool keep = false;

    void Start () {
        Check();
	}

#if UNITY_EDITOR
    void LateUpdate() {
        Check();
    }
#endif

    void Check() {
        Camera camera = GetComponent<Camera>();

        float hFOV = calcHorizontalFOV(designWidth, designHeight, designVerticalFOV);

        if (keep || (Screen.width * 1.0f / Screen.height)  < (designWidth / designHeight) ) {
            camera.fieldOfView = calcVerticalFOV(Screen.width, Screen.height, hFOV);
        } else {
            camera.fieldOfView = designVerticalFOV;
        }
    }

    float calcVerticalFOV(float width, float height, float horizontalFOV) {
        return calcHorizontalFOV(height, width, horizontalFOV);
    }

    float calcHorizontalFOV(float width, float height, float verticalFOV) {
        float distance = height / 2 / Mathf.Tan(Mathf.Deg2Rad * verticalFOV / 2);
        return Mathf.Atan2(width / 2, distance) * Mathf.Rad2Deg * 2;
    }
}
