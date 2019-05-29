using DG.Tweening;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {

    public class DialogAnim : MonoBehaviour {
        public GameObject mask;
        public GameObject[] viewRoot;

        public bool needClip = true;
        public AudioClip openClip;
        public AudioClip closeClip;

        public enum AnimTypeEnum {
            Scale          = 1, //普通窗口
            FullScreen     = 2, //全屏窗口
            FloatingWindow = 3, //浮窗
        }

        public AnimTypeEnum m_animType = AnimTypeEnum.Scale;
        public AnimTypeEnum AnimType {
            set {
                m_animType = value;
            }
            get {
                return m_animType;
            }
        }

        private System.Action m_startCallBack;
        public System.Action startCallBack {
            set {
                m_startCallBack = value;
            }
            get {
                return m_startCallBack;
            }
        }

        private System.Action m_destroyCallBack;
        public System.Action destroyCallBack {
            set {
                m_destroyCallBack = value;
            }
            get {
                return m_destroyCallBack;
            }
        }

        public bool OnStart = false;
        private void Start() {
//             if (OnStart) {
//                 PlayStartAnim();
//             }
        }

        private void scaleStart() {
            if (mask) {
                var _canvasGroup = mask.GetComponent<CanvasGroup>();
                if (_canvasGroup == null) {
                    _canvasGroup = mask.AddComponent<CanvasGroup>();
                }
                _canvasGroup.alpha = 0;
                _canvasGroup.DOFade(1, 0.3f).SetDelay(0.15f).OnComplete(() => {
                    _canvasGroup.alpha = 1;
                });
            }
            if (viewRoot != null && viewRoot.Length > 0) {
                foreach (var it in viewRoot) {
                    if (it != null) {
                        var _pos = it.transform.localPosition;
                        var _scale = it.transform.localScale;

                        it.transform.localPosition += new Vector3(0, -605, 0);
                        it.transform.DOLocalMove(_pos, 0.27f).OnComplete(() => {
                            it.transform.localPosition = _pos;
                        });

                        it.transform.localScale = new Vector3(0.15f, 0.03f, 1);
                        it.transform.DOScale(new Vector3(1.15f, 1.15f, 1.1f), 0.25f).OnComplete(() => {
                            it.transform.DOScale(_scale, 0.03f).OnComplete(() => {
                                it.transform.localScale = _scale;
                            });
                        });
                    }                    
                }
            }
            transform.DOLocalMoveZ(0, 0.3f).OnComplete(() => {
                if (startCallBack != null) {
                    startCallBack();
                }
            });
        }

        private void scaleDestroy() {
            if (mask) {
                var _canvasGroup = mask.GetComponent<CanvasGroup>();
                if (_canvasGroup) {
                    _canvasGroup.DOFade(0, 0.15f).OnComplete(() => {
                        _canvasGroup.alpha = 0;
                    });
                }
            }
            if (viewRoot != null && viewRoot.Length > 0) {
                foreach (var it in viewRoot) {
                    if (it != null) {
                        var _scale = it.transform.localScale;
                        it.transform.DOScale(new Vector3(1.2f, 1.2f, 1.2f), 0.2f);

                        var _pos = it.transform.localPosition;
                        it.transform.DOLocalMove(it.transform.localPosition + new Vector3(0, -862, 0), 0.2f).SetDelay(0.05f);
                        it.transform.DOScale(new Vector3(1, 0.4f, 1), 0.2f).SetDelay(0.05f);
                    }
                }
            }
            SGK.Action.DelayTime.Create(0.3f).OnComplete(() => {
                if (destroyCallBack != null) {
                    destroyCallBack();
                }
            });
        }

        private GameObject m_fullScreenTopBar;
        private GameObject m_fullScreenBottomBar;
        public void PlayFullScreenBarStart(GameObject top, GameObject bottom) {
            if (top) {
                m_fullScreenTopBar = top;
            }
            if (bottom) {
                m_fullScreenBottomBar = bottom;
            }
            if (m_fullScreenTopBar) {
                var _pos = m_fullScreenTopBar.transform.localPosition;
                m_fullScreenTopBar.transform.localPosition = _pos + new Vector3(0, 50, 0);
                m_fullScreenTopBar.transform.DOLocalMove(_pos, 0.15f).OnComplete(() => {
                    m_fullScreenTopBar.transform.localPosition = _pos;
                });
            }
            if (m_fullScreenBottomBar) {
                var _pos = m_fullScreenBottomBar.transform.localPosition;
                m_fullScreenBottomBar.transform.localPosition = _pos + new Vector3(0, -50, 0);
                m_fullScreenBottomBar.transform.DOLocalMove(_pos, 0.15f).OnComplete(() => {
                    m_fullScreenBottomBar.transform.localPosition = _pos;
                });
            }
        }

        private void playFullScreenBarDestroy() {
            if (m_fullScreenTopBar) {
                var _pos = m_fullScreenTopBar.transform.localPosition;
                m_fullScreenTopBar.transform.DOLocalMove(_pos + new Vector3(0, 50, 0), 0.05f);
            }
//             if (m_fullScreenBottomBar) {
//                 var _pos = m_fullScreenBottomBar.transform.localPosition;
//                 m_fullScreenBottomBar.transform.DOLocalMove(_pos + new Vector3(0, -50, 0), 0.05f);
//             }
        }

        private void fullScreenStart() {
            if (mask) {
                var _canvasGroup = mask.GetComponent<CanvasGroup>();
                if (_canvasGroup == null) {
                    _canvasGroup = mask.AddComponent<CanvasGroup>();
                }
                _canvasGroup.alpha = 0;
                _canvasGroup.DOFade(1, 0.15f).OnComplete(() => {
                    _canvasGroup.alpha = 1;
                });
            }
            if (viewRoot != null && viewRoot.Length > 0) {
                foreach (var it in viewRoot) {
                    if (it != null) {
                        var _canvasGroup = it.GetComponent<CanvasGroup>();
                        if (_canvasGroup == null) {
                            _canvasGroup = it.AddComponent<CanvasGroup>();
                        }
                        _canvasGroup.alpha = 0;
                        _canvasGroup.DOFade(1, 0.15f).OnComplete(() => {
                            _canvasGroup.alpha = 1;
                        });
                    }
                }
            }
            transform.DOLocalMoveZ(0, 0.15f).OnComplete(() => {
                if (startCallBack != null) {
                    startCallBack();
                }
            });
        }

        private void fullScreenDestroy() {
            playFullScreenBarDestroy();
            if (mask) {
                var _canvasGroup = mask.GetComponent<CanvasGroup>();
                if (_canvasGroup == null) {
                    _canvasGroup = mask.AddComponent<CanvasGroup>();
                }
                _canvasGroup.DOFade(0, 0.2f).SetDelay(0.05f);
            }
            if (viewRoot != null && viewRoot.Length > 0) {
                foreach (var it in viewRoot) {
                    if (it != null) {
                        var _canvasGroup = it.GetComponent<CanvasGroup>();
                        if (_canvasGroup == null) {
                            _canvasGroup = it.AddComponent<CanvasGroup>();
                        }
                        _canvasGroup.DOFade(0, 0.2f).SetDelay(0.05f);
                    }
                }
            }
            SGK.Action.DelayTime.Create(0.25f).OnComplete(() => {
                if (destroyCallBack != null) {
                    destroyCallBack();
                }
            });
        }

        private void floatingWindowStart() {
            if (mask) {
                var _canvasGroup = mask.GetComponent<CanvasGroup>();
                if (_canvasGroup == null) {
                    _canvasGroup = mask.AddComponent<CanvasGroup>();
                }
                _canvasGroup.alpha = 0;
                _canvasGroup.DOFade(1, 0.05f).SetDelay(0.1f).OnComplete(() => {
                    _canvasGroup.alpha = 1;
                });
            }
            if (viewRoot != null && viewRoot.Length > 0) {
                foreach (var it in viewRoot) {
                    if (it != null) {
                        var _pos = it.transform.localPosition;
                        var _scale = it.transform.localScale;

                        it.transform.localScale = new Vector3(1, 0.01f, 1);
                        it.transform.DOScale(new Vector3(1, 1.1f, 1), 0.12f).OnComplete(() => {
                            it.transform.DOScale(new Vector3(1, 1, 1), 0.03f).OnComplete(() => {
                                it.transform.localScale = _scale;
                            });
                        });
                    }
                }
            }
            transform.DOLocalMoveZ(0, 0.15f).OnComplete(() => {
                if (startCallBack != null) {
                    startCallBack();
                }
            });
        }

        private void floatingWindowDestroy() {
            if (mask) {
                var _canvasGroup = mask.GetComponent<CanvasGroup>();
                if (_canvasGroup == null) {
                    _canvasGroup = mask.AddComponent<CanvasGroup>();
                }
                _canvasGroup.DOFade(0, 0.1f);
            }

            if (viewRoot != null && viewRoot.Length > 0) {
                foreach (var it in viewRoot) {
                    if (it != null) {
                        var _pos = it.transform.localPosition;
                        var _scale = it.transform.localScale;

                        it.transform.DOScale(new Vector3(1, 1.1f, 1), 0.03f).OnComplete(() => {
                            it.transform.DOScale(new Vector3(1, 0.01f, 1), 0.12f);
                        });
                    }
                }
            }

            SGK.Action.DelayTime.Create(0.15f).OnComplete(() => {
                if (destroyCallBack != null) {
                    destroyCallBack();
                }
            });
        }

        public void PlayStartAnim() {
            if (needClip) {
                if (openClip == null) {
                    SGK.BackgroundMusicService.PlayUIClickSound(SGK.QualityConfig.GetInstance().defaultUIOpenAudio);
                } else {
                    SGK.BackgroundMusicService.PlayUIClickSound(openClip);
                }
            }
            if (AnimType == AnimTypeEnum.Scale) {
                scaleStart();
            } else if(AnimType == AnimTypeEnum.FullScreen) {
                fullScreenStart();
            } else if(AnimType == AnimTypeEnum.FloatingWindow) {
                floatingWindowStart();
            } else {
                if (startCallBack != null) {
                    startCallBack();
                }
            }
        }

        public void PlayDestroyAnim() {
            if (needClip) {
                transform.DORotate(new Vector3(0, 0, 0), 0.12f).OnComplete(() => {
                    if (closeClip == null) {
                        SGK.BackgroundMusicService.PlayUIClickSound(SGK.QualityConfig.GetInstance().defaultUICloseAudio);
                    } else {
                        SGK.BackgroundMusicService.PlayUIClickSound(closeClip);
                    }
                });
            }
            if (AnimType == AnimTypeEnum.Scale) {
                scaleDestroy();
            } else if(AnimType == AnimTypeEnum.FullScreen) {
                fullScreenDestroy();

            } else if (AnimType == AnimTypeEnum.FloatingWindow) {
                floatingWindowDestroy();

            } else {
                if (destroyCallBack != null) {
                    destroyCallBack();
                }
            }
        }

        private void OnDestroy() {
            m_startCallBack = null;
            m_destroyCallBack = null;
        }
    }
}
