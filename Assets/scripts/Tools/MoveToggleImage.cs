using System;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;
using System.Collections.Generic;

namespace SGK
{
    public class MoveToggleImage : MonoBehaviour
    {
        public GameObject image;        
        public void MoveImage(bool isOn)
        {
            if (isOn)
            {
                if (image != null)
                {
                    image.transform.DOLocalMove(this.gameObject.transform.localPosition, 0.3f).SetEase(Ease.InOutBack);
                }
            }
        }
    }
}
