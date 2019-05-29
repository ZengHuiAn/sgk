using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;

[RequireComponent(typeof(Image))]
public class CardFlipImage : MonoBehaviour {
    [Range(0, 1)]
    public float duration = 0.5f;

    public enum FlipDirection {
        Horizontal, Vertical,
    }

    public FlipDirection direction = FlipDirection.Horizontal;

    Sprite _nextSprite;
    public Sprite sprite {
        get { return image.sprite; }
        set {
            if (!running && image.sprite == value) {
                return;
            } else if (running && _nextSprite == value) {

            }

            _nextSprite = value;

            if (!running) {
                StartAnimation();
            }
        }
    }

    Image _image;
    Image image {
        get {
            if (_image == null) {
                _image = GetComponent<Image>();
            }
            return _image;
        }
    }

    bool running;
    void StartAnimation() {
        running = true;
        if (direction == FlipDirection.Horizontal) { 
            transform.DOScaleX(0, duration / 2).OnComplete(() => {
                ChangeIcon();
                transform.DOScaleX(1, duration / 2).OnComplete(FinishedAnimation);
            });
        } else {
            transform.DOScaleY(0, duration / 2).OnComplete(() => {
                ChangeIcon();
                transform.DOScaleY(1, duration / 2).OnComplete(FinishedAnimation);
            });
        }
    }

    public void ChangeIcon() {
        image.sprite = _nextSprite;
        _nextSprite = null;
    }

    public void FinishedAnimation() {
        running = false;
        if (_nextSprite == null) {
            return;
        }

        if (_nextSprite == image.sprite) {
            _nextSprite = null;
        } else {
            StartAnimation();
        } 
    }

    [ContextMenu("Test")]
    public void Test() {
        int r = Random.Range(1, 3);
        if (r == 1) {
            sprite = SGK.ResourcesManager.Load<Sprite>("icon/100341.png");
        } else if (r == 2) {
            sprite = SGK.ResourcesManager.Load<Sprite>("icon/100421.png");
        } else {
            sprite = SGK.ResourcesManager.Load<Sprite>("icon/100431.png");
        }
    }
}
