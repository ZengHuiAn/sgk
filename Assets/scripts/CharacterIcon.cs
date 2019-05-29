using UnityEngine;
using UnityEngine.UI;
using XLua;
using DG.Tweening;
using UnityEngine.EventSystems;


namespace SGK
{
    [ExecuteInEditMode]
    public class CharacterIcon : MonoBehaviour, IPointerClickHandler, IPointerDownHandler, IPointerUpHandler
    {
        public bool disableTween = true;
        LuaTable HeroInfo;
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
        }
        public void OnPointerClick(PointerEventData eventData)
        {
            if (showDetail)
            {
                LuaController.DispatchEvent("OnClickItemIcon", null, HeroInfo);
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
                        clickNode = gameObject.AddComponent<Image>();
                    }
                    clickNode.raycastTarget = true;
                    clickNode.color = new Vector4(1, 1, 1, 0);
                    clickNode.enabled = _showDetail;
                }
            }
        }
        [SerializeField]
        string _icon = "";
        public string icon
        {
            get { return _icon; }
            set
            {
                if (_icon != value)
                {
                    _icon = value;
                    UpdateIcon();
                    UpdateQuality();
                }
                else  
                {
                    if(characterIcon.sprite!=null)
                    {
                        if((characterIcon.sprite.name!=_icon)&&_icon!="0")
                        {
                            UpdateIcon();  
                        }
                    }
                }
            }
        }

        [SerializeField]
        [Range(0, 5)]
        int _stage = 0;

        public int stage
        {
            get { return _stage; }
            set
            {
                if (_stage != value)
                {
                    _stage = value;
                    UpdateQuality();
                }
            }
        }

        [SerializeField]
        [Range(1, 200)]
        int _level = 1;
        public int level
        {
            get { return _level; }
            set
            {
                if (_level != value)
                {
                    _level = value;
                    UpdateLevel();
                }
            }
        }

        string _headFrame = "";
        public string headFrame
        {
            get { return _headFrame; }
            set
            {
                if (_headFrame != value)
                {
                    _headFrame = value;
                    UpdateHeadFrame();
                }
            }
        }

        int _sex = -1;
        public int sex
        {
            get { return _sex; }
            set
            { 
                if (_sex != value)
                {
                    _sex = value;
                    UpdateSexImage();
                }
            }
        }

        [SerializeField]
        [Range(0, 30)]
        int _star = 0;
        public int star
        {
            get { return _star; }
            set
            {
                if (_star != value)
                {
                    _star = value;
                    UpdateStar();
                }
            }
        }

        [SerializeField]
        bool _piece = false;
        public bool piece
        {
            get { return _piece; }
            set
            {
                if (_piece != value)
                {
                    _piece = value;
                    UpdateQuality();
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

        public bool flipOnChange = false;
        public float flipDelay = 0;

        public int pos;

#if UNITY_EDITOR
        void Update()
        {
            if (!Application.isPlaying)
            {
                UpdateQuality();
                UpdateLevel();
                UpdateStar();
                UpdateIcon();
                UpdateHeadFrame();
                UpdateSexImage();
                UpdateGray();
                UpdateShowTopLeftmark();
            }
        }
#endif

        void UpdateQuality()
        {
            if (frameImage != null)
            {
                frameImage.gameObject.SetActive(true);
                UGUISelector selector = frameImage.gameObject.GetComponent<UGUISelector>();
                if (selector == null)
                {
                    selector = frameImage.gameObject.AddComponent<UGUISelector>();
                }
                selector = frameImage.gameObject.GetComponent<UGUISelector>();

                //if (_piece)
                //{
                //    selector.index = 6;
                //}
           
                if (_icon == "0")
                {
                    selector.index = 7;
                }
                else
                {
                    frameImage.gameObject.SetActive(_stage >= 0);
                    selector.index = _stage;
                }        
                pieceMark.gameObject.SetActive(_piece);
            }
            if (qualityFx!=null)
            {
                qualityFx.SetActive(_stage>=4);
            } 
        }

        void UpdateLevel()
        {
            if (LowerRightText != null)
            {
                if (_level <= 0)
                {
                    LowerRightText.text = "";
                }
                else
                {
                    LowerRightText.text = string.Format("^{0}", _level);
                }
            }
        }

        void UpdateStar()
        {
            if (starImages != null)
            {
                int starQuality;
                //1 - 6星显示1个绿星 7 - 12显示2个蓝星 13 - 18显示3个紫星19 - 24显示4个橙星 25 - 30显示5个红星
                //int star;
                if (_star <= 0)
                {
                    star = 0;
                    starQuality = 0;
                }
                else
                {
                    //star = (_star - 1) % starRound + 1;
                    starQuality = _star / starRound;
                }
                for (int i = 0; i < starImages.Length; i++)
                {
                    if (starImages[i] != null)
                    {
                        starImages[i].gameObject.SetActive(i < starQuality);
                        starImages[i].sprite = stageConfig.GetStarSprite(4);//星星不分品质统一显示橙色
                        //starImages[i].sprite = stageConfig.GetStarSprite(stage);
                    }
                }
            }
        }

        void UpdateGray()
        {
            for (var i = 0; i < transform.childCount; ++i)
            {
                var _child = transform.GetChild(i);
                if (_child.GetComponent<Image>() != null)
                {
                    _child.GetComponent<Image>().material = _gray == true ? QualityConfig.GetInstance().grayMaterial : null;
                }
            }
        }
        void UpdateIcon()
        {
            if (characterIcon != null)
            {
                characterIcon.gameObject.SetActive(_icon != "");
                if (_icon != "")
                {
                    if (_icon != "0")
                    {
                        characterIcon.LoadSprite(string.Format("icon/{0}", _icon));
                    }
                    else//如果 icon为 0 使用特殊 Icon
                    {
                        UGUISpriteSelector selector =characterIcon.GetComponent<UGUISpriteSelector>();
                        if (selector==null)
                        {
                            characterIcon.gameObject.AddComponent<UGUISpriteSelector>();
                            selector = characterIcon.GetComponent<UGUISpriteSelector>();
                        }
                        selector.index = 0;
                    }  
                }        
            }
        }
        void UpdateHeadFrame()
        {
            if (headFrameImage != null)
            {
                headFrameImage.gameObject.SetActive(headFrame != "" && headFrame != "0");
                if (headFrame != "" && headFrame != "0")
                {
                    headFrameImage.LoadSprite(string.Format("icon/{0}", headFrame));
                }
            }
        }
         void UpdateSexImage()
        {
            if (sexImage != null)
            {
                sexImage.gameObject.SetActive(sex != -1 ? true : false);
                if (sex != -1)
                {
                    UGUISelector selector = sexImage.gameObject.GetComponent<UGUISelector>();
                    if (selector == null)
                    {
                        selector = sexImage.gameObject.AddComponent<UGUISelector>();
                    }
                    selector = sexImage.gameObject.GetComponent<UGUISelector>();
                    selector.index = sex;
                }
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

        public void SetInfo(LuaTable t, bool IsPlayer = false)
        {
            int targetStage = 0;
            int targetSar = 0;
            string targetIcon = ""; 

            if (IsPlayer)
            {
                targetIcon = t.Get<string>("icon") != null ? t.Get<string>("icon") : t.Get<string>("head");
                targetStage = -1;
            }
            else
            {
                targetIcon = t.Get<string>("showMode") != null ? t.Get<string>("showMode") : t.Get<string>("icon");
                targetStage = t.Get<string>("role_stage")!= null? int.Parse(t.Get<string>("role_stage")): int.Parse(t.Get<string>("quality"));
                targetSar = t.Get<int>("star");
            }

            int targetLevel = t.Get<int>("level");

            if (icon == targetIcon && stage == targetStage && level == targetLevel && star == targetSar)
            {
                return;
            }

            HeroInfo = t;

            if (flipOnChange)
            {
                transform.DOKill(false);
                transform.DORotate(new Vector3(90, 0, 0), 0.2f).OnComplete(() =>
                {
                    icon = targetIcon;
                    stage = targetStage;
                    level = targetLevel;
                    star = targetSar;

                    transform.DORotate(new Vector3(0, 0, 0), 0.2f);
                }).SetDelay(flipDelay);
            }
            else
            {
                icon = targetIcon;
                stage = targetStage;
                level = targetLevel;
                star = targetSar;
            }
        }

        public QualityConfig stageConfig
        {
            get
            {
                return QualityConfig.GetInstance();
            }
        }

        [Space(20)]
        public Image characterIcon;
        public Image frameImage;
        public Image headFrameImage;
        public Image sexImage;
        public Text LowerRightText;
        [Space(20)]
        public Image[] starImages = new Image[0];
        public int starRound = 6;
        public bool asyncLoadIcon = true;
        public Image topLeftMark;
        public Image pieceMark;
        public GameObject qualityFx;
    }
}
