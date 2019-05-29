using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;
namespace SGK {
    [ExecuteInEditMode]
	public class EquipPrefixIcon : MonoBehaviour {
        [SerializeField]
		string _EquipIcon = "60002";
        public string Eicon {
			get { return _EquipIcon; }
            set {
				if (_EquipIcon != value) {
					_EquipIcon = value;
					UpdateEquipIcon ();
                }
            }
        }
		[SerializeField]
		string _PrefixIcon = "87001";
		public string Picon {
			get { return _PrefixIcon; }
			set {
				if (_PrefixIcon != value) {
					_PrefixIcon = value;
					UpdatePrefixIcon ();
				}
			}
		}
		[SerializeField]
		string _Desc = "攻击";
		public string Desc {
			get { return _Desc; }
			set {
				if (_Desc != value) {
					_Desc = value;
					UpdateDesc ();
				}
			}
		}
        [SerializeField]
        string _Lv = "";
        public string Lv {
			get { return _Lv; }
            set {
				if (_Lv != value) {
					_Lv = value;
					UpdateLv();
                }
            }
        }
        [SerializeField]
        int _Type = 0;
        public int Type {
            get { return _Type; }
            set {
                if (_Type != value) {
                    _Type = value;
                    UpdateType();
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
                    UpdateType();
                }
            }
        }
		[SerializeField]
		[Range(0, 6)]
		int _Index = 0;

		public int Index {
			get { return _Index; }
			set {
				if (_Index != value) {
					_Index = value;
					UpdateIndex();
				}
			}
		}

        [SerializeField]
        [Range(0, 5)]
        int _EquipQuality = 0;

        public int EquipQuality {
			get { return _EquipQuality; }
            set {
				if (_EquipQuality != value) {
					_EquipQuality = value;
                    UpdateEquipQuality();
                }
            }
        }
		[SerializeField]
		[Range(0, 5)]
		int _PrefixQuality = 0;

		public int PrefixQuality {
			get { return _PrefixQuality; }
			set {
				if (_PrefixQuality != value) {
					_PrefixQuality = value;
					UpdatePrefixQuality();
				}
			}
		}
        bool _redDot = false;
        public bool RedDot {
            get {
                return _redDot;
            }
            set {
                if (_redDot != value) {
                    _redDot = value;
                    UpdateRedDot();
                }
            }
        }


        #if UNITY_EDITOR
        void Update() {
			if (!Application.isPlaying) {
				UpdateEquipQuality();
				UpdatePrefixQuality();
				UpdateType();
				UpdateLv();
				UpdateEquipIcon();
				UpdatePrefixIcon ();
				UpdateIndex ();
				UpdateDesc ();
				UpdateRedDot();
			}
        }
		#endif
        void UpdateRedDot() {
            if (RedDotImg) {
                RedDotImg.SetActive(_redDot);
            }
        }
		void UpdateEquipQuality() {
			if (_EquipQuality < 0 ) {
				return;
			}
			EquipIcon.color = QualityConfig.GetInstance().GetColor(_EquipQuality);
		}
		void UpdatePrefixQuality() {
			if (_PrefixQuality < 0 ) {
				return;
			}
			PrefixIcon.color = QualityConfig.GetInstance().GetColor(PrefixQuality);
		}
		void UpdateDesc(){
			if (desc != null) {
				desc.text = Desc;
			}
		}
		void UpdateEquipIcon() {
			if (EquipIcon != null) {
				EquipIcon.LoadSprite("icon/"+Eicon);
			}
			EquipIcon.gameObject.SetActive (Eicon != "");
        }
		void UpdatePrefixIcon() {
			if (PrefixIcon != null) {
				PrefixIcon.LoadSprite("icon/"+Picon);
			}
			Prefixbg.gameObject.SetActive (Picon != "");
		}
		void UpdateLv(){
			if (EquipLv != null) {
				EquipLv.text = _Lv.ToString();
			}
		}
		void UpdateType(){
			if (EquipIcon != null) {
				
            }
		}
		void UpdateIndex(){
			if (EquipIndex != null) {
				string [] s = new string[] {"","壹","贰","叁","肆","伍","陆"};
				EquipIndex.text = s[Index];
			}
		}
		void UpadteBg(){
			if (EquipBg != null && bg != null){
				EquipBg.gameObject.SetActive (Eicon != "" && Picon != "");
				bg.gameObject.SetActive (Eicon == "" && Picon == "");
			}
		}
		[System.Serializable]
		public struct ColorInfo {
			public Color normal;
			public Color background;
		}
		public void Reset(){
			Eicon = "";
			Picon = "";
			Index = 0;
			Desc = "";
            Lv = "";
			bg.gameObject.SetActive (true);
			EquipBg.gameObject.SetActive (false);
            RedDot = false;
        }
		public void SetInfo(LuaTable t, bool showName = false) {
			bg.gameObject.SetActive (false);
			EquipBg.gameObject.SetActive (true);
			string targetEIcon = t.Get<string>("Eicon");
			string targetPIcon = t.Get<string>("Picon");
			string targetDesc = t.Get<string> ("Desc");
			int targetEquipQulity = t.Get<int>("EquipQuality");
			int targetPrefixQulity = t.Get<int>("PrefixQuality");
			string targetLv = t.Get<string>("lv");
            int targetType = t.Get<int>("type");
            int targetSubType = t.Get<int>("sub_type");
			int targetIndex = t.Get<int>("Index");

			if (Eicon == targetEIcon && Picon == targetPIcon && EquipQuality == targetEquipQulity && PrefixQuality == targetPrefixQulity && Lv == targetLv && Type == targetType&& SubType == targetSubType && Index == targetIndex && Desc == targetDesc) {
				return;
			}
			Eicon = targetEIcon;
			Picon = targetPIcon;
			EquipQuality = targetEquipQulity;
			PrefixQuality = targetPrefixQulity;
			Lv = targetLv;
			Type = targetType;
            SubType = targetSubType;
			Index = targetIndex;
			Desc = targetDesc; 
           
        }

		public Image [] backgroundImage = new Image[0];
		public Image [] colorImage = new Image[0];
		public Image EquipIcon;
		public Image PrefixIcon;
		public GameObject Prefixbg;
		public Image EquipBg;
		public Image bg;
		public Text desc;
        public Text EquipLv;
		public Text EquipIndex;
        public GameObject RedDotImg;
	}
}	