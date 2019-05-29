using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class MiniMapFollowPlayer : MonoBehaviour {
        public GameObject m_playerObj;
        public Transform viewArea;

        private Vector3 m_min;
        private Vector3 m_max;
        private float m_oldOrth;

        private void upOrthographicSize() {
#if UNITY_EDITOR
            Camera _camera = GetComponent<Camera>();
            if (_camera) {
                if (_camera.orthographicSize == m_oldOrth) {
                    return;
                }
            } else {
                return;
            }
#endif
            if (viewArea) {
                m_min = (viewArea.position - viewArea.lossyScale / 2);
                m_max = (viewArea.position + viewArea.lossyScale / 2);

                Camera camera = GetComponent<Camera>();
#if UNITY_EDITOR
                m_oldOrth = camera.orthographicSize;
#endif
                if (camera) {
                    m_min.x += camera.orthographicSize * camera.aspect;
                    m_max.x -= camera.orthographicSize * camera.aspect;

                    m_min.z += camera.orthographicSize / Mathf.Sin(Vector3.Angle(transform.forward, viewArea.forward) * Mathf.Deg2Rad) - 1.8f;
                    m_max.z -= camera.orthographicSize / Mathf.Sin(Vector3.Angle(transform.forward, viewArea.forward) * Mathf.Deg2Rad) + 1.5f;

                    if (m_max.x < m_min.x) {
                        m_min.x = m_max.x = (m_min.x + m_max.x) / 2;
                    }

                    if (m_max.z < m_min.z) {
                        m_min.z = m_max.z = (m_min.z + m_max.z) / 2;
                    }
                }
            }
        }

        private void Start() {
            upOrthographicSize();
        }

        public GameObject PlayerObj {
            get { return m_playerObj; }
            set {
                m_playerObj = value;
            }
        }

        // Update is called once per frame
        void Update() {
#if UNITY_EDITOR
            upOrthographicSize();
#endif
            if (m_playerObj && viewArea) {
                Vector3 _pos = new Vector3();
                _pos.x = Mathf.Clamp(m_playerObj.transform.position.x, m_min.x, m_max.x);
                _pos.y = transform.position.y;
                _pos.z = Mathf.Clamp(m_playerObj.transform.position.z, m_min.z, m_max.z);
                transform.position = _pos;
            }
        }
    }
}
