using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;

[ExecuteInEditMode]
public class BattlefieldProgressBar : MonoBehaviour {
    public RectTransform valueImage;
    public RectTransform valueImageExt;
    public RectTransform valueShadowImage;

    public RectTransform textArea;

    public Text titleText;
    public Text labelText;

    public Sprite[] valueSprites;

    public bool fromRight = false;

    [SerializeField]
    [Range(-50, 50)]
    float _textAreaPosition = 0;
    public float textAreaPosition {
        get { return _textAreaPosition; }
        set {
            if (_textAreaPosition != value || !Application.isPlaying) {
                _textAreaPosition = value;
                UpdateTextArena();
            }
        }
    }

    public bool showShadow = true;

    public static string percentFormat = "#0.#%";

    public bool showPercent = false;

    public string title {
        get { return titleText.text; }
        set { titleText.text = value; }
    }

    bool filledImage = false;
    bool filledImageExt = false;
    bool filledImageShadow = false;

    bool isFilled(RectTransform rt) {
        if (rt == null) return false;
        Image image = rt.GetComponent<Image>();
        if (image == null) return false;
        return image.type == Image.Type.Filled;
    }

    private void Start() {
        filledImage = isFilled(valueImage);
        filledImageExt = isFilled(valueImageExt);
        filledImageShadow = isFilled(valueShadowImage);

        UpdateTextArena();
    }

    Image _valueImage;
    Image valueUIImage {
        get {
            if (_valueImage == null && valueImage != null) {
                _valueImage = valueImage.GetComponent<Image>();
            }
            return _valueImage;
        }
    }

    public int color {
        // get { return valueUIImage.color; }
        set {
            if (value >= 0 && value < valueSprites.Length) {
                valueUIImage.sprite = valueSprites[value];
            }
        }
    }

    public void SetValue(int cur, int max, int ext = 0) {
        int rmax = Mathf.Max(max, cur + ext);

        float fillAmount = Mathf.Clamp(cur * 1.0f / rmax, 0, 1);
        if (showPercent && labelText != null) {
            float percent = Mathf.Clamp(cur * 1.0f / max, ((cur > 0) ? 0.001f : 0.0f), 1);
            if (percent > 0.01f) {
                percent = Mathf.Floor(percent * 100) / 100;
            }
            labelText.text = percent.ToString(percentFormat);
        } else if(labelText != null) {
            labelText.text = string.Format("{0}/{1}", cur, max);
        }

        SetAnchor(valueImage, fillAmount, filledImage);

        if (valueImageExt != null) {
            fillAmount = Mathf.Clamp((cur + ext) * 1.0f / rmax, 0, 1);
            SetAnchor(valueImageExt, fillAmount, filledImageExt);
        }

        if (valueShadowImage != null) {
            if (showShadow && Application.isPlaying) {
                RunTo(valueShadowImage, fillAmount, filledImageShadow);
            } else {
                SetAnchor(valueShadowImage, fillAmount, filledImageShadow);
            }
        }
    }

    void UpdateTextArena() {
        if (textArea != null) {
            textArea.anchoredPosition = new Vector2(0, _textAreaPosition);
        }
    }

    void RunTo(RectTransform rt, float x, bool isFilled) {
        if (isFilled) {
            var image = rt.GetComponent<Image>();
            float t = Mathf.Abs(image.fillAmount - x) * 2;
            image.DOFillAmount(x, t);
            return;
        }

        rt.DOKill();
        if (!fromRight) {
            float t = Mathf.Abs(rt.anchorMax.x - x) * 2;
            rt.DOAnchorMax(new Vector2(x, 1), t);
            rt.anchorMin = Vector2.zero;
        } else {
            x = 1 - x;
            float t = Mathf.Abs(rt.anchorMin.x - x) * 2;
            rt.DOAnchorMin(new Vector2(x, 0), t);
            rt.anchorMax = Vector2.one;
        }
    }

    void SetAnchor(RectTransform rt, float fillAmount, bool isFilled) {
        if (isFilled) {
            rt.GetComponent<Image>().fillAmount = fillAmount;
            return;
        }

        if (!fromRight) {
            if (rt != null && fillAmount != rt.anchorMax.x) {
                rt.anchorMax = new Vector2(fillAmount, 1);
                rt.anchorMin = Vector2.zero;
            }
        } else {
            if (rt != null && fillAmount != rt.anchorMin.x) {
                rt.anchorMin = new Vector2(1 - fillAmount, 0);
                rt.anchorMax = Vector2.one;
            }
        }
    }

    [Range(0, 100)]
    public float _value = 0;

    [Range(0, 100)]
    public float _ext = 0;
#if UNITY_EDITOR
    private void Update() {
        if (!Application.isPlaying) {
            SetValue((int)_value, 100, (int)_ext);
            textAreaPosition = _textAreaPosition;
        }
    }
#endif
}
