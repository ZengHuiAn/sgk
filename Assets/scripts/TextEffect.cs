using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
    public class TextEffect : MonoBehaviour {
        private string _text;
        private Text _uiText;
        private System.Action m_callBack = null;

        private void Start() {
            _uiText = GetComponent<Text>();
        }

        public string EffText {
            get { return _text; }
            set {
                _text = value;
                playEffect();
            }
        }

        public System.Action CallBack {
            set {
                m_callBack = value;
            }
        }


        private void playEffect() {
            if (_text != null) {
                StartCoroutine(textEffect());
            }
        }

        private IEnumerator textEffect() {
            foreach (char letter in _text.ToCharArray()) {
                _uiText.text += letter;
                yield return new WaitForSeconds(0.05f);
            }
            if (m_callBack != null) {
                m_callBack();
            }
        }

    }

}
