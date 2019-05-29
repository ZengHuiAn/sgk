using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using XLua;
using DG.Tweening;
using UnityEngine.Events;

namespace SGK
{
    [ExecuteInEditMode]
    public class ItemIcon : MonoBehaviour, IPointerClickHandler, IPointerDownHandler, IPointerUpHandler
    {
        public bool disableTween = true;
        private LuaTable ItemInfo;
        public int pos = 0;
        public System.Action onClick;
        [HideInInspector]
        public UnityEvent _onClick;
        public System.Action onPointDown;
        [HideInInspector]
        public UnityEvent _onPointDown;
        public System.Action onPointUp;
        [HideInInspector]
        public UnityEvent _onPointUp;

        Vector3 scale;
        
        public void Start()
        {
            scale = transform.localScale;

            if (_onClick == null)
            {
                _onClick = new UnityEvent();
            }
            if (_onPointDown == null)
            {
                _onPointDown = new UnityEvent();
            }
            if (_onPointUp == null)
            {
                _onPointUp = new UnityEvent();
            }

            float parentScale = Mathf.Min(transform.parent.transform.localScale.x, transform.parent.parent.transform.localScale.x);
            parentScale = Mathf.Min(transform.localScale.x, parentScale);
            float textScale = Mathf.Clamp(1 / parentScale, 1, 2);
            if (LowerRightText != null)
            {           
                LowerRightText.transform.localScale = Vector3.one * textScale;
                if (parentScale<0.7f)
                {
                    LowerRightText.transform.localPosition = LowerRightText.transform.localPosition + new Vector3(0, -23, 0);
                }
            }
            if (NameText != null)
            {
                NameText.transform.localScale = Vector3.one * textScale;
            }
            if (topLeftMark != null)//默认0 不显示（1必得2概率）
            {
               topLeftMark.transform.localScale = Vector3.one * textScale;
            }
        }

        private void OnDestroy() {
            onClick = null;
            onPointDown = null;
            onPointUp = null;;
        }

        bool _showDetail = false;
        public bool showDetail
        {
            get { return _showDetail; }
            set
            {
                if (_showDetail != value)
                {
                    _showDetail = value;
                    Image clickNode = gameObject.GetComponent<Image>();
                    if (clickNode == null)
                    {
                        gameObject.AddComponent<Image>();
                    }
                    gameObject.GetComponent<Image>().raycastTarget = true;
                    gameObject.GetComponent<Image>().color = new Vector4(1, 1, 1, 0);
                    gameObject.GetComponent<Image>().enabled = _showDetail;
                }
            }
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (showDetail)
            {
                int[] msg = { pos, Count };
                
                if (onClick != null)
                {
                    onClick();
                }
                else
                {
                    LuaController.DispatchEvent("OnClickItemIcon", ItemInfo, msg);
                }

                if (_onClick != null)
                {
                    _onClick.Invoke();
                }
               
            }
        }
        public void OnPointerDown(PointerEventData eventData)
        {
            if (!disableTween)
            {
                transform.DOScale(scale * 0.8f, 0.1f);
            }
            if (showDetail)
            {
                if (onPointDown != null)
                {
                    onPointDown();
                }
             
                if (_onPointDown != null)
                {
                    _onPointDown.Invoke();
                }
            }
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            transform.DOScale(scale, 0.1f);
            if (showDetail)
            {
                if (onPointUp != null)
                {
                    onPointUp();
                }
       
                if (_onPointUp != null)
                {
                    _onPointUp.Invoke();
                }

            }
        }
        [SerializeField]
        string _icon = "";
        public string Icon
        {
            get { return _icon; }
            set
            {
                if (_icon != value)
                {
                    _icon = value;
                    UpdateIcon();
                }
            }
        }
        [SerializeField]
        int _Count = 0;
        public int Count
        {
            get { return _Count; }
            set
            {
                if (_Count != value)
                {
                    _Count = value;
                    UpdateValue();
                }
            }
        }
        int _LimitCount = 0;
        public int LimitCount
        {
            get { return _LimitCount; }
            set
            {
                if (_LimitCount!=value)
                {
                    _LimitCount = value;
                    UpdateValue();
                }
            }

        }

       [SerializeField]
        int _SubType = 0;
        public int SubType
        {
            get { return _SubType; }
            set
            {
                if (_SubType != value)
                {
                    _SubType = value;
                    UpdateQuality();
                }
            }
        }
        [SerializeField]
        string _Desc = "";
        public string Desc
        {
            get { return _Desc; }
            set
            {
                if (_Desc != value)
                {
                    _Desc = value;
                    UpdateDesc();
                }
            }
        }
        [SerializeField]
        string _Name = "";
        public string Name
        {
            get { return _Name; }
            set
            {
                if (_Name != value)
                {
                    _Name = value;
                    UpdateName();
                }
            }
        }
        [SerializeField]
        [Range(0, 5)]
        int _quality = 0;
        public int Quality
        {
            get { return _quality; }
            set
            {
                if (_quality != value)
                {
                    _quality = value;
                    UpdateQuality();
                }
            }
        }
        int _type = 0;
        public int Type
        {
            get { return _type; }
            set
            {
                if (_type != value)
                {
                    _type = value;
                    UpdateValue();
                }
            }
        }

        int _equipLv = 0;
        public int EquipLv
        {
            get { return _equipLv; }
            set
            {
                if (_equipLv != value)
                {
                    _equipLv = value;
                    UpdateValue();
                }
            }
        }
        bool _showName = false;
        public bool ShowNameText
        {
            get { return _showName; }
            set
            {
                if (_showName != value)
                {
                    _showName = value;
                    UpdateShowNameText();
                }
            }
        }

        int _getType=0;    
        public int GetType
        {
            get { return _getType; }
            set
            {
                if (_getType != value)
                {
                    _getType = value;
                    UpdateShowTopLeftmark();
                }
            }
        }
#if UNITY_EDITOR
        void Update()
        {
            if (!Application.isPlaying)
            {
                UpdateIcon();
                UpdateQuality();
                UpdateValue();
                UpdateDesc();
                UpdateName();
                UpdateShowNameText();
                UpdateShowTopLeftmark();
            }
        }
#endif
        void UpdateQuality()
        {
            if (frameImage != null)
            {
                if (_SubType == 201)//图纸使用 特殊边框
                {
                    frameImage.GetComponent<UGUISpriteSelector>().index = 8;
                }
                else
                {
                    frameImage.GetComponent<UGUISpriteSelector>().index = _quality;
                    //碎片有额外显示 mark
                    pieceMark.gameObject.SetActive(_SubType == 21 || _SubType == 22);
                }        
            }
            if (qualityFx!=null)
            {
                qualityFx.SetActive(_quality>=4);
            }         
        }
        void UpdateIcon()
        {
            if (itemIcon != null)
            {   
                itemIcon.gameObject.SetActive(_icon != "");
                if (_icon != "")
                {
                    if (itemIcon.sprite == null)
                    {
                    //    itemIcon.sprite = SGK.ResourcesManager.Load<UnityEngine.Sprite>("icon/" + _icon);
                    }
                    else
                    {
                        
                    }
                    itemIcon.LoadSprite("icon/" + _icon);
                }               
            }
        }
        void UpdateValue()
        {
            if (LowerRightText != null)
            {
                if (_type == 43 || _type == 45)
                {
                    //LowerRightText.text = string.Format("需{0}级", _equipLv);
                    LowerRightText.text = _equipLv!=0?string.Format("^{0}", _equipLv) : "";
                }
                else
                {
                    if (_Count == 0&& _LimitCount == 0)
                    {
                        LowerRightText.text = "";
                    }
                    else
                    {
                        // string showNum = _Count / 1000000 >= 1 ? ((_Count /1000000.0).ToString("F1") )+"M": _Count / 1000 >= 1 ? ((_Count / 1000.0).ToString("F1"))+"K" : _Count+"";
                        if (_LimitCount==0)
                        {
                            LowerRightText.text = "x" + _Count;//showNum;
                            LowerRightText.color = Color.white;
                        }
                        else
                        {
                            LowerRightText.text = _Count+ "/" + _LimitCount ;//showNum;
                            if (_LimitCount > _Count)
                            {
                                LowerRightText.color = Color.red;
                            }
                            else
                            {
                                LowerRightText.color = Color.green;
                            }
                            
                        }
                        
                    }
                }    
            }
        }
        void UpdateDesc()
        {
            if (ItemDesc != null)
            {
                ItemDesc.text = _Desc;
            }
        }
        void UpdateName()
        {
            if (NameText != null)
            {
                NameText.text = _Name;
            }
        }
        void UpdateShowNameText()
        {
            if (NameText != null)
            {
                NameText.gameObject.SetActive(_showName);
            }
        }
        void UpdateShowTopLeftmark()
        {
            if(topLeftMark!=null)//默认0 不显示（1必得2概率）
            {
                topLeftMark.gameObject.SetActive(_getType!=0);
                if(_getType!=0)
                {   if(topLeftMark.GetComponent<UGUISpriteSelector>()!=null)
                    {
                        topLeftMark.gameObject.AddComponent<UGUISpriteSelector>();
                    }
                    topLeftMark.GetComponent<UGUISpriteSelector>().index = _getType-1;
                }
            }
        }
        public static ItemIcon Get(GameObject obj)
        {
            ItemIcon del = obj.GetComponent<ItemIcon>();
            if (del == null)
            {
                del = obj.AddComponent<ItemIcon>();
            }

            return del;
        }
        public void SetInfo(LuaTable t, bool showName = false, int sellCount = -1,int limitCount=0)//默认count为-1（取当前拥有数量） 当传入数量 为0时不显示数量
        {    
            int targetQulity = t.Get<int>("quality");
            int targetCount = sellCount == -1 ? t.Get<int>("count") : sellCount;
            int targetType = t.Get<int>("type");
            string targetIcon = (targetType==43|| targetType == 45)? t.Get<string>("icon_2") : t.Get<string>("icon");
            int targetSubType = t.Get<int>("sub_type");
            int targetLv = 0;
            // int targetPos = (targetType == 43 || targetType == 45) ? t.Get<int>("sub_type") : 0;//t.Get<int>("pos");//装备的穿戴位置 
            string targetDesc = t.Get<string>("type_name");
            string targetName = t.Get<string>("name");

            if (Icon == targetIcon && Quality == targetQulity && Count == targetCount && SubType == targetSubType && Desc == targetDesc && Name == targetName && ShowNameText == showName&& EquipLv == targetLv && LimitCount == limitCount)
            {
                return;
            }

            ItemInfo = t;
            Icon = targetIcon;
            Type = targetType;
            Quality = targetQulity;
            Count = targetCount;
            LimitCount = limitCount;
            SubType = targetSubType;
            Desc = targetDesc;
            Name = targetName;
            ShowNameText = showName;

            //EquipPos = targetPos;
            EquipLv = targetLv;
        }
        public Image itemIcon;
        [Space(20)]
        public Image frameImage;
        [Space(20)]
        public Text LowerRightText;
        public Text ItemDesc;
        public Text NameText;

        public Image pieceMark;
        public Image topLeftMark;
        public GameObject qualityFx;
    }
}
