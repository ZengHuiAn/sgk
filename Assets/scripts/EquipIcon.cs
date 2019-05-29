using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using XLua;
using DG.Tweening;
namespace SGK
{
    [ExecuteInEditMode]
    public class EquipIcon : MonoBehaviour, IPointerClickHandler, IPointerDownHandler, IPointerUpHandler
    {
        public bool disableTween = true;
        public int pos = 0;
        LuaTable EquipInfo;
        Vector3 scale;
        public void Start()
        {
            scale = transform.localScale;

            float parentScale = Mathf.Min(transform.parent.transform.localScale.x, transform.parent.parent.transform.localScale.x);
            parentScale = Mathf.Min(transform.localScale.x, parentScale);
            float textScale = Mathf.Clamp(1 / parentScale, 1, 2);
            if (LowerRightText != null)
            {
                LowerRightText.transform.localScale = Vector3.one * textScale;
                if (parentScale < 0.7f)
                {
                    LowerRightText.transform.localPosition = LowerRightText.transform.localPosition + new Vector3(0, -23, 0);
                }
            }

            if (topLeftMark != null)//默认0 不显示（1必得2概率）
            {           
                topLeftMark.transform.localScale = Vector3.one * textScale;         
            }
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
                    Image clickNode = this.gameObject.GetComponent<Image>();
                    if (clickNode == null)
                    {
                        clickNode = this.gameObject.AddComponent<Image>();
                    }
                    clickNode.raycastTarget = true;
                    clickNode.color = new Vector4(1, 1, 1, 0);
                    clickNode.enabled = _showDetail;
                }
            }
        }
        public void OnPointerClick(PointerEventData eventData)
        {
            if (showDetail)
            {
                int[] msg = { pos, 1 };
                LuaController.DispatchEvent("OnClickItemIcon", EquipInfo, msg);
            }
        }
        public void OnPointerDown(PointerEventData eventData)
        {
            if (!disableTween)
            {
                transform.DOScale(scale * 0.8f, 0.1f);
            }
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            transform.DOScale(scale, 0.1f);
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
        string _Lv = "";
        public string Lv
        {
            get { return _Lv; }
            set
            {
                if (_Lv != value)
                {
                    _Lv = value;
                    UpdateLv();
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
                if (_Name != null && _Name != value)
                {
                    _Name = value;
                    UpdateName();
                }
            }
        }
        int _equipPos = 0;
        public int EquipPos
        {
            get { return _equipPos; }
            set
            {
                if (_equipPos != value)
                {
                    _equipPos = value;
                    UpdatePos();
                }
            }
        }
        int _AdvLevel = 0;
        public int AdvLevel
        {
            get
            {
                return _AdvLevel;
            }
            set
            {
                _AdvLevel = value;
                UpdateAdvanceLv();
            }
        }
        [SerializeField]
        int _equipType = 0;
        public int EquipType
        {
            get { return _equipType; }
            set
            {
                if (_equipType != value)
                {
                    _equipType = value;
                    UpdatePos();
                    UpdateAdvanceLv();
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

        [SerializeField]
        int _heroId = 0;
        public int HeroId
        {
            get { return _heroId; }
            set
            {
                if (_heroId != value)
                {
                    _heroId = value;
                    UpdateShowMark();
                }
            }
        }
        bool _lock = false;
        public bool Locked
        {
            get { return _lock; }
            set
            {
                if (_lock != value)
                {
                    _lock = value;
                    UpdateShowMark();
                }
            }

        }

        [SerializeField]
        bool _gray = false;
        public bool gray
        {
            get { return _gray; }
            set
            {
                if (_gray != value)
                {
                    _gray = value;
                    UpdateGray();
                }
            }
        }
        bool _showName = false;
        public bool ShowEquipName
        {
            get { return _showName; }
            set
            {
                if (_showName != value)
                {
                    _showName = value;
                    UpdateShowEquipName();
                }
            }
        }
        int _getType = 0;
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
        int _rareMark = 0;
        public int RareMark
        {
            get { return _rareMark; }
            set
            {
                if (_rareMark!=value)
                {
                    _rareMark = value;
                    UpdateShowRareMark();
                }
            }
        }
        void UpdateGray()
        {
            Image[] imgs = transform.GetComponentsInChildren<Image>();
            foreach (var i in imgs)
            {
                i.material = gray == true ? QualityConfig.GetInstance().grayMaterial : null;
            }
        }
        void UpdateShowEquipName()
        {
            if (NameText != null)
            { 
                NameText.gameObject.SetActive(_showName);
            }
        }
        void UpdateShowRareMark()
        {
            if (posMark!=null)
            {
                posMark.gameObject.SetActive(_rareMark==1?true:false);
            }
        }
        void UpdateQuality()
        {
            if (Quality < 0)
            {
                return;
            }
            if (frameImage != null)
            {
                frameImage.GetComponent<UGUISpriteSelector>().index = Quality;
            }
            if (qualityFx!=null)
            {
                qualityFx.SetActive(_quality>=4);
            }     
        }
        void UpdateIcon()
        {
            if (equipIcon != null)
            {
                equipIcon.gameObject.SetActive(_icon!="");
                if (_icon != "")
                {
//                     if (equipIcon.sprite == null)
//                     {
//                         equipIcon.sprite = SGK.ResourcesManager.Load<Sprite>(string.Format("icon/{0}", _icon));
//                     }
//                     else
//                     {
//                         equipIcon.LoadSprite(string.Format("icon/{0}", _icon));
//                     }

                    equipIcon.LoadSprite(string.Format("icon/{0}", _icon));
                }
            }   
        }
        void UpdatePos()
        {
            //if (posMark != null)
            //{
            //    posMark.gameObject.SetActive(false);//策划说不显示装备位置叻
            //    posMark.gameObject.SetActive(EquipType == 0 ? true : false);
            //    if (posMark != null && EquipType == 0)
            //    {
            //        for (int i = 1; i <= 6; i++)
            //        {
            //            if ((_equipPos & (1 << i + 5)) != 0)
            //            {
            //                posMark.GetComponent<UGUISpriteSelector>().index = i - 1;
            //            }
            //        }
            //    }
            //}
        }
        void UpdateAdvanceLv()
        {
            if (advanceMark != null)
            {
                advanceMark.gameObject.SetActive(_equipType == 0 && AdvLevel > 0 ? true : false);
                if (advanceLv != null && _equipType == 0)
                {
                    advanceLv.text = AdvLevel.ToString();
                }
            }
        }
        void UpdateLv()
        {
            if (LowerRightText != null)
            {
               //LowerRightText.text = "";
                //LowerRightText.text =( _Lv != "" && _Lv != "0" )? string.Format("需{0}级", _Lv) : "";
                LowerRightText.text = (_Lv != "" && _Lv != "0") ? string.Format("^{0}", _Lv) : "";
            }
        }
        void UpdateName()
        {
            if (_Name != null && NameText != null)
            {
                NameText.text = _Name.ToString();
            }
        }
        void UpdateShowMark()
        {
            if (heroIcon != null && statusMark != null)
            {
                //statusMark.gameObject.SetActive(HeroId != 0 ? true : false);
                if (HeroId != 0)
                {
                    heroIcon.LoadSprite("icon/" + HeroId);
                    //if (statusTip != null)
                    //{
                    //    statusTip.text = Locked == true ? "绑" : "装";
                    //    statusTip.color = Locked == true ? Color.yellow : Color.green;
                    //}
                }
            }
        }
        void UpdateShowTopLeftmark()
        {
            if (topLeftMark != null)//默认0 不显示（1必得2概率）
            {
                topLeftMark.gameObject.SetActive(_getType != 0);
                if (_getType != 0)
                {
                    if (topLeftMark.GetComponent<UGUISpriteSelector>() != null)
                    {
                        topLeftMark.gameObject.AddComponent<UGUISpriteSelector>();
                    }
                    topLeftMark.GetComponent<UGUISpriteSelector>().index = _getType-1;
                }
            }
        }

#if UNITY_EDITOR
        void Update()
        {
            if (!Application.isPlaying)
            {
                UpdateIcon();
                UpdatePos();
                UpdateAdvanceLv();
                UpdateQuality();
                UpdateLv();
                UpdateName();
                UpdateShowMark();
                UpdateGray();
                UpdateShowTopLeftmark();
                UpdateShowEquipName();
                UpdateShowRareMark();
            }
        }
#endif
        public void SetInfo(LuaTable t,bool showName=false)
        {
            string targetIcon = t.GetInPath<string>("cfg.icon_2");//道具型装备
            int targetQulity = t.Get<int>("quality");
            int targetType = t.Get<int>("type");
            
            string targetName = t.GetInPath<string>("cfg.name");
            int targetPos = t.GetInPath<int>("cfg.type");//t.Get<int>("pos");//装备的穿戴位置
            int targetHeroId = t.Get<int>("heroid");
            bool targetLock = t.Get<bool>("isLock");
            // var _strType = t.GetInPath<int>("cfg.id").ToString();
            int targetRareMark = t.GetInPath<int>("cfg.treasure");
            //int targetAdv = System.Convert.ToInt32(_strType.Substring(_strType.Length - 3, 1));

            //string targetLv = t.GetInPath<int>("cfg.equip_level").ToString();
            //int targetAdv = t.GetInPath<int>("level")-1;

            string targetLv = t.GetInPath<int>("level").ToString();//装备属性等级
            int targetAdv = 0; 

            EquipInfo = t;
            if (Icon == targetIcon && Quality == targetQulity && EquipType == targetType && Lv == targetLv && Name == targetName && EquipPos == targetPos &&ShowEquipName == showName&& AdvLevel == targetAdv && HeroId == targetHeroId && Locked == targetLock)
            {
                return;
            }
            Icon = targetIcon;
            
            Quality = targetQulity;
            EquipType = targetType;//装备还是铭文  装备为0
            Lv = targetLv;
            Name = targetName;
            EquipPos = targetPos;
            HeroId = targetHeroId;
            Locked = targetLock;
            AdvLevel = targetAdv;
            ShowEquipName=showName;
            RareMark = targetRareMark;
        }

        public Image equipIcon;
        public Image posMark;
        public Image frameImage;
        public Text LowerRightText;
        public Text NameText;
        public GameObject advanceMark;
        public Text advanceLv;
        public GameObject statusMark;
        public Image heroIcon;
        public Text statusTip;
        public Image topLeftMark;
        public GameObject qualityFx;
    }
}
