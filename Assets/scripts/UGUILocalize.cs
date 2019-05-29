using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
    public class UGUILocalize : MonoBehaviour {
        public string key;

        public string value {
            set {
                if (!string.IsNullOrEmpty(value)) {
                    var _uguiText = GetComponent<Text>();
                    if (_uguiText != null) {
                        _uguiText.text = value;
                    }
                }
            }
        }


        void OnLocalize() {
            if (string.IsNullOrEmpty(key)) {
                var _uguiText = GetComponent<Text>();
                if (_uguiText != null) {
                    key = _uguiText.text;
                }
            }
            if (!string.IsNullOrEmpty(key)) {
                value = Localize.getInstance().getValue(key);
            } else {
                value = "";
            }
        }


        void Start() {
            OnLocalize();
        }

    }
}