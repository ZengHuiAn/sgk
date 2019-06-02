using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;

[CustomEditor(typeof(UGUIClickEventListener))]
public class UGUIClickEventListenerEditor : Editor {
    public override void OnInspectorGUI() {
        base.OnInspectorGUI();

        UGUIClickEventListener listener = (UGUIClickEventListener)serializedObject.targetObject;
        Image image = listener.GetComponent<Image>();
        if (image == null) {
            return;
        }

        FindCloseButton(image, listener);
    }

    void FindCloseButton(Image image, UGUIClickEventListener listener) {
        // SGK.QualityConfig.ButtonConfig[] cfgs = SGK.QualityConfig.GetInstance().buttonConfig;

        if (image.sprite != SGK.QualityConfig.GetInstance().closeButtonSprite) {
            return;
        }


        if (!GUILayout.Button(string.Format("更新关闭按钮风格"))) {
            return;
        }

        listener.disableTween = false;
        listener.tweenStyle = UGUIClickEventListener.TweenStyle.DEFAULT;

        image.SetNativeSize();

        RectTransform rectTransform = image.gameObject.GetComponent<RectTransform>();
        rectTransform.anchorMin = rectTransform.anchorMax = new Vector2(1, 1);
        rectTransform.anchoredPosition = new Vector2(-49, -90);
    }
}
