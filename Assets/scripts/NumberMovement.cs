using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class NumberMovement : MonoBehaviour {
    public int AniValue;

    public float ySpeed = 0.2f;
    public float xOffset = 0.2f;
    public float tirggetSpeed = 1f;

    static int next_number_index = 0;
    int number_index;

    public Text text;
    public Text nameText;
    public GameObject restrictImage;

    RectTransform rectTransform;
    float x = 0;
    void OnEnable() {
        number_index = ++next_number_index;

        rectTransform = GetComponent<RectTransform>();

        if (xOffset > 0) {
            Vector2 a = rectTransform.anchoredPosition;
            a.x += Random.Range(-xOffset, xOffset);
            rectTransform.anchoredPosition = a;
        }
        x = rectTransform.anchoredPosition.x;
    }

    void OnDisable() {
    }

    void Update() {
        Vector2 a = rectTransform.anchoredPosition;
        a.y += ySpeed * Time.deltaTime;
        a.x = x;
        rectTransform.anchoredPosition = a;

        Rect r1 = SGK.BattlefiledUIConstraint.rectInScreen(rectTransform, 0);
        rectTransform.position = SGK.BattlefiledUIConstraint.adJustPos(rectTransform.position, r1);
    }

    void OnTriggerStay2D(Collider2D other) {
        if (!other.gameObject.CompareTag("UIMoveableNumber")) {
            return;
        }

        if (other.gameObject.GetComponent<NumberMovement>().number_index > number_index) {
            Vector2 a = rectTransform.anchoredPosition;
            a.y += tirggetSpeed * Time.deltaTime;
            rectTransform.anchoredPosition = a;
        }
    }
}