using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;
namespace SGK {
    [ExecuteInEditMode]
    public class TitleIcon : MonoBehaviour {
        [SerializeField]
        int _Icon = 1;
        public int Icon {
            get { return _Icon; }
            set {
                if (_Icon != value) {
                    _Icon = value;
                    UpdateIcon();
                }
            }
        }
        [SerializeField]
        int _Type = 1;
        public int Type
        {
            get { return _Type; }
            set
            {
                if (_Type != value)
                {
                    _Type = value;
                    UpdateBgIcon();
                }
            }
        }
     
        [SerializeField]
        string _Name = "战士";
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
  

        bool _showDesc = false;
        public bool ShowDesc
        {
            get { return _showDesc; }
            set
            {
                if (_showDesc != value)
                {
                    _showDesc = value;
                    UpdateShowDesc();
                }
            }
        }

#if UNITY_EDITOR
        void Update() {
            if (!Application.isPlaying) {
                UpdateIcon();
                UpdateBgIcon();
                UpdateName();
                UpdateShowDesc();
            }
        }
		#endif
	
		void UpdateIcon() {
            if (icon != null)
            {
                icon.LoadSprite("icon/" + "ch_" + _Icon.ToString("D2"));
            }
        }
        void UpdateBgIcon()
        {
            if (Bg != null && Border != null)
            {   if (Type>=1&&Type<=6)
                {
                    Bg.sprite = BgList[Type - 1];
                    Border.sprite = BorderList[Type - 1];
                }    
            }
        }
        void UpdateName()
        {
            if (NameText != null)
            {
               NameText.text = _Name;   
            }
        }


        void UpdateShowDesc(){
            if (DescText != null)
            {
                DescText.gameObject.SetActive(_showDesc);
            }
        }
   
		public void SetInfo(LuaTable t,bool showDesc= false) {
			int targetIcon = t.Get<int>("icon_id");
            int targetType = t.Get<int>("background_id");
            string targetName = t.Get<string>("name");
            if (Icon == targetIcon && Type ==targetType && name == targetName)
            {
                return;
            }
            Icon = targetIcon;
            Name = targetName;
            Type = targetType;
   
            ShowDesc = showDesc;   
        }
        [SerializeField]
        public Sprite[] BgList;
        [SerializeField]
        public Sprite[] BorderList;

        public Text NameText;
        public Text DescText;
        public Image icon;
        public Image Bg;
        public Image Border;
    }
}	