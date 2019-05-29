using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class CreateCharacterLoad : MonoBehaviour {
        public Renderer process;
        public TextMesh processText;
        public Animator animator;
        private float m_percentV = 0;
        private System.Action m_callBack = null;
        private System.Action m_startCallBack = null;
        private GameObject m_spineNode;

        void Start() {
            SetPercent(0);
            InvokeRepeating("play", 0.05f, 0.025f);
        }

        private void SetPercent(float value) {
            if (process != null) {
                process.material.SetFloat("FillAmount", value);
            }

            if (processText != null) {
                processText.text = string.Format("{0}%", (int)(value * 100));
            }
            m_percentV = value;
        }

        private void closeLoad() {
            gameObject.SetActive(false);
            if (m_startCallBack != null) {
                m_startCallBack();
                if (m_spineNode) {
                    Invoke("showSpineNode", 0.5f);
                }
            }
        }

        private void showSpineNode() {
            if (m_spineNode) {
                m_spineNode.SetActive(true);
            }
        }

        private void play() {
            if ((m_percentV) >= 1) {
                CancelInvoke();
                Invoke("closeLoad", 0.5f);
            } else {
                SetPercent(m_percentV + 0.01f);
            }
        }

        public System.Action StartCallBack {
            set {
                m_startCallBack = value;
            }
        }

        public GameObject SpineNode {
            set {
                m_spineNode = value;
            }
        }

        public void PlayCloseAn(System.Action callback = null) {
            if (animator) {
                //gameObject.SetActive(true);
                //animator.SetInteger("sta", 1);
                m_callBack = callback;
                runCallBack();
                //Invoke("runCallBack", 1.0f);
            }
        }

        private void runCallBack() {
            if (m_callBack != null) {
                m_callBack();
            }
        }

        private void OnDestroy() {
            m_callBack = null;
            m_startCallBack = null;
        }
    }
}