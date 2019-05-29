using SGK;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace SGK {
    public class InscIcon : MonoBehaviour {
        public Image Icon;
        public Image MidIcon;
        public Text Level;
        public GameObject Lock;
        public GameObject posMark;
        public Image posIcon;
        public Text advText;
        public GameObject advancedNode;
        public GameObject advanced;
        public bool needMoveAdvNode = true;

        public GameObject[] SSR = new GameObject[5];

        [SerializeField]
        string m_icon = "";
        public string icon {
            get { return m_icon; }
            set {
                if (m_icon != value) {
                    m_icon = value;
                    updateIcon();
                }
            }
        }
        [SerializeField]
        int _EquipType = 0;
        public int EquipType
        {
            get { return _EquipType; }
            set
            {
                if (_EquipType != value)
                {
                    _EquipType = value;
                    updateIcon();
                }
            }
        }
        [SerializeField]
        int _Pos = 0;
        public int Pos
        {
            get { return _Pos; }
            set
            {
                if (_Pos != value)
                {
                    _Pos = value;
                    updateIcon();
                }
            }
        }
        // private Vector2[] posValue = { new Vector2(0, 0), new Vector2(0, 1), new Vector2(0.5f, 1), new Vector2(1, 1), new Vector2(0, 0), new Vector2(0.5f, 0), new Vector2(1, 0) };
        private void updateIcon() {
            //if (Icon != null) {
            //    //Icon.LoadSprite(string.Format("icon/{0}", m_icon));
            //    Icon.sprite = SGK.ResourcesManager.Load<Sprite>("icon/" + m_icon);
            //}
            if (MidIcon != null)
            {
                MidIcon.gameObject.SetActive(EquipType == 0 ? true : false);
                if (m_icon != "")
                {
                    MidIcon.LoadSprite("icon/" + m_icon);
                }
            }
            if (Icon != null)
            {
                Icon.gameObject.SetActive(EquipType == 1 ? true : false);
                if (m_icon != "")
                {
                    Icon.LoadSprite("icon/" + m_icon);
                }
            }
            if (posMark != null)
            {
                posMark.gameObject.SetActive(EquipType == 0 ? true : false);
                if (posIcon != null && EquipType == 0)
                {
                    for (int i = 1; i <= 6; i++)
                    {
                        if ((Pos & (1 << i + 5)) != 0)
                        {
                            posIcon.SetNativeSize();
                            posIcon.gameObject.transform.GetComponent<RectTransform>().anchorMax = new Vector2(0.5f, 0.5f);
                            posIcon.gameObject.transform.GetComponent<RectTransform>().anchorMin = new Vector2(0.5f, 0.5f);
                            posIcon.gameObject.transform.GetComponent<RectTransform>().anchoredPosition = new Vector2(0.5f, 0.5f);
                            posIcon.LoadSprite("icon/jiaobiao" + (i));
                            
                        }
                    }
                }
            }
            if (SSR!=null)
            {
                for (int i = 0; i < 5; i++)
                {
                    if (SSR[i] != null)
                    {
                        SSR[i].SetActive(m_ssr == i && EquipType == 1);
                    }
                }
            }
            
        }

        [SerializeField]
        int m_level = 0;
        public int level {
            get { return m_level; }
            set {
                if (m_level != value || m_level == 1) {
                    m_level = value;
                    updateLevel();
                }
            }
        }
        private void updateLevel() {
            if (Level != null) {
                Level.text = SGK.Localize.getInstance().getValue("zhuangbei_lv_01", m_level);
            }
        }

        [SerializeField]
        bool m_lock = false;
        public bool isLock {
            get { return m_lock; }
            set {
                if (m_lock != value) {
                    m_lock = value;
                    updateLock();
                }
            }
        }
        private void updateLock() {
            if (Lock != null) {
                Lock.SetActive(m_lock);
            }
        }

        [SerializeField]
        int m_ssr = 0;
        public int ssr
        {
            get { return m_ssr; }
            set
            {
                if (m_ssr != value)
                {
                    m_ssr = value;
                    updateIcon();
                }
            }
        }

        [SerializeField]
        int m_advLevel = -1;
        bool m_advActive = false;
        public int advLevel {
            get {
                return m_advLevel;
            }
            set {
                m_advLevel = value;
                upAdvLevel();
            }
        }

        void upAdvLevel() {
            if (advanced != null && advText != null && advancedNode != null) {
                if (advanced.activeSelf != m_advActive) {
                    advanced.SetActive(advanced);
                }
                advText.text = "" + m_advLevel;
                for (var i = 0; i < advancedNode.transform.childCount; ++i) {
                    var _child = advancedNode.transform.GetChild(i);
                    if (_child) {
                        _child.gameObject.SetActive(i < m_advLevel);
                    }
                }
                if (needMoveAdvNode) {
                    for (int i = 1; i <= 6; i++) {
                        if ((Pos & (1 << i + 5)) != 0) {
                            advanced.transform.localPosition = i <= 3 ? new Vector3(9.2f, -87.83f, 0) : new Vector3(9.2f, 89.11f, 0);
                        }
                    }
                }
            }
        }

#if UNITY_EDITOR
        void Update() {
            if (!Application.isPlaying) {
                updateLevel();
                updateIcon();
                updateLock();
                upAdvLevel();
            }
        }
#endif

        public void SetInfo(LuaTable t) {
            string targetIcon = t.Get<string>("icon");
            int targetLevel = t.Get<int>("level");          
            bool targetIsLock = t.Get<bool>("isLock");
            int targetSSR = t.Get<int>("ssrType");
            int targetType = t.Get<int>("type");
            int targetEquipPos = t.GetInPath<int>("cfg.type");//t.Get<int>("pos");//装备的穿戴位置
            var _strType = t.GetInPath<int>("cfg.id").ToString();
            int targetAdv = System.Convert.ToInt32(_strType.Substring(_strType.Length - 3, 1));
            if (m_icon == targetIcon && m_level == targetLevel && m_lock == targetIsLock && m_ssr == targetSSR&& EquipType== targetType&& Pos == targetEquipPos
                && m_advLevel == targetAdv) {
                return;
            }
            icon = targetIcon;
            level = targetLevel;
            isLock = targetIsLock;
            ssr = targetSSR;
            EquipType= targetType;
            Pos = targetEquipPos;
            m_advActive = targetType == 0 ? true : false;
            advLevel = targetAdv;
        }
    }
}
