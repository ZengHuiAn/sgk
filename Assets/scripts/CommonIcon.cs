using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using XLua;
using DG.Tweening;
using UnityEngine.Events;

namespace SGK
{
    [XLua.LuaCallCSharp]
    public class CommonIcon : MonoBehaviour {
        public Transform scaler;

        public Image _BGFrame;
        public UGUIClickEventListener _listener;

        public Image _Icon;
        public Image[] _Star;

        public UGUISelector _Frame;
        public Image _FrameImage;

        public Image _QualityAnimationFx;
        public Image _Owner;
        public Image[] _Mark;

        public Text _Name;
        public Text _Count;

        public Text[] _Label;

        public Sprite defaultIcon;

        public Sprite[] _MarkSprite;

        public System.Action onClick {
            set {
                if (_BGFrame != null) {
                    _BGFrame.raycastTarget = (value != null);
                }

                if (_listener) {
                    _listener.onClick = value;
                    _listener.disableTween = false;
                    _listener.enabled = (value != null);
                }
            }
        }

        public bool disableTween {
            get { return _listener == null || _listener.disableTween;  }
            set { if (_listener != null) _listener.disableTween = value;  }
        }

        bool _gray = false;
        public bool colorGray {
            get { return _gray;  }
            set {
                if (_gray != value) {
                    _gray = value;
                    UpdateMaterial();
                }
            }
        }

        Color IconColor {
            get {
                return Color.white;
            }
        }

        void SetIconSprite(Image image, Sprite sprite = null) {
            if (image != null) {
                image.sprite = sprite;
                image.color = (sprite == null) ? Color.clear : IconColor;
            }
        }

        void SetIconSprite(Image image, string name, Sprite defaultSprite = null) {
            if (image != null) {
                if (string.IsNullOrEmpty(name) || name == "0") {
                    SetIconSprite(image, defaultSprite);
                } else {
                    SetIconSprite(image, image.sprite);
                    image.LoadSprite(name, Color.white);
                }
            }
        }

        [ContextMenu("Reset")]
        public void Reset() {
            SetIconSprite(_BGFrame);
            onClick = null;
            colorGray = false;

            RectTransform rt = GetComponent<RectTransform>();
            rt.sizeDelta = new Vector2(130, 130);
            rt.localScale = Vector3.one;
            rt.localRotation = Quaternion.identity;
            rt.localPosition = Vector3.zero;

            Icon = null;
            Star = 0;
            Quality = 0;
            Scale = 1;
            Owner = null;
            SetName("");
            SetCount("");
            CleanMark();
            SetLabel();
        }

        public string Icon {
            set {
                SetIconSprite(_Icon, value, defaultIcon);
            }
        }

        public int Star {
            set {
                for (int i = 0; i < _Star.Length; i++) {
                    _Star[i].gameObject.SetActive(i < value);
                }
            }
        }

        public int Quality {
            get {
                return _Frame.index;
            }

            set {
                int quality = value;
                if (quality < 0) {
                    quality = 0;
                    _FrameImage.color = Color.clear;
                } else {
                    _FrameImage.color = Color.white;
                }
                
                if (quality >= _Frame.Count) quality = _Frame.Count - 1;
                _Frame.index = quality;
                _QualityAnimationFx.gameObject.SetActive(quality >= 4);
            }
        }

        public string Owner {
            set {
                SetIconSprite(_Owner, value);
            }
        }

        public string Count {
            set {
                SetCount(value);
            }
        }

        public int Level {
            set {
                SetLevel(value);
            }
        }

        public string Name {
            set {
                SetName(value);
            }
        }

        public float Scale {
            set {
                SetScale(value);
            }
        }

        public float CountScale {
            set{
                SetCountScale(value);
            }
        }

        public void SetInfo(string icon, string name, string count, int star = 0, int quality = -1) {
            SetIconSprite(_BGFrame);
            onClick = null;
            Scale = 1;
            Owner = null;
            CleanMark();
            SetLabel();
            Icon = icon;
            SetName(name);
            SetCount(count);
            Star = star;
            Quality = quality;
        }

        public void SetLabel(params string[] labels) {
            if (_Label != null) {
                for (int i = 0; i < _Label.Length; i++) {
                    SetText(_Label[i], (labels != null && i < labels.Length) ? labels[i] : null, Color.white);
                }
            }
        }

        public void SetLabel(string name, string label, int size = 0) {
            SetLabel(name, label, Color.white, size);
        }

        public void SetLabel(string name, string label, Color color, int size = 0) {
            if (_Label != null) {
                for (int i = 0; i < _Label.Length; i++) {
                    if (_Label[i] != null && _Label[i].gameObject.name == name) {
                        SetText(_Label[i], label, color, size);
                        break;
                    }
                }
            }
        }


        public void CleanMark() {
            if (_Mark != null) {
                for (int i = 0; i < _Mark.Length; i++) {
                    if (_Mark[i] != null) {
                        if (_Mark[i].gameObject.name[0] == '_') {
                            _Mark[i].color = Color.clear;
                        } else { 
                            SetIconSprite(_Mark[i], null);
                        }
                    }
                }
            }
        }

        public void SetMark(string markName, string spriteName) {
            for (int i = 0; i < _Mark.Length; i++) {
                if ((_Mark[i] != null) && _Mark[i].gameObject.name == markName) {
                    Sprite sprite = null;
                    for (int j = 0; j < _MarkSprite.Length; j++) {
                        if (_MarkSprite[j].name == spriteName) {
                            sprite = _MarkSprite[j];
                        }
                    }
                    SetIconSprite(_Mark[i], sprite);
                    break;
                }
            }
        }

        public void SetMark(string name, Sprite sprite = null) {
            if (_Mark != null) {
                for (int i = 0; i < _Mark.Length; i++) {
                    if ((_Mark[i] != null) && _Mark[i].gameObject.name == name) {
                        SetIconSprite(_Mark[i], sprite);
                        break;
                    }
                }
            }
        }

        public void SetName(string name, int size = 0) {
            SetName(name, Color.black, size);
        }

        public void SetName(string name, Color color, int size = 0) {
            SetText(_Name, name, color, size);
        }

        public void SetLevel(int level, int size = 24) {
            SetLevel(level, Color.white);
        }

        public void SetLevel(int level, Color color, int size = 24) {
            SetCount(string.Format("^{0}", level), Color.white, size);
        }

        public void SetCount(string count, int size = 0) {
            SetCount(count, Color.white);
        }

        public void SetCount(string count, Color color, int size = 0) {
            SetText(_Count, count, color, size);
        }

        public void SetCountScale(float scale){
            if (_Count != null) { 
                _Count.transform.localScale = Vector3.one * scale;
            }
        }

        public void SetCountScale(){
            if (_Count != null) { 
                float parentScale = Mathf.Min(transform.parent.transform.localScale.x, transform.parent.parent.transform.localScale.x);
                parentScale = Mathf.Min(transform.localScale.x, parentScale);
                float textScale = Mathf.Clamp(1 / parentScale, 1, 2);
                _Count.transform.localScale = Vector3.one * textScale;
                // if (parentScale<0.7f)
                // {
                //     _Count.transform.localPosition = _Count.transform.localPosition + new Vector3(0, -23, 0);
                // }
            }
        }

        void SetText(Text label, string text, Color color, int size = 0) {
            if (label != null) {
                label.text = text;
                label.color = color;
                if (size > 0) {
                    label.fontSize = size;
                }
            }
        }

        void SetScale(float scale) {
            if (scaler != null) {
                scaler.localScale = Vector3.one * scale;
            }
        }

        void UpdateMaterial() {
            Material material = _gray ? QualityConfig.GetInstance().grayMaterial : null;

            _Icon.material = material;
            for (int i = 0; i < _Star.Length; i++) {
                _Star[i].material = material;
            }

            _Frame.gameObject.GetComponent<Image>().material = material;
            for (int i = 0; i < _Mark.Length; i++) {
                _Mark[i].material = material;
            }
        }
    }
}
