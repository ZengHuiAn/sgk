using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace SGK
{
    public class moveMapItem : MonoBehaviour
    {   
        // Use this for initialization
        void Start()
        {

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
                }
            }
        }
        public int _group = 0;
        public int group
        {
            get { return _group; }
            set
            {
                if (_group != value)
                {
                    _group = value;
                    UpdateShow();
                }
            }
        }
        void UpdateIcon()
        {
            if (headIcon != null)
            {
                headIcon.gameObject.SetActive(_icon != "");
                if (_icon != "")
                {
                    if (_icon != "0")
                    {
//                         if (headIcon.sprite == null)
//                         {
//                             headIcon.sprite = SGK.ResourcesManager.Load<Sprite>(string.Format("icon/{0}", _icon));
//                         }
//                         else
//                         {
//                             headIcon.LoadSprite(string.Format("icon/{0}", _icon));
//                         }
                        headIcon.LoadSprite(string.Format("icon/{0}", _icon));
                    }
                }
            }
        }
        void UpdateShow()
        {
            if (arrowImage!=null)
            {
                UGUISpriteSelector selector = arrowImage.GetComponent<UGUISpriteSelector>();
                if (selector == null)
                {
                    arrowImage.gameObject.AddComponent<UGUISpriteSelector>();
                    selector = arrowImage.GetComponent<UGUISpriteSelector>();
                }
                selector.index = group; 
            }
            if (bgImage != null)
            {
                UGUISpriteSelector selector = bgImage.GetComponent<UGUISpriteSelector>();
                if (selector == null)
                {
                    bgImage.gameObject.AddComponent<UGUISpriteSelector>();
                    selector = bgImage.GetComponent<UGUISpriteSelector>();
                }
                selector.index = group;
            }
        }

        // Update is called once per frame
        void Update()
        {
            if (!Application.isPlaying)
            {
                UpdateShow();
                UpdateIcon();
            }
        }

        public void SetInfo(string head, int group=1)
        {
            string targetIcon = head;
            int targetGroup = group;
            if (icon == targetIcon && group == targetGroup)
            {
                return;
            }
            icon = targetIcon;
        }
        public Image headIcon;
        public Image arrowImage;
        public Image bgImage;
    }
}
