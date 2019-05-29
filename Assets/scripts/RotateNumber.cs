using DG.Tweening;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
    public class RotateNumber : MonoBehaviour {
        [SerializeField]
        [Tooltip("按最高位起始顺序设置每位数字Text（显示组）")]
        private List<Text> _numbers;
        public List<Vector3> m_numbersPoint = new List<Vector3>();
        [SerializeField]
        [Tooltip("按最高位起始顺序设置每位数字Text（替换组）")]
        private List<Text> _unactiveNumbers;
        /// <summary>
        /// 动画时长
        /// </summary>
        [SerializeField]
        private float _duration = 1.5f;
        /// <summary>
        /// 数字每次滚动时长
        /// </summary>
        [SerializeField]
        private float _rollingDuration = 0.05f;
        /// <summary>
        /// 数字每次变动数值
        /// </summary>
        private int _speed;
        /// <summary>
        /// 滚动延迟（每进一位增加一倍延迟，让滚动看起来更随机自然）
        /// </summary>
        [SerializeField]
        private float _delay = 0.008f;
        /// <summary>
        /// Text文字宽高
        /// </summary>
        private Vector2 _numberSize;
        /// <summary>
        /// 当前数字
        /// </summary>
        private int _curNumber;
        /// <summary>
        /// 起始数字
        /// </summary>
        private int _fromNumber;
        /// <summary>
        /// 最终数字
        /// </summary>
        private int _toNumber;
        /// <summary>
        /// 各位数字的缓动实例
        /// </summary>
        private List<Tweener> _tweener = new List<Tweener>();
        /// <summary>
        /// 是否处于数字滚动中
        /// </summary>
        private bool _isJumping;
        /// <summary>
        /// 滚动完毕回调
        /// </summary>
        public System.Action OnComplete;

        public enum AlignmentType {
            Nothing = 0,
            Left    = 1,
            Right   = 2,
        }

        public bool needAlignment = false;
        public AlignmentType m_alignment = AlignmentType.Nothing;
        public AlignmentType alignment {
            get {
                return m_alignment;
            }
            set {
                if (m_alignment != value) {
                    m_alignment = value;
                    changeAlignment();
                }
            }
        }

        private int getNumberCount(int number) {
            var _count = 0;
            do {
                _count++;
                number /= 10;
            } while (number > 0);
            return _count;
        }

        private void changeAlignment() {
            changeAlignment(number);
        }

        private void changeAlignment(int maxNumber) {
            if (needAlignment) {
                var _count = getNumberCount(maxNumber);
                if (m_alignment == AlignmentType.Right) {
                    if (_count < _numbers.Count) {
                        for (int i = 0; i < _numbers.Count; ++i) {
                            _numbers[i].gameObject.SetActive(i < _count);
                            _unactiveNumbers[i].gameObject.SetActive(i < _count);
                        }
                    }
                }
            } else {
                for (int i = 0; i < _numbers.Count - 1; ++i) {
                    _numbers[i].gameObject.SetActive(true);
                    _unactiveNumbers[i].gameObject.SetActive(true);
                    _numbers[i].gameObject.transform.localPosition = new Vector3(m_numbersPoint[i].x, _numbers[i].gameObject.transform.localPosition.y, _numbers[i].gameObject.transform.localPosition.z);
                    _unactiveNumbers[i].gameObject.transform.localPosition = new Vector3(m_numbersPoint[i].x, _unactiveNumbers[i].gameObject.transform.localPosition.y, _unactiveNumbers[i].gameObject.transform.localPosition.z);
                }
            }
        }

        private void Awake() {
            if (_numbers.Count == 0 || _unactiveNumbers.Count == 0) {
                return;
            }
            m_numbersPoint.Clear();
            if (m_numbersPoint.Count <= 0) {
                for (int i = 0; i < _numbers.Count; ++i) {
                    m_numbersPoint.Add(_numbers[i].gameObject.transform.localPosition);
                }
            }
            _numberSize = _numbers[0].rectTransform.sizeDelta;
        }

        public float duration {
            get { return _duration; }
            set {
                _duration = value;
            }
        }

        private float _different;
        public float different {
            get { return _different; }
        }

        public void Change(int from, int to) {
            bool isRepeatCall = _isJumping && _fromNumber == from && _toNumber == to;
            if (isRepeatCall) return;
            //changeAlignment(Math.Max(Math.Abs(from), Math.Abs(to)));

            bool isContinuousChange = (_toNumber == from) && ((to - from > 0 && _different > 0) || (to - from < 0 && _different < 0));
            if (_isJumping && isContinuousChange) {
            } else {
                _fromNumber = from;
                _curNumber = _fromNumber;
            }
            _toNumber = to;

            _different = _toNumber - _fromNumber;
            _speed = (int)Math.Ceiling(_different / (_duration * (1 / _rollingDuration)));
            _speed = _speed == 0 ? (_different > 0 ? 1 : -1) : _speed;

            SetNumber(_curNumber, false);
            _isJumping = true;
            StopCoroutine("DoJumpNumber");
            StartCoroutine("DoJumpNumber");
        }

        public int number {
            get { return _toNumber; }
            set {
                if (_toNumber == value) return;
                Change(_curNumber, _toNumber);
            }
        }           

        IEnumerator DoJumpNumber() {
            while (true) {
                if (_speed > 0)//增加
                {
                    _curNumber = Math.Min(_curNumber + _speed, _toNumber);
                } else if (_speed < 0) //减少
                  {
                    _curNumber = Math.Max(_curNumber + _speed, _toNumber);
                }
                SetNumber(_curNumber, true);

                if (_curNumber == _toNumber) {
                    StopCoroutine("DoJumpNumber");
                    _isJumping = false;
                    if (OnComplete != null) OnComplete();
                    yield return null;
                }
                yield return new WaitForSeconds(_rollingDuration);
            }
        }

        /// <summary>
        /// 设置战力数字
        /// </summary>
        /// <param name="v"></param>
        /// <param name="isTween"></param>
        public void SetNumber(int v, bool isTween) {
            char[] c = v.ToString().ToCharArray();
            Array.Reverse(c);
            string s = new string(c);

            if (!isTween) {
                for (int i = 0; i < _numbers.Count; i++) {
                    if (i < s.Count()) {
                        _numbers[i].text = s[i] + "";
                        if (needAlignment && m_alignment == AlignmentType.Left) {
                            _numbers[i].gameObject.SetActive(true);
                            _numbers[i].rectTransform.anchoredPosition = new Vector2(m_numbersPoint[i + (_numbers.Count - s.Count())].x, 0);
                        }
                    } else {
                        _numbers[i].text = "0";
                        if (needAlignment && m_alignment == AlignmentType.Left) {
                            _numbers[i].gameObject.SetActive(false);
                        }
                    }
                }
            } else {
                while (_tweener.Count > 0) {
                    _tweener[0].Complete();
                    _tweener.RemoveAt(0);
                }

                for (int i = 0; i < _numbers.Count; i++) {
                    if (i < s.Count()) {
                        _unactiveNumbers[i].text = s[i] + "";
                        if (needAlignment && m_alignment == AlignmentType.Left) {
                            _unactiveNumbers[i].gameObject.SetActive(true);
                            _unactiveNumbers[i].rectTransform.anchoredPosition = new Vector2(m_numbersPoint[i + (_numbers.Count - s.Count())].x, _unactiveNumbers[i].rectTransform.anchoredPosition.y);
                        }
                    } else {
                        _unactiveNumbers[i].text = "0";
                        if (needAlignment && m_alignment == AlignmentType.Left) {
                            _unactiveNumbers[i].gameObject.SetActive(false);
                        }
                    }

                    if (needAlignment && m_alignment == AlignmentType.Left) {
                        if (i < s.Count()) {
                            _unactiveNumbers[i].rectTransform.anchoredPosition = new Vector2(m_numbersPoint[i + (_numbers.Count - s.Count())].x, (_speed > 0 ? -1 : 1) * _numberSize.y);
                        } else {
                            _unactiveNumbers[i].rectTransform.anchoredPosition = new Vector2(_unactiveNumbers[i].rectTransform.anchoredPosition.x, (_speed > 0 ? -1 : 1) * _numberSize.y);
                        }
                        if (i < s.Count()) {
                            _numbers[i].rectTransform.anchoredPosition = new Vector2(m_numbersPoint[i + (_numbers.Count - s.Count())].x, 0);
                        } else {
                            _numbers[i].rectTransform.anchoredPosition = new Vector2(_unactiveNumbers[i].rectTransform.anchoredPosition.x, 0);
                        }
                    } else {
                        _unactiveNumbers[i].rectTransform.anchoredPosition = new Vector2(_unactiveNumbers[i].rectTransform.anchoredPosition.x, (_speed > 0 ? -1 : 1) * _numberSize.y);
                        _numbers[i].rectTransform.anchoredPosition = new Vector2(_unactiveNumbers[i].rectTransform.anchoredPosition.x, 0);
                    }

                    if (_unactiveNumbers[i].text != _numbers[i].text) {
                        DoTween(_numbers[i], (_speed > 0 ? 1 : -1) * _numberSize.y, _delay * i);
                        DoTween(_unactiveNumbers[i], 0, _delay * i);

                        Text tmp = _numbers[i];
                        _numbers[i] = _unactiveNumbers[i];
                        _unactiveNumbers[i] = tmp;
                    }
                }
            }
        }

        public void DoTween(Text text, float endValue, float delay) {
            Tweener t = DOTween.To(() => text.rectTransform.anchoredPosition, (x) => {
                text.rectTransform.anchoredPosition = x;
            }, new Vector2(text.rectTransform.anchoredPosition.x, endValue), _rollingDuration - delay).SetDelay(delay);
            _tweener.Add(t);
        }

        [ContextMenu("test")]
        public void TestChange() {
            //Change(UnityEngine.Random.Range(1, 1), UnityEngine.Random.Range(1, 200));
            Change(1, 100);
        }
    }
}