using UnityEngine;
using System.Collections;
using UnityEngine.UI;


public class ProcessBar : MonoBehaviour {
    public Image bgImage;
    public Image valueImage;
    public Text  valueText;

    // public float speed = 10;

    public int maxValue = 100;
    public int value = 100;
    public string text = "";

    public bool autoText = true;

    // Use this for initialization
	void Start () {
    }

    void Update() {
        if (autoText) {
            text = string.Format("{0}/{1}", value, maxValue);
        }

        if (valueText != null) {
            valueText.text = text;
        }
        updateImage();
    }
	
    void updateImage() {
        Vector2 _size = bgImage.gameObject.GetComponent<RectTransform>().rect.size;
        RectTransform rt = valueImage.gameObject.GetComponent<RectTransform>();
        if (maxValue > 0) {
            Vector2 currentSize = rt.sizeDelta;
            Vector2 targetSize = new Vector2(_size.x * (value- maxValue) / maxValue, currentSize.y);
            rt.sizeDelta = targetSize; //  Vector2.MoveTowards(currentSize, targetSize, _size.x / 100.0f * speed);
        }
    }
}
