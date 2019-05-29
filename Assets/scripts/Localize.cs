using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class Localize {
        private static readonly Localize m_instance = new Localize();

        private string m_language = "Chinese";
        private Dictionary<string, Dictionary<string, string>> m_dictionary = new Dictionary<string, Dictionary<string, string>>();

        public static Localize getInstance() {
            return m_instance;
        }

        public void addCfg(string key, string language, string value) {
            try {
                if (m_dictionary.ContainsKey(key)) {
                    if (!m_dictionary[key].ContainsKey(language)) {
                        m_dictionary[key].Add(language, value);
                    }
                } else {
                    var _value = new Dictionary<string, string>();
                    _value.Add(language, value);
                    m_dictionary.Add(key, _value);
                }
                
            } catch (System.Exception e) {
                Debug.LogError(e);
            }
        }

        public string language {
            set {
                if (m_language != value) {
                    m_language = value;
                }
            }
            get {
                return m_language;
            }
        }

        public string getValue(string key, params object[] arg) {
            var _value = getValue(key);
            try {
                var _s = string.Format(_value, arg);
                return _s;
            } catch(System.Exception e) {
                Debug.LogError(e);
            }
            return _value;
        }

        public string getValue(string key) {
            if (m_dictionary.ContainsKey(key)) {
                if (!string.IsNullOrEmpty(m_dictionary[key][m_language])) {
                    return m_dictionary[key][m_language];
                }
            }
            return key;
        }

        
    }
}