using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using DG.Tweening;

public class UGUIClickEventListener : MonoBehaviour, IPointerClickHandler, IPointerDownHandler, IPointerUpHandler
{
    public System.Action onClick;
    public UnityEvent _onClick;
    public bool disableTween = false;
    public bool SkipClickTime = false;
    public Sprite DisabledSprite;
    public Sprite NormalSprite;
    public Image ImageBtn;
    // private Vector3 scale;
    static float lastClickTime = 0;
    public static float clickInterval = 0.25f;
    
    public static bool disableAllClickListener = false;

    [System.Serializable]
    public enum TweenStyle
    {
        DEFAULT,
        EXPAND,
        SHRINK,
        MOVEDOWN,
        MOVEDOWN_EXPAND,
    }
    public TweenStyle tweenStyle = TweenStyle.DEFAULT;

    /*
    public Vector3 DefaultScale {
        get {
            return scale;
        }
        set {
            scale = value;
        }
    }
    */
    public AudioClip clickClip;

    public void Start() {
        if (_onClick == null) {
            _onClick = new UnityEvent();
        }
        // scale = transform.localScale;
        ImageBtn = GetComponent<Image>();
        if (!NormalSprite && ImageBtn != null) {
            NormalSprite = ImageBtn.sprite;
        }
		UpdateInteractable();
    }
    [SerializeField]
    bool IsInteractable = true;
    public bool interactable {
        get { return IsInteractable; }
        set {
            if (IsInteractable != value) {
                IsInteractable = value;
                UpdateInteractable();
            }
        }
    }
    void UpdateInteractable() {
        if (ImageBtn != null && DisabledSprite != null && NormalSprite != null) {
            if (interactable) {
                ImageBtn.sprite = NormalSprite;
            } else {
                ImageBtn.sprite = DisabledSprite;
            }
        }
    }

    bool onClickFired = false;
    public void OnPointerDown(PointerEventData eventData) {
        onClickFired = false;
		if (interactable) {
            if (!disableTween)
            {
                BtnAnimate();
            }
            if (clickClip == null) {
                SGK.BackgroundMusicService.PlayUIClickSound(SGK.QualityConfig.GetInstance().defaultUIClickAudio);
            } else {
                SGK.BackgroundMusicService.PlayUIClickSound(clickClip);
            }
        }
    }

    Tween tween;
	public void BtnAnimate(float delay = 0.1f){
        if (tween != null) {
            return;
        }

        switch(tweenStyle) {
            case TweenStyle.DEFAULT:
            case TweenStyle.MOVEDOWN:
                tween = transform.DOLocalMoveY(-10, delay).SetRelative();
                break;
            case TweenStyle.EXPAND:
                tween = transform.DOScale(transform.localScale * 1.1f, delay);
                break;
            case TweenStyle.SHRINK:
                tween = transform.DOScale(transform.localScale * 0.8f, delay);
                break;
            case TweenStyle.MOVEDOWN_EXPAND:
                Sequence seq = DOTween.Sequence();
                seq.Append(transform.DOLocalMoveY(-10, 0.1f).SetRelative());
                seq.Insert(0, transform.DOScale(transform.localScale * 1.1f, delay));
                tween = seq;
                break;
        }
        if (tween != null) {
            tween.SetAutoKill(false);
            tween.OnRewind(() => {
                tween.Kill();
                tween = null;
            });
        }
	}

    public void BtnReset() {
        if (tween != null) {
            tween.PlayBackwards();
        }
    }

    public void OnPointerUp(PointerEventData eventData) {
		BtnReset ();
        if (eventData.pointerEnter != gameObject && !eventData.dragging) {
            if (Vector2.Distance(eventData.pressPosition, eventData.position) < 10) {
                Toggle toggle = GetComponent<Toggle>();
                if (toggle != null && toggle.interactable) {
                    if (!(toggle.group != null && toggle.group.allowSwitchOff)) {
                        toggle.isOn = true;
                    }
                }

                OnPointerClick(eventData);
            }
        }
    }

    public void OnPointerClick(PointerEventData eventData) {
        if (disableAllClickListener) {
            return;
        }

        if (onClickFired) {
            return;
        }

        onClickFired = true;

        if (eventData.dragging) {
            return;
        }

        if (IsInteractable == false) {
            return;
        }
        if (!SkipClickTime) {
            if (Time.time - lastClickTime < clickInterval) {
                return;
            }

            lastClickTime = Time.time;
        }

        Invoke("doClick", 0.1f);
    }

    void doClick()
    {
        if (onClick != null)
        {
            onClick();
        }
        if (_onClick != null)
        {
            _onClick.Invoke();
        }
    }

    public static UGUIClickEventListener Get(GameObject obj, bool disableTween = false) {
        UGUIClickEventListener del = obj.GetComponent<UGUIClickEventListener>();
        if (del == null) {
            del = obj.AddComponent<UGUIClickEventListener>();
            del.disableTween = disableTween;
        }

        return del;
    }

    Tween toggleTween = null;
    public static float toggleTweenOffset = 10;
    public void onToggleActive(bool active) {
        if (!active) {
            if (toggleTween != null) {
                toggleTween.PlayBackwards();
            }
            return;
        }

        if (toggleTween == null) {
            toggleTween = transform.DOLocalMoveY(toggleTweenOffset, 0.1f).SetRelative();
            toggleTween.SetAutoKill(false);
        }
        toggleTween.PlayForward();
    }

    private void OnDestroy() {
        if (tween != null) {
            tween.Kill();
        }

        if (toggleTween != null) {
            toggleTween.Kill();
        }

        onClick = null;
    }
}
