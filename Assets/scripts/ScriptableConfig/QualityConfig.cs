using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace SGK {
    [CreateAssetMenu(fileName = "QualityConfig", menuName = "config/quality", order = 1)]
    public class QualityConfig : ScriptableObject {
        [System.Serializable]
        public struct ColorInfo {
            public Color frame;
            public Color background;
            public Sprite starSprite;
        };

        public ColorInfo [] colors = new ColorInfo[0];

        public Material grayMaterial;

        public Color mpColor = Color.blue;
        public Color epColor = Color.green;
        public Color fpColor = Color.red;

        [System.Serializable]
        public struct ButtonConfig
        {
            public Sprite sprite;
            public Color textColor;
        }

        public ButtonConfig[] buttonConfig;
        public Sprite closeButtonSprite;
        public Sprite tabButtonSprite1;
        public Sprite tabButtonSprite2;

        public AudioClip defaultUIClickAudio;

        public AudioClip defaultUIOpenAudio;
        public AudioClip defaultUICloseAudio;

        public Color GetColor(int quality, bool background = false) {
            if (quality >= 0 && quality < colors.Length) {
                return background ? colors[quality].background : colors[quality].frame;
            }
            return Color.white;
        }

        public Sprite GetStarSprite(int quality) {
            if (quality >= 0 && quality < colors.Length) {
                return colors[quality].starSprite;
            }
            return null;
        }

        static QualityConfig _instance = null;
        public static QualityConfig GetInstance() {
            if (_instance == null) {
                _instance = SGK.ResourcesManager.Load<QualityConfig>("config/QualityConfig.asset");
            }
            return _instance;
        }
    }
}
