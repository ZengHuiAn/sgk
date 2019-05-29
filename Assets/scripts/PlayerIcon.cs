using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;
namespace SGK {
    [ExecuteInEditMode]
    public class PlayerIcon : MonoBehaviour {
        [SerializeField]
        string _Icon = "11000";
        public string Icon {
            get { return _Icon; }
            set {
                if (_Icon != value) {
                    _Icon = value!="0" ?value : _Icon ;
                    UpdateIcon();
                }
            }
        }
        [SerializeField]
        int _Level = 1;
        public int Level {
            get { return _Level; }
            set {
                if (_Level != value) {
                    _Level = value;
                    UpdateLevel();
                }
            }
        }

        [SerializeField]
        int _VipLevel = 0;
        public int VipLevel
        {
            get { return _VipLevel; }
            set {
                if (_VipLevel != value) {
                    _VipLevel = value;
                    UpdateVipLevel();
                }
            }
        }
     

        public bool _topTag = false;
        public bool ShowTopTag
        {
            get { return _topTag; }
            set
            {
                if (_topTag != value)
                {
                    _topTag = value;
                    UpdateTopTag();
                }
            }
        }

#if UNITY_EDITOR
        void Update() {
            if (!Application.isPlaying) {
                UpdateIcon();
                UpdateLevel();
                UpdateVipLevel();
                UpdateTopTag();
            }
        }
#endif
	
		void UpdateIcon() {
            if (HeadIcon != null)
            {
                HeadIcon.LoadSprite("icon/" + _Icon);
            }
        }

        void UpdateLevel(){
            if (PlayerLevel != null)
            {
                if (_Level == 0)
                {
                    PlayerLevel.text = "";
                }
                else
                {
                    PlayerLevel.text = "Lv" + _Level;
                }
            }
        }
        void UpdateVipLevel()
        {
            if (VipTag!=null &&VipText != null)
            {
                VipTag.gameObject.SetActive(_VipLevel > 0);
                VipText.text = "Vip" + _VipLevel;
            }
        }

        void UpdateTopTag()
        {
            if (TopTag != null)
            {
                TopTag.gameObject.SetActive(_topTag);
            }
        }

		public void SetInfo(LuaTable t, bool showTopTag=false) {
			string targetIcon = t.Get<string>("head");
			int targetLevel   = t.Get<int>("level");
            int targetVipLevel = t.Get<int>("vip");

			Icon = targetIcon;
			Level = targetLevel;
            VipLevel=targetVipLevel;
            ShowTopTag = showTopTag;
        }
	
		public Image HeadIcon;
		public Image TopTag;
        public GameObject VipTag;
        public Text VipText;
        public Text PlayerLevel;
	}
}	