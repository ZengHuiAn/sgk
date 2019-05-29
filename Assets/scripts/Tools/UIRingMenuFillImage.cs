using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;

public class UIRingMenuFillImage : MonoBehaviour {
    bool Fill = false;
    public Image FillImage;
    public GameObject Menu;
    public float StartDelay;
    [Range(0.1f, 3f)]
    public float FillDuration = 0.1f;

    float _DelayTime = 0;

    void EndFill() {
        Menu.SetActive(true);
        Menu.transform.DOScale(new Vector3(1, 1, 1), 0.2f);
        Fill = false;
        FillImage.fillAmount = 0;
    }

    void OnDisable()
    {
        Menu.transform.localScale = new Vector3(0, 0, 0);
        Fill = false;
        FillImage.fillAmount = 0;
        _DelayTime = 0;
    }

    public void StartFill()
    {
        Menu.transform.localScale = new Vector3(0, 0, 0);
        Menu.SetActive(false);
        Fill = true;
        FillImage.fillAmount = 0;
        _DelayTime = 0;
    }

    void Update () {
        if (Fill == true) {
            if (FillImage.fillAmount < 1 && (_DelayTime > StartDelay))
            {
                FillImage.fillAmount = FillImage.fillAmount + Time.deltaTime / FillDuration;
            }
            else if (FillImage.fillAmount >= 1)
            {
                EndFill();
            }
            _DelayTime = _DelayTime + Time.deltaTime;
        }
    }
}
